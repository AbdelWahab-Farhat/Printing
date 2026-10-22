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
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\ProfitAwaitingDelivery;
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
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «أيُّ طلبيةٍ استُلم ربحُها، وأيُّها ينتظر» — حالُ كلِّ طلبيةٍ في شاشة الفترة.
 *
 * المواصفة: §١١ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ```
 * قيد التسليم  →  بانتظار انتهاء الفترة / بانتظار التحصيل  →  تم الاستلام
 * (محسوب)          (profit_deal)                               (أُفرج عنه)
 * ```
 *
 * **والحالُ من البوّابتين اللتين يُفرج بهما الإقفالُ نفسُه** (§٠.٨) — فلا تقول الشاشةُ «استُلم»
 * عن ربحٍ يحجزه الإقفال.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PeriodOrdersByStateTest extends TestCase
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

    // ─────────────────────────── the ledger alone ───────────────────────────

    /** @return array<string, string> */
    private function viewer(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestors->value);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * فترةٌ في حالٍ بعينها. **والمغلقةُ لا تُطلب هنا**: حارسُ الدفتر يرفض الكتابة فيها، فتُكتب
     * صفوفُها في مفتوحةٍ ثم تُقفَل بـ{@see seal()}.
     */
    private function periodIn(PeriodStatus $status): InvestmentPeriod
    {
        $period = InvestmentPeriod::factory()->create();

        if ($status === PeriodStatus::Closing) {
            $period->forceFill(['status' => $status])->save();
        }

        return $period;
    }

    /** تُقفَل بأرقامٍ مجمّدة — لأن قيدَ `_shape` يشترطها كلَّها معاً. */
    private function seal(InvestmentPeriod $period): void
    {
        $period->forceFill([
            'status' => PeriodStatus::Closed,
            'closed_at' => now(),
            'closing_stock_cost' => '0.00',
            'closing_cash' => '0.00',
            'sales_revenue' => '0.00',
            'cost_of_goods_sold' => '0.00',
            'cost_damaged' => '0.00',
            'cost_short' => '0.00',
            'expenses_amount' => '0.00',
            'net_profit' => '0.00',
            'investors_pool' => '0.00',
            'company_share' => '0.00',
            'through_consumption_id' => 0,
            'through_movement_id' => 0,
            'through_wallet_entry_id' => 0,
            'through_cash_entry_id' => 0,
        ])->save();
    }

    /** ربحٌ يُكتب كما يكتبه `PostDealShare`: بمصدره وختمِ فترته. */
    private function accrue(Investor $investor, InvestmentPeriod $period, string $amount, string $sourceType, int $sourceId): InvestorWalletEntry
    {
        $entry = new InvestorWalletEntry(['amount' => $amount, 'occurred_at' => now()]);

        $entry->investor_id = $investor->id;
        $entry->investor_deal_id = InvestorDeal::factory()->create()->id;
        $entry->type = WalletEntryType::Profit;
        $entry->source_type = $sourceType;
        $entry->source_id = $sourceId;
        $entry->source_sequence = 1;
        $entry->investment_period_id = $period->id;
        $entry->save();

        return $entry;
    }

    private function unpaidOrder(): Order
    {
        return Order::factory()->create(['grand_total' => '500.00', 'paid_amount' => '100.00']);
    }

    private function paidOrder(): Order
    {
        return Order::factory()->create(['grand_total' => '400.00', 'paid_amount' => '400.00']);
    }

    private function read(InvestmentPeriod $period): TestResponse
    {
        return $this->withHeaders($this->viewer())
            ->getJson("/api/v1/investment/periods/{$period->id}/orders")
            ->assertOk();
    }

    public function test_an_open_period_holds_every_order_until_it_ends(): void
    {
        // Arrange — «لا يوجد أرباح يمكن سحبها من أي طلبية حتى تنتهي مدة الفترة».
        $period = $this->periodIn(PeriodStatus::Open);
        $ahmad = Investor::factory()->create();
        $order = $this->paidOrder();
        $this->accrue($ahmad, $period, '300.00', 'order', (int) $order->id);

        // Act
        $response = $this->read($period);

        // Assert
        $response
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_period_end')
            ->assertJsonPath('data.orders.0.profit_state_label', 'بانتظار انتهاء الفترة')
            ->assertJsonPath('data.orders.0.by_state.awaiting_period_end', '300.00')
            ->assertJsonPath('data.orders.0.by_state.released', '0.00')
            ->assertJsonPath('data.orders.0.uncollected', false)
            ->assertJsonPath('data.totals.by_state.awaiting_period_end.orders', 1)
            ->assertJsonPath('data.totals.by_state.awaiting_period_end.amount', '300.00')
            ->assertJsonPath('data.totals.by_state.released.orders', 0);
    }

    public function test_an_unpaid_order_in_an_open_period_says_its_profit_will_be_held(): void
    {
        // Arrange — قرارُ المالك ٣: «غير محصّلة» تحت الحالة، ليُرى قبل الإقفال أن ربحها سيُحجز.
        $period = $this->periodIn(PeriodStatus::Open);
        $ahmad = Investor::factory()->create();
        $order = $this->unpaidOrder();
        $this->accrue($ahmad, $period, '300.00', 'order', (int) $order->id);

        // Act
        $response = $this->read($period);

        // Assert
        $response
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_period_end')
            ->assertJsonPath('data.orders.0.uncollected', true);
    }

    public function test_a_plain_bag_margin_is_not_flagged_as_uncollected(): void
    {
        // Arrange — هامشُ السادة لا تمرّ عليه بوّابةُ التحصيل، فلا يُنذَر بحجزه.
        $period = $this->periodIn(PeriodStatus::Open);
        $ahmad = Investor::factory()->create();
        $order = $this->unpaidOrder();
        $line = OrderItem::factory()->create(['order_id' => $order->id]);
        $this->accrue($ahmad, $period, '96.00', 'order_item', (int) $line->id);

        // Act
        $response = $this->read($period);

        // Assert
        $response->assertJsonPath('data.orders.0.uncollected', false);
    }

    public function test_a_period_awaiting_its_money_releases_the_paid_and_holds_the_unpaid(): void
    {
        // Arrange — §٠.٨: «قيد الإغلاق» أفرجت عن ربح ما حُصِّل، وتحجز ربحَ ما لم يُحصَّل.
        $period = $this->periodIn(PeriodStatus::Closing);
        $ahmad = Investor::factory()->create();
        $paid = $this->paidOrder();
        $unpaid = $this->unpaidOrder();
        $this->accrue($ahmad, $period, '50.00', 'order', (int) $paid->id);
        $this->accrue($ahmad, $period, '70.00', 'order', (int) $unpaid->id);

        // Act
        $orders = collect($this->read($period)->json('data.orders'))->keyBy('order_id');

        // Assert
        $this->assertSame('released', $orders[$paid->id]['profit_state']);
        $this->assertSame('استُلم الربح', $orders[$paid->id]['profit_state_label']);
        $this->assertSame('awaiting_payment', $orders[$unpaid->id]['profit_state']);
        $this->assertSame('70.00', $orders[$unpaid->id]['by_state']['awaiting_payment']);
    }

    public function test_the_ledger_states_add_up_to_the_investors_total(): void
    {
        // Arrange — كلُّ صفٍّ تحت حالةٍ واحدة، فلا يضيع قرشٌ بين الحالات ولا يُعدّ مرّتين.
        $period = $this->periodIn(PeriodStatus::Closing);
        $ahmad = Investor::factory()->create();
        $salem = Investor::factory()->create();
        $paid = $this->paidOrder();
        $unpaid = $this->unpaidOrder();
        $this->accrue($ahmad, $period, '50.00', 'order', (int) $paid->id);
        $this->accrue($salem, $period, '25.00', 'order', (int) $paid->id);
        $this->accrue($ahmad, $period, '70.00', 'order', (int) $unpaid->id);

        // Act
        $totals = $this->read($period)->json('data.totals');

        // Assert
        $this->assertSame('145.00', $totals['investors_total']);
        $this->assertSame('75.00', $totals['by_state']['released']['amount']);
        $this->assertSame('70.00', $totals['by_state']['awaiting_payment']['amount']);
        $this->assertSame('0.00', $totals['by_state']['awaiting_period_end']['amount']);
        $this->assertSame(1, $totals['by_state']['released']['orders']);
        $this->assertSame(1, $totals['by_state']['awaiting_payment']['orders']);
    }

    public function test_a_closed_period_has_released_everything(): void
    {
        // Arrange — «مغلقة» تعني لم يبقَ شيء: لا تُغلق وفيها ما يُحجز إلا بتجاوز.
        $period = $this->periodIn(PeriodStatus::Open);
        $ahmad = Investor::factory()->create();
        $order = $this->unpaidOrder();
        $this->accrue($ahmad, $period, '300.00', 'order', (int) $order->id);
        $this->seal($period);

        // Act
        $response = $this->read($period);

        // Assert
        $response
            ->assertJsonPath('data.orders.0.profit_state', 'released')
            ->assertJsonPath('data.totals.by_state.released.amount', '300.00')
            ->assertJsonPath('data.totals.by_state.awaiting_payment.orders', 0);
    }

    public function test_an_order_split_across_two_gates_shows_each_part_under_its_own(): void
    {
        // Arrange — هامشُ السادة أُفرج عنه، وربحُ التسليم محجوزٌ لأن العميل لم يدفع: الطلبيةُ
        // تحت المرشّحين معاً، وحالتُها على البطاقة أبعدُ جزءَيها عن الجيب.
        $period = $this->periodIn(PeriodStatus::Closing);
        $ahmad = Investor::factory()->create();
        $order = $this->unpaidOrder();
        $line = OrderItem::factory()->create(['order_id' => $order->id]);
        $this->accrue($ahmad, $period, '96.00', 'order_item', (int) $line->id);
        $this->accrue($ahmad, $period, '300.00', 'order', (int) $order->id);

        // Act
        $response = $this->read($period);

        // Assert
        $response
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_payment')
            ->assertJsonPath('data.orders.0.states', ['awaiting_payment', 'released'])
            ->assertJsonPath('data.orders.0.by_state.awaiting_payment', '300.00')
            ->assertJsonPath('data.orders.0.by_state.released', '96.00')
            ->assertJsonPath('data.orders.0.investors_total', '396.00');
    }

    public function test_each_investor_sees_what_reached_the_wallet_and_what_waits(): void
    {
        // Arrange — سؤالُ المستثمر نفسُه: «كم وصلني من هذه الفترة، وكم بقي».
        $period = $this->periodIn(PeriodStatus::Closing);
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $paid = $this->paidOrder();
        $unpaid = $this->unpaidOrder();
        $this->accrue($ahmad, $period, '50.00', 'order', (int) $paid->id);
        $this->accrue($ahmad, $period, '70.00', 'order', (int) $unpaid->id);

        // Act
        $response = $this->read($period);

        // Assert
        $response
            ->assertJsonCount(1, 'data.investors')
            ->assertJsonPath('data.investors.0.name', 'أحمد')
            ->assertJsonPath('data.investors.0.amount', '120.00')
            ->assertJsonPath('data.investors.0.released', '50.00')
            ->assertJsonPath('data.investors.0.pending', '70.00')
            ->assertJsonPath('data.investors.0.expected', '0.00');
    }

    // ─────────────────────────── orders still on the road ───────────────────────────

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

    /**
     * الصندوقُ يشتري ٥٠٠ كغ بتكلفة 25.000 — بلا سعر سادة فطريقُه ربحُ الطلبية عند التسليم، وبه
     * تشتريه المطبعةُ عند «جاهزة للطباعة» فيُقبض هامشُه هناك.
     *
     * @param  array<string, string>  $headers
     * @return array{0: ProductVariant, 1: Warehouse}
     */
    private function shipment(array $headers, ?string $printingSalePrice = null): array
    {
        $warehouse = Warehouse::factory()->create();

        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Kilogram,
            'product_category_id' => ProductCategory::factory()->investable()->create()->getKey(),
            'is_active' => true,
        ]);

        $size = ProductVariant::factory()->for($product)->create([
            'label' => '25*35',
            'stock_item_id' => StockItem::factory()->unit(PricingUnit::Kilogram)->create()->getKey(),
        ]);

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
            array_filter([
                'stock_item_ids' => [$size->stock_item_id],
                'printing_sale_prices' => $printingSalePrice === null
                    ? null
                    : [$size->stock_item_id => $printingSalePrice],
            ]),
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

    /**
     * إلى «جاهزة للطباعة» — تخرج البضاعةُ من الرفّ — ثم إلى «جاهزة» إن طُلب، فيصير لربحها رقم.
     *
     * @param  array<string, string>  $headers
     */
    private function advance(array $headers, Order $order, Warehouse $warehouse, bool $toReady): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->getKey()],
        ])->assertOk();

        if (! $toReady) {
            return;
        }

        foreach ([OrderStatus::Printing, OrderStatus::Ready] as $status) {
            $this->withHeaders($headers)->postJson(
                "/api/v1/orders/{$order->id}/status",
                ['status' => $status->value],
            )->assertOk();
        }
    }

    /** @param  array<string, string>  $headers */
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

    /** @param  array<string, string>  $headers */
    private function readOpen(array $headers): TestResponse
    {
        $period = InvestmentPeriod::query()->where('status', PeriodStatus::Open)->firstOrFail();

        return $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders")
            ->assertOk();
    }

    public function test_an_order_at_the_press_is_counted_on_the_road_without_a_figure(): void
    {
        // Arrange — §١٢أ: «قبل ذلك تكون مجهولة». خرجت بضاعتُها ولم تُحسب تكلفةُ إنتاجها.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->advance($headers, $order, $warehouse, toReady: false);

        // Act
        $response = $this->readOpen($headers);

        // Assert — تظهر ولا تدخل «من كم طلبية» ربحُ الدفتر، لأن لا صفَّ لها فيه بعد.
        $response
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $order->id)
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_delivery')
            ->assertJsonPath('data.orders.0.profit_state_label', 'قيد التسليم')
            ->assertJsonPath('data.orders.0.by_state.awaiting_delivery', null)
            ->assertJsonPath('data.orders.0.investors', [])
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.orders', 1)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.unpriced', 1)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.amount', '0.00')
            ->assertJsonPath('data.totals.orders', 0)
            ->assertJsonPath('data.totals.investors_total', '0.00');
    }

    public function test_a_ready_order_on_the_road_carries_the_figure_the_dashboard_shows(): void
    {
        // Arrange — رقمُ «قيد التسليم» هنا هو رقمُ المحفظة نفسُه، لا حسابٌ ثانٍ.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->advance($headers, $order, $warehouse, toReady: true);
        $figure = app(ProfitAwaitingDelivery::class)->forInvestor((int) $investor->id)['amount'];

        // Act
        $response = $this->readOpen($headers);

        // Assert
        $this->assertSame(1, bccomp($figure, '0', 2));
        $response
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_delivery')
            ->assertJsonPath('data.orders.0.by_state.awaiting_delivery', $figure)
            ->assertJsonPath('data.orders.0.expected_investors.0.investor_id', (int) $investor->id)
            ->assertJsonPath('data.orders.0.expected_investors.0.amount', $figure)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.amount', $figure)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.unpriced', 0)
            ->assertJsonPath('data.investors.0.investor_id', (int) $investor->id)
            ->assertJsonPath('data.investors.0.expected', $figure)
            ->assertJsonPath('data.investors.0.amount', '0.00');
    }

    public function test_an_order_the_press_bought_outright_is_not_waiting_on_delivery(): void
    {
        // Arrange — المالك 2026-10-19: «ليش متوقّع 0 والربح 30». المطبعةُ اشترت السادةَ عند
        // «جاهزة للطباعة» فقُبض هامشُه هناك، وما يأتي بالتسليم للشركة — فلا ينتظر المستثمرون منها
        // شيئاً، ولا تُعدّ في «قيد التسليم» ولا يُكتب تحتها «متوقّع: 0».
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers, printingSalePrice: '32.000');
        $order = $this->sale($size);
        $this->advance($headers, $order, $warehouse, toReady: true);

        // Act
        $response = $this->readOpen($headers);

        // Assert — هامشُها وحده، تحت حالته، ومرّةً واحدة.
        $response
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $order->id)
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_period_end')
            ->assertJsonPath('data.orders.0.states', ['awaiting_period_end'])
            ->assertJsonPath('data.orders.0.by_state.awaiting_delivery', null)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.orders', 0)
            ->assertJsonPath('data.totals.by_state.awaiting_period_end.orders', 1);
    }

    public function test_a_delivered_order_leaves_the_road_for_the_ledger(): void
    {
        // Arrange — سُلِّمت فصار ربحُها صفّاً، والفترةُ مفتوحة: تنتظر نهايتَها لا التسليم.
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->advance($headers, $order, $warehouse, toReady: true);
        $this->deliver($headers, $order);

        // Act
        $response = $this->readOpen($headers);

        // Assert
        $response
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.profit_state', 'awaiting_period_end')
            ->assertJsonPath('data.orders.0.states', ['awaiting_period_end'])
            ->assertJsonPath('data.orders.0.by_state.awaiting_delivery', null)
            ->assertJsonPath('data.totals.by_state.awaiting_delivery.orders', 0)
            ->assertJsonPath('data.totals.orders', 1);
    }
}
