<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\ProfitAwaitingDelivery;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Actions\ResolveOrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «ربح قيد التسليم» — أوّلُ الأرقام الثلاثة في المحفظة، والوحيدُ الذي لا صفَّ له في الدفتر.
 *
 * المواصفة: §٠.٨ و§١٢أ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ```
 * ربح قيد التسليم  →  أرباح معلّقة  →  أرباح متاحة للسحب
 * (محسوبٌ لا مقيَّد)    (profit_deal)     (profit_wallet)
 * ```
 *
 * **ويُسعَّر ما بلغ «جاهزة» وحده** — «في حالة الجاهزة تقدر تحسبها، قبل ذلك تكون مجهولة».
 * والرقمُ ليس تقديراً: هو بالضبط ما سيقيّده التسليمُ، بالقسمة نفسها والنسب نفسها.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class ProfitAwaitingDeliveryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Carbon::setTestNow('2026-09-01 09:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    // ─────────────────────────── people ───────────────────────────

    /** @return array<string, string> */
    private function manager(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
            PermissionName::RecordInvestorMoney->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
            PermissionName::ViewPurchaseOrders->value,
            PermissionName::ManagePurchaseOrders->value,
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::MoveOrderToReadyToPrint->value,
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::MoveOrderToReady->value,
            PermissionName::DispatchOrders->value,
            PermissionName::MarkOrdersDelivered->value,
        ]);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    // ─────────────────────────── the fund ───────────────────────────

    /** مالٌ على الطاولة أولاً، ثم اشتراكٌ به في الصندوق. */
    private function subscribe(string $amount): Investor
    {
        $investor = Investor::factory()->create();

        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        app(DepositToFund::class)(investorId: (int) $investor->id, amount: $amount, actorId: null);

        return $investor;
    }

    // ─────────────────────────── goods ───────────────────────────

    private function bagSize(): ProductVariant
    {
        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Kilogram,
            'product_category_id' => ProductCategory::factory()->investable()->create()->getKey(),
            'is_active' => true,
        ]);

        return ProductVariant::factory()->for($product)->create([
            'label' => '25*35',
            'stock_item_id' => StockItem::factory()->unit(PricingUnit::Kilogram)->create()->getKey(),
        ]);
    }

    /**
     * الصندوقُ يشتري ٥٠٠ كغ بتكلفة 25.000 **بلا سعر سادة** — فطريقُه ربحُ الطلبية عند التسليم،
     * لا هامشُ المكينة عند «جاهزة للطباعة».
     *
     * @return array{0: ProductVariant, 1: Warehouse}
     */
    private function shipment(array $headers): array
    {
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();

        $purchase = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        PurchaseOrderItem::factory()->forOrder($purchase)->create([
            'stock_item_id' => $size->stock_item_id,
            'quantity_ordered' => '500.000',
            'base_total_cost' => '12500.00',
            'base_unit_cost' => '25.000',
            'allocated_additional_cost' => '0.00',
            'final_unit_cost' => '25.000',
            'final_total_cost' => '12500.00',
        ]);

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$purchase->id}/fund-purchase",
            ['stock_item_ids' => [$size->stock_item_id]],
        )->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$purchase->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '500.000']]],
        )->assertCreated();

        return [$size, $warehouse];
    }

    /** طلبيةٌ لـ٣٠٠ كيلو بسعر 60.000 — بلا إضافاتٍ تُعكّر الأرقام. */
    private function sale(ProductVariant $size): Order
    {
        $order = Order::factory()->create([
            'design_fee' => '0.00',
            'delivery_price' => '0.00',
            'discount' => '0.00',
            'additional_cost' => '0.00',
        ]);

        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '300',
            'unit_price' => '60.000',
            'line_total' => '18000.00',
            'pricing_unit' => PricingUnit::Kilogram,
        ]);

        app(RecalculateOrderTotals::class)($order->refresh());
        app(ResolveOrderFlow::class)($order->refresh());

        return $order->refresh();
    }

    /** إلى «جاهزة للطباعة» — تخرج البضاعةُ من الرفّ، ولم تُحسب تكلفةُ الإنتاج بعد. */
    private function toThePress(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->getKey()],
        ])->assertOk();
    }

    /** إلى «جاهزة» — تُحسب تكلفتُها كاملةً، فيصير لربحها رقم. */
    private function toReady(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->toThePress($headers, $order, $warehouse);

        foreach ([OrderStatus::Printing, OrderStatus::Ready] as $status) {
            $this->withHeaders($headers)->postJson(
                "/api/v1/orders/{$order->id}/status",
                ['status' => $status->value],
            )->assertOk();
        }
    }

    /** من «جاهزة» إلى باب العميل. */
    private function deliver(array $headers, Order $order): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::OutForDelivery->value,
            'fields' => ['shipping_company_id' => ShippingCompany::factory()->create()->getKey()],
        ])->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            ['status' => OrderStatus::Delivered->value],
        )->assertOk();
    }

    private function awaiting(): ProfitAwaitingDelivery
    {
        return app(ProfitAwaitingDelivery::class);
    }

    // ─────────────────────────── the figure ───────────────────────────

    public function test_an_order_whose_cost_is_frozen_is_priced_before_it_is_delivered(): void
    {
        // Arrange — شريكٌ واحد يملك الصندوقَ كلَّه، وطلبيةٌ خرجت بضاعتُها ولم تُسلَّم.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);

        // Act
        $figure = $this->awaiting()->forInvestor((int) $investor->id);

        // Assert — نصفُ ربح الطلبية نصيبُ المستثمرين، وهو وحده فيهم.
        $order->refresh();
        $expected = Money::round(bcdiv(bcsub((string) $order->grand_total, (string) $order->total_cogs, 8), '2', 8));
        $this->assertSame(1, bccomp($expected, '0', 2));
        $this->assertSame($expected, $figure['amount']);
        $this->assertSame(1, $figure['orders']);
    }

    public function test_the_figure_is_exactly_what_the_delivery_then_posts(): void
    {
        // Arrange — الرقمُ ليس تقديراً: التسليمُ يقيّده بحذافيره.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);
        $before = $this->awaiting()->forInvestor((int) $investor->id)['amount'];

        // Act
        $this->deliver($headers, $order);

        // Assert
        $posted = InvestorWalletEntry::query()
            ->where('investor_id', $investor->id)
            ->where('source_type', 'order')
            ->where('source_id', $order->id)
            ->where('type', WalletEntryType::Profit->value)
            ->sum('amount');

        $this->assertSame($before, Money::round((string) $posted));
    }

    public function test_a_delivered_order_leaves_the_figure_for_the_ledger(): void
    {
        // Arrange — سُلِّمت فصار ربحُها صفّاً في «أرباح معلّقة»، فلا يُعدّ مرّتين.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);
        $this->deliver($headers, $order);

        // Act
        $figure = $this->awaiting()->forInvestor((int) $investor->id);

        // Assert
        $this->assertSame('0.00', $figure['amount']);
        $this->assertSame(0, $figure['orders']);
    }

    public function test_an_order_whose_cost_is_not_frozen_has_no_figure_yet(): void
    {
        // Arrange — §١٢أ: «في حالة الجاهزة تقدر تحسبها، قبل ذلك تكون مجهولة». خرجت بضاعتُها
        // إلى المطبعة، ولم تُحسب تكلفةُ إنتاجها بعد — فلا رقم.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toThePress($headers, $order, $warehouse);

        // Act
        $figure = $this->awaiting()->forInvestor((int) $investor->id);

        // Assert
        $this->assertSame('0.00', $figure['amount']);
        $this->assertSame(0, $figure['orders']);
    }

    public function test_the_figure_splits_by_the_shares_of_the_orders_period(): void
    {
        // Arrange — ثلاثةُ آلافٍ وألف في نافذة الفترة الأولى: ٧٥٪ و٢٥٪.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $big = $this->subscribe('15000.00');
        $small = $this->subscribe('5000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);

        // Act
        $all = $this->awaiting()();

        // Assert — القسمةُ بنسب الفترة، والمجموعُ نصيبُ المستثمرين كاملاً بلا قرشٍ ضائع.
        $order->refresh();
        $pool = Money::round(bcdiv(bcsub((string) $order->grand_total, (string) $order->total_cogs, 8), '2', 8));
        $bigAmount = $all[(int) $big->id]['amount'];
        $smallAmount = $all[(int) $small->id]['amount'];

        $this->assertSame($pool, Money::round(bcadd($bigAmount, $smallAmount, 2)));
        $this->assertSame(Money::round(bcmul($pool, '0.75', 8)), $bigAmount);
    }

    // ─────────────────────────── the three figures on screen ───────────────────────────

    /** @return array<string, string> */
    private function portalHeadersFor(Investor $investor): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestorPortal->value);
        $investor->forceFill(['user_id' => $user->id])->save();

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_the_portal_shows_the_profit_on_its_way_first(): void
    {
        // Arrange
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);
        $figure = $this->awaiting()->forInvestor((int) $investor->id);

        // Act
        $response = $this->withHeaders($this->portalHeadersFor($investor))
            ->getJson('/api/v1/investor-portal/summary');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.profit_awaiting_delivery', $figure['amount'])
            ->assertJsonPath('data.orders_awaiting_delivery', 1);
    }

    public function test_the_portal_counts_fund_profit_among_the_pending(): void
    {
        // Arrange — شريكُ الصندوق لا صفَّ له في `investor_deal_shares`، فكان ربحُه المقيَّد في
        // الصندوق يغيب عن «أرباح معلّقة» ويظهر صفراً وهو له.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);
        $this->deliver($headers, $order);

        $posted = Money::round((string) InvestorWalletEntry::query()
            ->where('investor_id', $investor->id)
            ->where('type', WalletEntryType::Profit->value)
            ->sum('amount'));

        // Act
        $response = $this->withHeaders($this->portalHeadersFor($investor))
            ->getJson('/api/v1/investor-portal/summary');

        // Assert — سُلِّمت فانتقلت من الأول إلى الثاني.
        $response->assertOk()
            ->assertJsonPath('data.profit_awaiting_delivery', '0.00')
            ->assertJsonPath('data.profit_in_deals', $posted);
    }

    public function test_the_investor_screen_carries_the_three_figures(): void
    {
        // Arrange — المديرُ يرى ما يراه صاحبُ المال: قيد التسليم، ومعلّقة، ومتاحة للسحب.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);
        $figure = $this->awaiting()->forInvestor((int) $investor->id);

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/investors/{$investor->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.profit_figures.awaiting_delivery', $figure['amount'])
            ->assertJsonPath('data.profit_figures.orders_awaiting_delivery', 1)
            ->assertJsonPath('data.profit_figures.pending', '0.00')
            ->assertJsonPath('data.profit_figures.available', '0.00');
    }
}
