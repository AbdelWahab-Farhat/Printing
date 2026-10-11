<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Collection;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «مصاريف عند وصول البضاعة» — costs typed on the receive screen, landed into what arrived, and
 * the money behind each one wherever it was really paid. PURCHASE-ORDER-ARRIVAL-COSTS.md.
 *
 * Arrange - Act - Assert throughout.
 */
class PurchaseOrderArrivalCostsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** @return array<string, string> */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** Raises orders, and may pay their costs from a drawer. @return array<string, string> */
    private function buyer(): array
    {
        return $this->auth(
            PermissionName::ViewPurchaseOrders,
            PermissionName::ManagePurchaseOrders,
            PermissionName::RecordTreasuryOperations,
        );
    }

    /** Receives, and may pay the lorry from a drawer. @return array<string, string> */
    private function receiver(): array
    {
        return $this->auth(
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
            PermissionName::RecordTreasuryOperations,
        );
    }

    /** Receives, and has no hand in the treasury. @return array<string, string> */
    private function storekeeper(): array
    {
        return $this->auth(PermissionName::ViewInventory, PermissionName::ManageInventory);
    }

    /** See PurchaseOrderTest::forgetAuth() — call it last, right before the request. */
    private function forgetAuth(): void
    {
        $this->app->get('auth')->forgetGuards();
    }

    private function cash(): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', AccountKind::Cash->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account->refresh());
    }

    /** What the company owes the vendor, as a positive figure. */
    private function owedToVendor(Vendor $vendor): string
    {
        $id = app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id);

        return $id === null
            ? '0.00'
            : bcmul($this->balance(TreasuryAccount::query()->findOrFail($id)), '-1', 2);
    }

    /**
     * An order for each `[shelf, ordered, base total]`, through the real endpoint.
     *
     * @param  list<array{0: StockItem, 1: int, 2: int}>  $lines
     * @param  list<array<string, mixed>>  $costs
     * @return array<string, mixed>
     */
    private function order(Vendor $vendor, array $lines, array $costs = []): array
    {
        $headers = $this->buyer();
        $this->forgetAuth();

        return $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'items' => array_map(fn (array $line) => [
                'stock_item_id' => $line[0]->id,
                'quantity_ordered' => $line[1],
                'base_total_cost' => $line[2],
            ], $lines),
            'additional_costs' => $costs,
        ])->assertCreated()->json('data');
    }

    /**
     * @param  array<string, mixed>  $order
     * @param  list<array{0: StockItem, 1: int}>  $lines
     * @param  list<array<string, mixed>>  $costs
     * @param  array<string, string>|null  $headers
     */
    private function receive(array $order, array $lines, array $costs = [], ?array $headers = null): TestResponse
    {
        $headers ??= $this->receiver();
        $this->forgetAuth();

        return $this->withHeaders($headers)->postJson("/api/v1/purchase-orders/{$order['id']}/arrivals", [
            'items' => array_map(fn (array $line) => ['stock_item_id' => $line[0]->id, 'quantity' => $line[1]], $lines),
            'additional_costs' => $costs,
        ]);
    }

    private function line(array $order, StockItem $shelf): PurchaseOrderItem
    {
        return PurchaseOrderItem::query()
            ->where('purchase_order_id', $order['id'])
            ->where('stock_item_id', $shelf->id)
            ->firstOrFail();
    }

    private function layerCost(StockItem $shelf): string
    {
        return (string) StockBatch::query()->where('stock_item_id', $shelf->id)->firstOrFail()->unit_cost;
    }

    /** @return Collection<int, TreasuryMovement> */
    private function expenseMovementsOf(PurchaseOrderAdditionalCost $cost)
    {
        return TreasuryMovement::query()
            ->where('source_type', AuditSubject::PurchaseOrderAdditionalCost->value)
            ->where('source_id', $cost->id)
            ->where('kind', MovementKind::Expense->value)
            ->get();
    }

    // ─────────────────────────── landing the cost ───────────────────────────

    public function test_a_cost_paid_on_arrival_lands_in_the_stock_and_leaves_the_drawer_not_the_vendors_debt(): void
    {
        // Arrange — 10 bags at 100.00; the lorry's driver is paid 30.00 cash at the door
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $cashBefore = $this->balance($this->cash());

        // Act
        $response = $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $this->cash()->id],
        ]);

        // Assert — (100 + 30) / 10 = 13.000 on the shelf
        $response->assertCreated()->assertJsonPath('data.items.0.unit_cost', '13.000');
        $this->assertSame('13.000', $this->layerCost($bags));
        $this->assertSame('13.000', (string) $this->line($order, $bags)->landed_unit_cost);
        $this->assertSame('30.00', (string) $this->line($order, $bags)->arrival_additional_cost);

        // The drawer paid it, the vendor is owed the goods alone.
        $this->assertSame(bcsub($cashBefore, '30', 2), $this->balance($this->cash()));
        $this->assertSame('100.00', $this->owedToVendor($vendor));

        $saved = PurchaseOrder::query()->findOrFail($order['id']);
        $this->assertSame('130.00', (string) $saved->total_amount);
        $this->assertSame('100.00', (string) $saved->vendor_amount);

        $cost = PurchaseOrderAdditionalCost::query()->where('purchase_order_id', $order['id'])->sole();
        $this->assertNotNull($cost->stock_arrival_id);
        $this->assertCount(1, $this->expenseMovementsOf($cost));
    }

    public function test_a_cost_on_the_vendors_bill_is_owed_to_the_vendor_and_moves_no_drawer(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $cashBefore = $this->balance($this->cash());

        // Act
        $this->receive($order, [[$bags, 10]], [['name' => 'تحميل', 'amount' => 20]])->assertCreated();

        // Assert
        $this->assertSame('12.000', $this->layerCost($bags));
        $this->assertSame('120.00', $this->owedToVendor($vendor));
        $this->assertSame($cashBefore, $this->balance($this->cash()));

        $cost = PurchaseOrderAdditionalCost::query()->where('purchase_order_id', $order['id'])->sole();
        $this->assertCount(0, $this->expenseMovementsOf($cost));
    }

    public function test_a_cost_owed_to_somebody_else_deepens_that_payable(): void
    {
        // Arrange — the customs broker is paid next week
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $broker = TreasuryAccount::factory()->kind(AccountKind::Payable)->create(['name' => 'المخلّص الجمركي']);
        $order = $this->order($vendor, [[$bags, 10, 100]]);

        // Act
        $this->receive($order, [[$bags, 10]], [
            ['name' => 'جمارك', 'amount' => 45, 'treasury_account_id' => $broker->id],
        ])->assertCreated();

        // Assert — «علينا 45» to the broker, nothing to the vendor for it
        $this->assertSame('-45.00', $this->balance($broker));
        $this->assertSame('100.00', $this->owedToVendor($vendor));
        $this->assertSame('14.500', $this->layerCost($bags));
    }

    public function test_an_arrival_cost_is_split_by_the_value_of_what_arrived_and_to_the_cent(): void
    {
        // Arrange — A: 10 ordered at 300, 5 arrive (worth 150). B: 4 ordered at 50, all arrive (50).
        // 100.01 splits 3 : 1 → 75.01 and 25.00, never a cent lost.
        $vendor = Vendor::factory()->create();
        $a = StockItem::factory()->create();
        $b = StockItem::factory()->create();
        $order = $this->order($vendor, [[$a, 10, 300], [$b, 4, 50]]);

        // Act
        $this->receive($order, [[$a, 5], [$b, 4]], [['name' => 'شحن', 'amount' => '100.01']])->assertCreated();

        // Assert
        $lineA = $this->line($order, $a);
        $lineB = $this->line($order, $b);
        $this->assertSame('100.01', bcadd((string) $lineA->arrival_additional_cost, (string) $lineB->arrival_additional_cost, 2));
        $this->assertSame('75.01', (string) $lineA->arrival_additional_cost);
        // A: (150 + 75.01) / 5 = 45.002; B: (50 + 25) / 4 = 18.750
        $this->assertSame('45.002', $this->layerCost($a));
        $this->assertSame('18.750', $this->layerCost($b));
    }

    public function test_a_planned_cost_lands_whole_on_a_short_shipment(): void
    {
        // Arrange — 10 ordered at 100 with 20 delivery planned; only 8 arrive
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]], [['name' => 'توصيل', 'amount' => 20]]);

        // Act
        $this->receive($order, [[$bags, 8]])->assertCreated();

        // Assert — (80 + 20) / 8 = 12.500: the delivery was paid in full for what came
        $this->assertSame('12.500', $this->layerCost($bags));
    }

    // ─────────────────────────── funded goods ───────────────────────────

    private function fundLine(array $order, StockItem $shelf, ?InvestorDeal $deal = null): InvestorDeal
    {
        $deal ??= InvestorDeal::factory()->open()->create();

        $supply = new InvestorDealSupply;
        $supply->investor_deal_id = $deal->getKey();
        $supply->source_type = AuditSubject::PurchaseOrder->value;
        $supply->source_id = $order['id'];
        $supply->stock_item_id = $shelf->id;
        $supply->save();

        return $deal;
    }

    public function test_a_funded_lines_share_is_the_deals_expense_and_its_layer_keeps_the_agreed_cost(): void
    {
        // Arrange — A (company) and B (funded) at 100 each; 40 paid from the cash box
        $vendor = Vendor::factory()->create();
        $a = StockItem::factory()->create();
        $b = StockItem::factory()->create();
        $order = $this->order($vendor, [[$a, 10, 100], [$b, 10, 100]]);
        $deal = $this->fundLine($order, $b);
        $cashBefore = $this->balance($this->cash());

        // Act
        $this->receive($order, [[$a, 10], [$b, 10]], [
            ['name' => 'نقل', 'amount' => 40, 'treasury_account_id' => $this->cash()->id],
        ])->assertCreated();

        // Assert — B's layer stays at the funded 10.000; its 20.00 is the deal's expense
        $this->assertSame('12.000', $this->layerCost($a));
        $this->assertSame('10.000', $this->layerCost($b));

        $cost = PurchaseOrderAdditionalCost::query()->where('purchase_order_id', $order['id'])->sole();
        $expense = InvestorDealExpense::query()->where('investor_deal_id', $deal->id)->sole();
        $this->assertSame('20.00', (string) $expense->amount);
        $this->assertSame(AuditSubject::PurchaseOrderAdditionalCost->value, $expense->source_type);
        $this->assertSame($cost->id, (int) $expense->source_id);

        // The drawer paid 40 in all — the company's 20 and the deal's 20.
        $this->assertSame('20.00', (string) $this->expenseMovementsOf($cost)->sole()->amount);
        $this->assertSame(bcsub($cashBefore, '40', 2), $this->balance($this->cash()));
    }

    public function test_a_line_the_fund_bought_charges_the_fund_as_a_fund_expense(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $fund = $this->fundLine($order, $bags, app(FundDeal::class)());

        // Act
        $this->receive($order, [[$bags, 10]], [
            ['name' => 'جمارك', 'amount' => 15, 'treasury_account_id' => $this->cash()->id],
        ])->assertCreated();

        // Assert — the fund's expense, with the fund's cash entry beside it
        $expense = InvestorDealExpense::query()->where('investor_deal_id', $fund->id)->sole();
        $this->assertSame('15.00', (string) $expense->amount);
        $this->assertTrue(InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->where('source_id', $expense->id)
            ->exists());
        $this->assertSame('10.000', $this->layerCost($bags));
    }

    public function test_a_funded_lines_share_must_have_been_paid_from_a_drawer(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $this->fundLine($order, $bags);

        // Act — on the vendor's bill
        $response = $this->receive($order, [[$bags, 10]], [['name' => 'نقل', 'amount' => 40]]);

        // Assert — refused whole: nothing received
        $response->assertStatus(422)->assertJsonValidationErrors(['additional_costs.0.treasury_account_id']);
        $this->assertSame('0.000', (string) $this->line($order, $bags)->quantity_received);
    }

    public function test_a_deal_expense_from_a_purchase_order_is_not_reversed_by_hand(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $deal = $this->fundLine($order, $bags);
        $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 40, 'treasury_account_id' => $this->cash()->id],
        ])->assertCreated();
        $expense = InvestorDealExpense::query()->where('investor_deal_id', $deal->id)->sole();
        $headers = $this->auth(PermissionName::ViewInvestors, PermissionName::ReverseInvestorMoney);
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/investor-deals/{$deal->id}/expenses/{$expense->id}/reverse",
            ['reason' => 'خطأ'],
        );

        // Assert
        $response->assertStatus(422);
        $this->assertFalse($expense->refresh()->isReversed());
    }

    // ─────────────────────────── who may spend ───────────────────────────

    public function test_a_storekeeper_without_the_treasury_grant_cannot_pay_from_a_drawer(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);

        // Act
        $paid = $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $this->cash()->id],
        ], $this->storekeeper());

        // Assert — refused; on the vendor's bill he may still record it
        $paid->assertStatus(422)->assertJsonValidationErrors(['additional_costs.0.treasury_account_id']);
        $this->receive($order, [[$bags, 10]], [['name' => 'نقل', 'amount' => 30]], $this->storekeeper())
            ->assertCreated();
    }

    public function test_a_vendors_own_payable_cannot_be_named(): void
    {
        // Arrange — the order itself opens the vendor's payable
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $payableId = app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id);

        // Act
        $response = $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $payableId],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['additional_costs.0.treasury_account_id']);
    }

    // ─────────────────────────── taking it back ───────────────────────────

    public function test_reversing_the_receipt_gives_the_drawer_back_and_clears_the_cost(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $cashBefore = $this->balance($this->cash());
        $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 30, 'treasury_account_id' => $this->cash()->id],
            ['name' => 'تحميل', 'amount' => 10],
        ])->assertCreated();
        $this->assertSame('110.00', $this->owedToVendor($vendor));
        $headers = $this->receiver();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/receipt-reversal",
            ['reason' => 'استُلمت على الأمر الخطأ'],
        );

        // Assert
        $response->assertOk();
        $this->assertSame($cashBefore, $this->balance($this->cash()));
        $this->assertSame('100.00', $this->owedToVendor($vendor));
        $this->assertSame(0, PurchaseOrderAdditionalCost::query()->where('purchase_order_id', $order['id'])->count());
        $this->assertNull($this->line($order, $bags)->landed_unit_cost);

        $saved = PurchaseOrder::query()->findOrFail($order['id']);
        $this->assertSame('100.00', (string) $saved->total_amount);
        $this->assertSame('0.00', (string) $saved->total_additional_cost);
    }

    public function test_reversing_a_funded_receipt_reverses_the_deals_expense(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]]);
        $deal = $this->fundLine($order, $bags);
        $cashBefore = $this->balance($this->cash());
        $this->receive($order, [[$bags, 10]], [
            ['name' => 'نقل', 'amount' => 40, 'treasury_account_id' => $this->cash()->id],
        ])->assertCreated();
        $headers = $this->receiver();
        $this->forgetAuth();

        // Act
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/receipt-reversal",
            ['reason' => 'خطأ في الكمية'],
        )->assertOk();

        // Assert
        $expense = InvestorDealExpense::query()->where('investor_deal_id', $deal->id)->whereNull('reverses_expense_id')->sole();
        $this->assertTrue($expense->isReversed());
        $this->assertSame($cashBefore, $this->balance($this->cash()));
    }

    // ─────────────────────────── planned costs ───────────────────────────

    public function test_a_planned_cost_paid_from_a_drawer_follows_every_edit(): void
    {
        // Arrange — 20 delivery paid in advance from the cash box
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $cashBefore = $this->balance($this->cash());
        $order = $this->order($vendor, [[$bags, 10, 100]], [
            ['name' => 'توصيل', 'amount' => 20, 'treasury_account_id' => $this->cash()->id],
        ]);
        $this->assertSame(bcsub($cashBefore, '20', 2), $this->balance($this->cash()));
        $this->assertSame('100.00', $this->owedToVendor($vendor));
        $costId = $order['additional_costs'][0]['id'];
        $headers = $this->buyer();
        $this->forgetAuth();

        // Act — the driver asked for 25
        $edit = fn (array $costs) => $this->withHeaders($headers)->putJson("/api/v1/purchase-orders/{$order['id']}", [
            'vendor_id' => $vendor->id,
            'warehouse_id' => $order['warehouse_id'],
            'order_date' => now()->toDateString(),
            'items' => [['id' => $order['items'][0]['id'], 'stock_item_id' => $bags->id, 'quantity_ordered' => 10, 'base_total_cost' => 100]],
            'additional_costs' => $costs,
        ]);
        $edit([['id' => $costId, 'name' => 'توصيل', 'amount' => 25, 'treasury_account_id' => $this->cash()->id]])
            ->assertOk()
            ->assertJsonPath('data.additional_costs.0.treasury_account.id', $this->cash()->id);

        // Assert
        $this->assertSame(bcsub($cashBefore, '25', 2), $this->balance($this->cash()));
        $this->assertSame('100.00', $this->owedToVendor($vendor));

        // And moved onto the vendor's bill: the drawer has it back, the vendor is owed it.
        $edit([['id' => $costId, 'name' => 'توصيل', 'amount' => 25]])->assertOk();
        $this->assertSame($cashBefore, $this->balance($this->cash()));
        $this->assertSame('125.00', $this->owedToVendor($vendor));
    }

    public function test_a_buyer_without_the_treasury_grant_may_still_edit_an_order_whose_cost_was_paid(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $bags = StockItem::factory()->create();
        $order = $this->order($vendor, [[$bags, 10, 100]], [
            ['name' => 'توصيل', 'amount' => 20, 'treasury_account_id' => $this->cash()->id],
        ]);
        $headers = $this->auth(PermissionName::ViewPurchaseOrders, PermissionName::ManagePurchaseOrders);
        $this->forgetAuth();

        // Act — the cost sent back untouched, the quantity changed
        $response = $this->withHeaders($headers)->putJson("/api/v1/purchase-orders/{$order['id']}", [
            'vendor_id' => $vendor->id,
            'warehouse_id' => $order['warehouse_id'],
            'order_date' => now()->toDateString(),
            'items' => [['id' => $order['items'][0]['id'], 'stock_item_id' => $bags->id, 'quantity_ordered' => 12, 'base_total_cost' => 120]],
            'additional_costs' => [[
                'id' => $order['additional_costs'][0]['id'],
                'name' => 'توصيل',
                'amount' => '20.00',
                'treasury_account_id' => $this->cash()->id,
            ]],
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.vendor_amount', '120.00');
    }
}
