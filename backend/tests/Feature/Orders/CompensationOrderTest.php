<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Actions\PostDealEarningsForOrder;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderDeliveryUndone;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Events\OrderProfitUnwound;
use App\Domain\Order\Events\OrderStockRedrawn;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;
use App\Domain\Order\OrderService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\Support\GivesPrintableArtwork;
use Tests\TestCase;

/**
 * «طلبية تعويض» — Docs/orders/ORDER-COMPENSATION.md.
 *
 * The worked example of §5 throughout: 1,000 bags priced 500, which cost the fund 300; our
 * printing labour on them 50. At cost (option a): the fund gets its 300 back from the company,
 * the investors earn nothing, and the compensation costs the company 350.
 *
 * Arrange - Act - Assert throughout.
 */
class CompensationOrderTest extends TestCase
{
    use GivesPrintableArtwork;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    // ── helpers ──────────────────────────────────────────────────────────────────────────

    /**
     * @return array<string, string>
     */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function clerk(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders);
    }

    /** @return array<string, string> */
    private function compensator(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders, PermissionName::CompensationOrders);
    }

    /**
     * A new-order body: 300 bags at 1.100 = 330.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = [], ?Customer $customer = null): array
    {
        $product = Product::factory()->create(['pricing_mode' => PricingMode::Tiered, 'min_order_quantity' => '100']);
        $variant = ProductVariant::factory()->create(['product_id' => $product->getKey(), 'label' => '25*35']);
        ProductPriceTier::factory()->create(['product_variant_id' => $variant->getKey(), 'min_quantity' => '100', 'unit_price' => '1.100']);
        $customer ??= Customer::factory()->create();

        return array_merge([
            'customer_id' => $customer->getKey(),
            'city_id' => City::factory()->create(['delivery_price' => '20.00'])->getKey(),
            'address_details' => 'شارع الجمهورية',
            'items' => [[
                'product_id' => $variant->product_id,
                'product_variant_id' => $variant->getKey(),
                'quantity' => '300',
            ]],
            'design_ids' => [$this->printableDesignId((int) $customer->getKey())],
        ], $overrides);
    }

    /**
     * An order whose one line drew 1,000 bags costing 300 off the fund's shelf, priced 500, with
     * 50 of our labour on it — §5's example.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function fundOrder(bool $compensation, OrderStatus $status = OrderStatus::Delivered, array $overrides = []): Order
    {
        $fund = app(FundDeal::class)();

        $item = StockItem::factory()->named('رفّ الصندوق '.fake()->unique()->numberBetween(1, 99999))->create();
        $batch = StockBatch::factory()->create([
            'investor_deal_id' => $fund->getKey(),
            'stock_item_id' => $item->getKey(),
        ]);
        $movement = StockMovement::factory()->create([
            'movement_type' => 'order_fulfillment',
            'stock_item_id' => $item->getKey(),
        ]);
        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->getKey(),
            'stock_movement_id' => $movement->getKey(),
            'quantity' => '1000.000',
            'unit_cost' => '0.300',
            'total_cost' => '300.00',
        ]);

        $order = Order::factory()->create(array_merge([
            'status' => $status,
            'items_total' => '500.00',
            'delivery_price' => '20.00',
            'grand_total' => $compensation ? '0.00' : '500.00',
            'total_cogs' => '350.00',
            'is_compensation' => $compensation,
            'compensation_reason' => $compensation ? 'print_defect' : null,
            'delivered_at' => '2026-03-15 10:00:00',
        ], $overrides));

        OrderItem::factory()->for($order)->create([
            'fulfillment_stock_movement_id' => $movement->getKey(),
            'quantity' => '1000.000',
            'unit_price' => '0.500',
            'line_total' => '500.00',
            'material_cost' => '300.00',
            'labor_cost' => '50.00',
            'overhead_cost' => '0.00',
            'cogs' => '350.00',
        ]);

        return $order->refresh();
    }

    /** What stands for this order in the fund's treasury, of one type. */
    private function standing(Order $order, CashEntryType $type): string
    {
        $sum = InvestmentCashEntry::query()
            ->where('source_type', 'order')
            ->where('source_id', $order->id)
            ->where('type', $type)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        return number_format((float) $sum, 2, '.', '');
    }

    /**
     * @return array<int, array<string, string>>
     */
    private function slices(Order $order): array
    {
        $attribution = app(OrderService::class)->profitAttributionFor((int) $order->id);

        return OrderDealSlices::forOrder(
            $attribution,
            app(InventoryService::class)->consumptionBreakdownFor(
                array_map(fn (array $line) => $line['movement_id'], $attribution['lines']),
            ),
        );
    }

    // ── taking one ───────────────────────────────────────────────────────────────────────

    public function test_a_compensation_order_owes_nothing_and_keeps_its_line_prices(): void
    {
        // Act
        $response = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
        ]));

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.is_compensation', true)
            ->assertJsonPath('data.compensation_reason', 'print_defect')
            ->assertJsonPath('data.compensation_reason_label', 'خطأ طباعة')
            ->assertJsonPath('data.items_total', '330.00')
            ->assertJsonPath('data.grand_total', '0.00')
            ->assertJsonPath('data.payment_status', 'paid');
    }

    public function test_an_ordinary_order_is_not_a_compensation(): void
    {
        // Act
        $response = $this->withHeaders($this->clerk())->postJson('/api/v1/orders', $this->payload());

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.is_compensation', false)
            ->assertJsonPath('data.grand_total', '330.00');
    }

    public function test_it_needs_its_own_grant(): void
    {
        // Act — orders.manage and even orders.discount are not enough
        $response = $this->withHeaders($this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders, PermissionName::DiscountOrders))
            ->postJson('/api/v1/orders', $this->payload([
                'is_compensation' => true,
                'compensation_reason' => 'goodwill',
            ]));

        // Assert
        $response->assertForbidden();
        $this->assertSame(0, Order::query()->count());
    }

    public function test_it_needs_a_reason_and_other_needs_words(): void
    {
        // Act
        $noReason = $this->withHeaders($this->compensator())
            ->postJson('/api/v1/orders', $this->payload(['is_compensation' => true]));
        $bareOther = $this->withHeaders($this->compensator())
            ->postJson('/api/v1/orders', $this->payload(['is_compensation' => true, 'compensation_reason' => 'other']));

        // Assert
        $noReason->assertUnprocessable()->assertJsonValidationErrors('compensation_reason');
        $bareOther->assertUnprocessable()->assertJsonValidationErrors('compensation_note');
    }

    public function test_a_discount_is_refused_on_a_compensation_order(): void
    {
        // Act
        $response = $this->withHeaders($this->auth(
            PermissionName::ViewOrders, PermissionName::ManageOrders,
            PermissionName::CompensationOrders, PermissionName::DiscountOrders,
        ))->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
            'discount' => '30',
        ]));

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('discount');
    }

    public function test_the_original_order_is_optional(): void
    {
        // Act — goodwill across several orders names none
        $response = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'wrong_item',
        ]));

        // Assert
        $response->assertCreated()->assertJsonPath('data.compensates_order_id', null);
    }

    public function test_the_original_links_both_ways(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $original = Order::factory()->create(['customer_id' => $customer->getKey()]);

        // Act
        $created = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
            'compensates_order_id' => $original->getKey(),
        ], $customer));

        // Assert
        $created->assertCreated()
            ->assertJsonPath('data.compensates_order_id', $original->getKey())
            ->assertJsonPath('data.compensates_order_code', $original->code);

        $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$original->getKey()}")
            ->assertOk()
            ->assertJsonPath('data.compensated_by.0.id', $created->json('data.id'));
    }

    public function test_the_original_must_be_the_same_customer_s(): void
    {
        // Arrange
        $someoneElse = Order::factory()->create();

        // Act
        $response = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
            'compensates_order_id' => $someoneElse->getKey(),
        ]));

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('compensates_order_id');
    }

    public function test_the_original_cannot_itself_be_a_compensation(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $replacement = Order::factory()->create([
            'customer_id' => $customer->getKey(),
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
        ]);

        // Act
        $response = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
            'compensates_order_id' => $replacement->getKey(),
        ], $customer));

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('compensates_order_id');
    }

    // ── switching an existing order ─────────────────────────────────────────────────────

    public function test_an_open_order_can_become_a_compensation_and_back(): void
    {
        // Arrange
        $order = $this->withHeaders($this->clerk())->postJson('/api/v1/orders', $this->payload())->json('data');

        // Act
        $on = $this->withHeaders($this->compensator())->patchJson("/api/v1/orders/{$order['id']}/compensation", [
            'is_compensation' => true,
            'compensation_reason' => 'delivery_damage',
        ]);
        $off = $this->withHeaders($this->compensator())->patchJson("/api/v1/orders/{$order['id']}/compensation", [
            'is_compensation' => false,
        ]);

        // Assert
        $on->assertOk()->assertJsonPath('data.grand_total', '0.00')->assertJsonPath('data.is_compensation', true);
        $off->assertOk()
            ->assertJsonPath('data.grand_total', '330.00')
            ->assertJsonPath('data.is_compensation', false)
            ->assertJsonPath('data.compensation_reason', null);
    }

    public function test_the_switch_closes_with_the_lines(): void
    {
        // Arrange
        $order = Order::factory()->create(['status' => OrderStatus::Printing]);

        // Act
        $response = $this->withHeaders($this->compensator())->patchJson("/api/v1/orders/{$order->getKey()}/compensation", [
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('is_compensation');
        $this->assertFalse((bool) $order->fresh()->is_compensation);
    }

    public function test_the_switch_needs_the_grant(): void
    {
        // Arrange
        $order = Order::factory()->create();

        // Act
        $response = $this->withHeaders($this->clerk())->patchJson("/api/v1/orders/{$order->getKey()}/compensation", [
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
        ]);

        // Assert
        $response->assertForbidden();
    }

    public function test_an_order_with_a_discount_must_drop_it_first(): void
    {
        // Arrange
        $order = Order::factory()->create(['discount' => '10.00']);

        // Act
        $response = $this->withHeaders($this->compensator())->patchJson("/api/v1/orders/{$order->getKey()}/compensation", [
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('discount');
    }

    public function test_the_edit_form_cannot_put_a_discount_on_a_compensation(): void
    {
        // Arrange
        $created = $this->withHeaders($this->compensator())->postJson('/api/v1/orders', $this->payload([
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
        ]))->json('data');
        $order = Order::query()->findOrFail($created['id']);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders, PermissionName::DiscountOrders))
            ->putJson("/api/v1/orders/{$order->getKey()}", [
                'city_id' => $order->city_id,
                'address_details' => $order->address_details,
                'discount' => '15',
            ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('discount');
    }

    public function test_the_order_says_whether_the_switch_is_offered(): void
    {
        // Arrange
        $open = Order::factory()->create();
        $printing = Order::factory()->create(['status' => OrderStatus::Printing]);

        // Act + Assert
        $this->withHeaders($this->compensator())->getJson("/api/v1/orders/{$open->getKey()}")
            ->assertJsonPath('data.can_change_compensation', true);
        $this->withHeaders($this->compensator())->getJson("/api/v1/orders/{$printing->getKey()}")
            ->assertJsonPath('data.can_change_compensation', false);
        $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$open->getKey()}")
            ->assertJsonPath('data.can_change_compensation', false);
    }

    // ── investors: at cost (option a) ───────────────────────────────────────────────────

    public function test_the_fund_s_slice_is_its_goods_at_cost_with_no_profit(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);
        $fundId = (int) app(FundDeal::class)()->getKey();

        // Act
        $slice = $this->slices($order)[$fundId];

        // Assert — 300 back, no labour charged, nothing earned
        $this->assertSame('300.00', $slice['revenue']);
        $this->assertSame('300.00', $slice['material_cost']);
        $this->assertSame('0.00', $slice['conversion_cost']);
        $this->assertSame('0.00', $slice['profit']);
    }

    public function test_a_courier_fee_we_pay_stays_off_the_fund_s_slice(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true, overrides: ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);
        $fundId = (int) app(FundDeal::class)()->getKey();

        // Act
        $slice = $this->slices($order)[$fundId];

        // Assert
        $this->assertSame('300.00', $slice['revenue']);
        $this->assertSame('0.00', $slice['profit']);
    }

    public function test_no_profit_is_posted_to_investors(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);

        // Act
        $written = app(PostDealEarningsForOrder::class)((int) $order->id);

        // Assert
        $this->assertSame([], $written);
        $this->assertSame(0, InvestorWalletEntry::query()->where('source_type', 'order')->where('source_id', $order->id)->count());
    }

    public function test_delivery_pays_the_fund_back_at_cost_from_the_company(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);

        // Act
        event(new OrderProfitFinalised((int) $order->id));

        // Assert
        $this->assertSame('300.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
        $this->assertSame('0.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('0.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    public function test_announcing_the_delivery_twice_pays_once(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);

        // Act
        event(new OrderProfitFinalised((int) $order->id));
        event(new OrderProfitFinalised((int) $order->id));

        // Assert
        $this->assertSame('300.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
        $this->assertSame(1, InvestmentCashEntry::query()
            ->where('source_type', 'order')->where('source_id', $order->id)->count());
    }

    public function test_nothing_is_paid_before_delivery(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true, status: OrderStatus::OutForDelivery);

        // Act
        event(new OrderProfitFinalised((int) $order->id));

        // Assert
        $this->assertSame('0.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
    }

    public function test_undoing_the_delivery_takes_the_company_s_money_back(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);
        event(new OrderProfitFinalised((int) $order->id));

        // Act
        $order->forceFill(['status' => OrderStatus::OutForDelivery, 'delivered_at' => null])->save();
        event(new OrderDeliveryUndone((int) $order->id));

        // Assert
        $this->assertSame('0.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
    }

    public function test_archiving_a_delivered_compensation_takes_the_money_back(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: true);
        event(new OrderProfitFinalised((int) $order->id));

        // Act
        $order->delete();
        event(new OrderProfitUnwound((int) $order->id));

        // Assert
        $this->assertSame('0.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
    }

    public function test_restoring_a_delivered_compensation_pays_the_fund_again(): void
    {
        // Arrange — archived, its cover reversed
        $order = $this->fundOrder(compensation: true);
        event(new OrderProfitFinalised((int) $order->id));
        $order->delete();
        event(new OrderProfitUnwound((int) $order->id));

        // Act — RestoreOrder brings it back and announces each redraw
        $order->restore();
        event(new OrderStockRedrawn((int) $order->id, (int) $order->items()->first()->fulfillment_stock_movement_id));

        // Assert
        $this->assertSame('300.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
    }

    public function test_an_ordinary_order_s_delivery_writes_no_compensation_row(): void
    {
        // Arrange
        $order = $this->fundOrder(compensation: false);

        // Act
        event(new OrderProfitFinalised((int) $order->id));

        // Assert
        $this->assertSame('0.00', $this->standing($order, CashEntryType::CompensationCoveredByCompany));
    }

    // ── the profit and loss statement ───────────────────────────────────────────────────

    public function test_the_price_is_not_revenue_and_the_cost_is_named_as_a_loss(): void
    {
        // Arrange — one sale of 500 and one compensation, both costing 350
        $this->fundOrder(compensation: false);
        $this->fundOrder(compensation: true);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewProfitAndLossReport))
            ->getJson('/api/v1/reports/profit-loss?from=2026-03-01&to=2026-03-31');

        // Assert — revenue 500, COGS 700, gross −200; the 350 named under losses
        $response->assertOk()
            ->assertJsonPath('data.revenue.product', '500.00')
            ->assertJsonPath('data.cost_of_goods_sold.total', '700.00')
            ->assertJsonPath('data.gross_profit', '-200.00')
            ->assertJsonPath('data.losses.compensation', '350.00')
            ->assertJsonPath('data.losses.total', '350.00');
    }

    public function test_goods_left_behind_are_one_loss_not_two(): void
    {
        // Arrange — a compensation partly delivered, 50 of its 350 written off as left behind
        $order = $this->fundOrder(compensation: true);
        ProductionCostEntry::factory()->forOrder($order)->type(ManufacturingCostType::DeliveryLoss)->amount('50.00')->create();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewProfitAndLossReport))
            ->getJson('/api/v1/reports/profit-loss?from=2026-03-01&to=2026-03-31');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.losses.partial_delivery', '50.00')
            ->assertJsonPath('data.losses.compensation', '300.00')
            ->assertJsonPath('data.losses.total', '350.00');
    }

    public function test_the_sales_board_does_not_count_a_compensation_as_a_sale(): void
    {
        // Arrange
        $this->fundOrder(compensation: false);
        $this->fundOrder(compensation: true);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewSalesStatisticsReport))
            ->getJson('/api/v1/reports/sales-statistics?from=2026-03-01&to=2026-03-31');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.orders_counted', 1)
            ->assertJsonPath('data.sales_value.total', '500.00');
    }

    public function test_an_order_already_compensated_cannot_become_a_compensation(): void
    {
        // Arrange
        $original = Order::factory()->create();
        Order::factory()->create([
            'customer_id' => $original->customer_id,
            'is_compensation' => true,
            'compensation_reason' => 'print_defect',
            'compensates_order_id' => $original->getKey(),
        ]);

        // Act
        $response = $this->withHeaders($this->compensator())->patchJson("/api/v1/orders/{$original->getKey()}/compensation", [
            'is_compensation' => true,
            'compensation_reason' => 'goodwill',
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('is_compensation');
    }

    public function test_the_delivery_switch_warns_the_fee_is_the_company_s_alone(): void
    {
        // Arrange
        $order = Order::factory()->create(['is_compensation' => true, 'compensation_reason' => 'goodwill']);

        // Act
        $warnings = $this->withHeaders($this->clerk())
            ->getJson("/api/v1/orders/{$order->getKey()}")
            ->json('data.delivery_payer_warnings');

        // Assert
        $this->assertStringContainsString('الشركة وحدها', $warnings[0]);
    }

    // ── lists and the customer app ──────────────────────────────────────────────────────

    public function test_the_list_filters_compensation_orders(): void
    {
        // Arrange
        Order::factory()->create();
        $compensation = Order::factory()->create(['is_compensation' => true, 'compensation_reason' => 'goodwill']);

        // Act
        $response = $this->withHeaders($this->clerk())->getJson('/api/v1/orders?is_compensation=1');

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $compensation->getKey());
    }
}
