<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
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
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «مصدر الربح» — كلُّ بوّابةٍ من بوّابات ربحه الثلاث تُفتح على ما صنعها.
 *
 * **والعهدُ الذي يقوم عليه كلُّ شيء: مجموعُ القائمة رقمُ بوّابتها على البطاقة.** فكلُّ اختبارٍ
 * هنا يقرأ البطاقةَ من `GET /investors/{id}` ويقارنها بالقائمة، لا برقمٍ محفوظٍ في الاختبار.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestorProfitSourcesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

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
        ]);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, mixed> */
    private function sources(array $headers, Investor $investor, string $gate): array
    {
        return $this->withHeaders($headers)
            ->getJson("/api/v1/investors/{$investor->id}/profit-sources?gate={$gate}")
            ->assertOk()
            ->json('data');
    }

    /** @return array<string, mixed> */
    private function card(array $headers, Investor $investor): array
    {
        return $this->withHeaders($headers)
            ->getJson("/api/v1/investors/{$investor->id}")
            ->assertOk()
            ->json('data.profit_figures');
    }

    // ─────────────────────────── a ledger written by hand ───────────────────────────

    private function period(string $startsOn, PeriodStatus $status): InvestmentPeriod
    {
        $starts = Carbon::parse($startsOn);

        // المغلقةُ تحمل أرقامَها مجمّدةً — قيدُ `investment_periods_shape` — وما يهمّ هنا حالتُها.
        $frozen = $status !== PeriodStatus::Closed ? [] : [
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
        ];

        return InvestmentPeriod::factory()->create([
            'status' => $status,
            'starts_on' => $starts->toDateString(),
            'ends_on' => $starts->copy()->endOfMonth()->toDateString(),
            'subscription_closes_on' => $starts->copy()->addDays(6)->toDateString(),
            ...$frozen,
        ]);
    }

    /** طلبيةٌ سُلِّمت، مدفوعةً كلُّها أو لا شيءَ منها — وهو ما تسأله بوّابةُ التحصيل. */
    private function order(bool $paid): Order
    {
        return Order::factory()->create([
            'status' => OrderStatus::Delivered,
            'grand_total' => '1000.00',
            'paid_amount' => $paid ? '1000.00' : '0.00',
            'delivered_at' => now(),
        ]);
    }

    /** @param  array<string, mixed>  $columns */
    private function row(Investor $investor, WalletEntryType $type, string $amount, array $columns = []): int
    {
        return (int) DB::table('investor_wallet_entries')->insertGetId([
            'investor_id' => $investor->id,
            'type' => $type->value,
            'amount' => $amount,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
            ...$columns,
        ]);
    }

    private function profit(Investor $investor, InvestorDeal $deal, InvestmentPeriod $period, string $amount, Order $order): void
    {
        $this->row($investor, WalletEntryType::Profit, $amount, [
            'investor_deal_id' => $deal->id,
            'investment_period_id' => $period->id,
            'source_type' => 'order',
            'source_id' => $order->id,
            'source_sequence' => 1,
        ]);
    }

    private function released(Investor $investor, InvestorDeal $deal, InvestmentPeriod $period, string $amount): void
    {
        $this->row($investor, WalletEntryType::ProfitRelease, $amount, [
            'investor_deal_id' => $deal->id,
            'investment_period_id' => $period->id,
        ]);
    }

    /**
     * ثلاثُ فترات بثلاث حالات، ومحفظةٌ سُحب منها:
     *
     * ```
     * P1 مغلقة       #1 300 مدفوعة          أُفرج عن 300
     * P2 قيد الإغلاق  #2 200 مدفوعة، #3 90 لا   أُفرج عن 200
     * P3 مفتوحة      #4 80، #5 40، مصاريف −15
     * المحفظة        سحب 250، تحويل 50 إلى رأس مال، وسحبٌ 30 عُكس
     * ```
     *
     * @return array{0: Investor, 1: array<string, Order>}
     */
    private function ledger(): array
    {
        Carbon::setTestNow('2026-10-20 09:00:00');

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $p1 = $this->period('2026-08-01', PeriodStatus::Closed);
        $p2 = $this->period('2026-09-01', PeriodStatus::Closing);
        $p3 = $this->period('2026-10-01', PeriodStatus::Open);

        $orders = [
            'one' => $this->order(paid: true),
            'two' => $this->order(paid: true),
            'three' => $this->order(paid: false),
            'four' => $this->order(paid: false),
            'five' => $this->order(paid: true),
        ];

        $this->profit($investor, $deal, $p1, '300.00', $orders['one']);
        $this->released($investor, $deal, $p1, '300.00');

        $this->profit($investor, $deal, $p2, '200.00', $orders['two']);
        $this->profit($investor, $deal, $p2, '90.00', $orders['three']);
        $this->released($investor, $deal, $p2, '200.00');

        $this->profit($investor, $deal, $p3, '80.00', $orders['four']);
        $this->profit($investor, $deal, $p3, '40.00', $orders['five']);
        $this->row($investor, WalletEntryType::Loss, '15.00', [
            'investor_deal_id' => $deal->id,
            'investment_period_id' => $p3->id,
            'source_type' => 'fund_expense_charge',
            'source_id' => 1,
            'source_sequence' => 1,
        ]);

        $this->row($investor, WalletEntryType::ProfitWithdrawal, '250.00', ['method' => 'cash']);
        $this->row($investor, WalletEntryType::ProfitCapitalisation, '50.00');
        $mistake = $this->row($investor, WalletEntryType::ProfitWithdrawal, '30.00', ['method' => 'cash']);
        $this->row($investor, WalletEntryType::Reversal, '30.00', ['reverses_entry_id' => $mistake]);

        return [$investor, $orders];
    }

    // ─────────────────────────── معلّقة ───────────────────────────

    public function test_the_pending_list_adds_up_to_the_pending_figure(): void
    {
        // Arrange
        [$investor] = $this->ledger();
        $headers = $this->manager();

        // Act
        $sources = $this->sources($headers, $investor, 'pending');

        // Assert — 90 من P2 و105 من P3.
        $this->assertSame('195.00', $sources['total']);
        $this->assertSame($this->card($headers, $investor)['pending'], $sources['total']);
        $this->assertSame(
            $sources['total'],
            number_format(array_sum(array_map(fn (array $g): float => (float) $g['total'], $sources['groups'])), 2, '.', ''),
        );
    }

    public function test_pending_is_grouped_by_period_newest_first_and_hides_what_was_all_released(): void
    {
        // Arrange
        [$investor] = $this->ledger();

        // Act
        $groups = $this->sources($this->manager(), $investor, 'pending')['groups'];

        // Assert — P1 أُفرج عنها كلُّها، فلا تظهر.
        $this->assertSame(['open', 'closing'], array_column($groups, 'status'));
        $this->assertSame(['105.00', '90.00'], array_column($groups, 'total'));

        foreach ($groups as $group) {
            $sum = array_sum(array_map(fn (array $line): float => (float) $line['amount'], $group['lines']));
            $this->assertSame($group['total'], number_format($sum, 2, '.', ''));
        }
    }

    public function test_each_order_in_pending_says_which_gate_holds_it(): void
    {
        // Arrange
        [$investor, $orders] = $this->ledger();

        // Act
        [$open, $closing] = $this->sources($this->manager(), $investor, 'pending')['groups'];

        // Assert — المفتوحةُ تنتظر موعدَها، و«قيد الإغلاق» تحجز ما لم يُدفع وتطرح ما أُفرج عنه.
        $openOrders = array_values(array_filter($open['lines'], fn (array $l): bool => $l['kind'] === 'order'));
        $this->assertEqualsCanonicalizing(
            [$orders['four']->id, $orders['five']->id],
            array_column($openOrders, 'order_id'),
        );
        $this->assertSame(['awaiting_period_end'], array_values(array_unique(array_column($openOrders, 'state'))));

        $expenses = array_values(array_filter($open['lines'], fn (array $l): bool => $l['key'] === 'expenses'));
        $this->assertSame('-15.00', $expenses[0]['amount']);

        $states = [];

        foreach ($closing['lines'] as $line) {
            $states[$line['kind'] === 'order' ? $line['order_id'] : $line['key']] = [$line['state'] ?? null, $line['amount']];
        }

        $this->assertSame(['awaiting_payment', '90.00'], $states[$orders['three']->id]);
        $this->assertSame(['released', '200.00'], $states[$orders['two']->id]);
        $this->assertSame([null, '-200.00'], $states['type:profit_release']);

        // الأبعدُ عن الجيب أوّلاً، والإفراجُ آخرُ المجموعة.
        $this->assertSame($orders['three']->id, $closing['lines'][0]['order_id']);
        $this->assertSame('type:profit_release', end($closing['lines'])['key']);
    }

    // ─────────────────────────── متاحة للسحب ───────────────────────────

    public function test_the_available_reconciliation_adds_up_to_the_available_figure(): void
    {
        // Arrange
        [$investor] = $this->ledger();
        $headers = $this->manager();

        // Act
        $sources = $this->sources($headers, $investor, 'available');

        // Assert — 300 + 200 − 250 − 50.
        $this->assertSame('200.00', $sources['total']);
        $this->assertSame($this->card($headers, $investor)['available'], $sources['total']);

        $lines = $sources['groups'][0]['lines'];
        $sum = array_sum(array_map(fn (array $line): float => (float) $line['amount'], $lines));
        $this->assertSame('200.00', number_format($sum, 2, '.', ''));
    }

    public function test_each_release_opens_onto_the_orders_it_paid_and_a_reversed_withdrawal_drops_out(): void
    {
        // Arrange
        [$investor, $orders] = $this->ledger();

        // Act
        $lines = $this->sources($this->manager(), $investor, 'available')['groups'][0]['lines'];

        // Assert — إفراجان، وسحبٌ وتحويل؛ والسحبُ المعكوس وعكسُه لا يظهران.
        $this->assertCount(4, $lines);

        $releases = array_values(array_filter($lines, fn (array $l): bool => $l['kind'] === 'release'));
        $byAmount = array_column($releases, null, 'amount');

        $this->assertSame([$orders['one']->id], array_column($byAmount['300.00']['children'], 'order_id'));

        // #3 لم يُدفع فلم يُفرج عنه — ليس تحت إفراج P2.
        $this->assertSame([$orders['two']->id], array_column($byAmount['200.00']['children'], 'order_id'));

        $entries = array_values(array_filter($lines, fn (array $l): bool => $l['kind'] === 'entry'));
        $this->assertEqualsCanonicalizing(['-250.00', '-50.00'], array_column($entries, 'amount'));
    }

    // ─────────────────────────── قيد التسليم ───────────────────────────

    public function test_the_awaiting_list_names_the_orders_behind_the_figure(): void
    {
        // Arrange — طلبيةٌ من بضاعة الصندوق بلغت «جاهزة» ولم تُسلَّم.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->manager();
        $investor = $this->subscribe('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size);
        $this->toReady($headers, $order, $warehouse);

        // Act
        $sources = $this->sources($headers, $investor, 'awaiting_delivery');

        // Assert
        $card = $this->card($headers, $investor);
        $this->assertSame($card['awaiting_delivery'], $sources['total']);
        $this->assertSame(1, bccomp($sources['total'], '0', 2));

        $line = $sources['groups'][0]['lines'][0];
        $this->assertSame($order->id, $line['order_id']);
        $this->assertSame((string) $order->code, $line['code']);
        $this->assertSame('awaiting_delivery', $line['state']);
        $this->assertSame($sources['total'], $line['amount']);
        $this->assertSame(app(ProfitAwaitingDelivery::class)->ordersOf((int) $investor->id), [$order->id => $line['amount']]);
    }

    public function test_an_investor_with_nothing_gets_empty_lists(): void
    {
        // Arrange
        $investor = Investor::factory()->create();
        $headers = $this->manager();

        // Act & Assert
        foreach (['awaiting_delivery', 'pending', 'available'] as $gate) {
            $sources = $this->sources($headers, $investor, $gate);

            $this->assertSame('0.00', $sources['total']);
            $this->assertSame([], $sources['groups']);
        }
    }

    public function test_an_unknown_gate_is_refused(): void
    {
        // Arrange
        $investor = Investor::factory()->create();

        // Act
        $response = $this->withHeaders($this->manager())
            ->getJson("/api/v1/investors/{$investor->id}/profit-sources?gate=everything");

        // Assert
        $response->assertUnprocessable();
    }

    public function test_it_needs_the_permission_to_view_investors(): void
    {
        // Arrange
        $investor = Investor::factory()->create();
        $user = User::factory()->create();
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investors/{$investor->id}/profit-sources?gate=pending");

        // Assert
        $response->assertForbidden();
    }

    // ─────────────────────────── the fund, end to end ───────────────────────────

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

    /** @return array{0: ProductVariant, 1: Warehouse} */
    private function shipment(array $headers): array
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
            ['stock_item_ids' => [$size->stock_item_id]],
        )->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$purchase->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '500.000']]],
        )->assertCreated();

        return [$size, $warehouse];
    }

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

    private function toReady(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->getKey()],
        ])->assertOk();

        foreach ([OrderStatus::Printing, OrderStatus::Ready] as $status) {
            $this->withHeaders($headers)->postJson(
                "/api/v1/orders/{$order->id}/status",
                ['status' => $status->value],
            )->assertOk();
        }
    }
}
