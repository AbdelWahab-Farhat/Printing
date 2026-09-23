<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * ما وراء كلِّ رقمٍ في لوحة الصندوق — «من أين أتى هذا النقد، وما هذه البضاعة، وأيُّ طلبية».
 *
 * طلبُ المالك 2026-09-24: النقدُ يُفتح على سجلّه كاملاً داخلاً وخارجاً، والبضاعةُ على الرفّ
 * تُفتح على موادّها، والخارجةُ والمسلَّمةُ غيرُ المحصَّلة على طلبياتها، والأرباحُ المستحقّة على
 * الطلبيات التي صنعتها وربح كلٍّ منها.
 *
 * **والقاعدةُ التي يقوم عليها كلُّ اختبارٍ هنا: مجموعُ القائمة هو رقمُ اللوحة بعينه.** قائمةٌ
 * لا تجمع إلى الرقم الذي فُتحت منه تفتح سؤالاً بدل أن تجيبه — فكلُّ مجموعٍ يُقارَن بما تقوله
 * {@see FundValuation} للمشهد نفسه، لا برقمٍ مكتوبٍ باليد وحده.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundBreakdownTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Carbon::setTestNow('2026-09-24 12:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    private function headersFor(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function viewer(): array
    {
        return $this->headersFor([PermissionName::ViewInvestors]);
    }

    /** @return array<string, string> */
    private function value(): array
    {
        return app(FundValuation::class)();
    }

    // ── النقد ─────────────────────────────────────────────────────────────────────────────

    /** صفٌّ في الخزينة كما يكتبه أيُّ بابٍ من أبوابها — بمصدره وتسلسله ويومه. */
    private function cash(
        CashEntryType $type,
        string $amount,
        string $sourceType,
        int $sourceId,
        string $at,
        int $sequence = 1,
        ?string $notes = null,
    ): int {
        return (int) DB::table('investment_cash_entries')->insertGetId([
            'type' => $type->value,
            'amount' => $amount,
            'source_type' => $sourceType,
            'source_id' => $sourceId,
            'source_sequence' => $sequence,
            'occurred_at' => $at,
            'notes' => $notes,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function reverseCash(int $entryId, string $amount, string $at): void
    {
        DB::table('investment_cash_entries')->insert([
            'type' => CashEntryType::Reversal->value,
            'amount' => $amount,
            'reverses_entry_id' => $entryId,
            'occurred_at' => $at,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /** صفُّ إيداعٍ في محفظة — ما يسمّيه صفُّ الخزينة مصدراً. */
    private function walletDeposit(Investor $investor, string $amount): int
    {
        return (int) DB::table('investor_wallet_entries')->insertGetId([
            'investor_id' => $investor->id,
            'investor_deal_id' => null,
            'type' => WalletEntryType::Deposit->value,
            'amount' => $amount,
            'method' => 'cash',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_the_cash_log_says_where_every_dinar_came_from_and_where_it_went(): void
    {
        // Arrange — إيداعٌ دخل، وأمرُ شراءٍ خرج، وتحصيلُ طلبيةٍ دخل: الحكايةُ كلُّها بأيامها.
        $investor = Investor::factory()->create(['name' => 'عبدالرحمن']);
        $customer = Customer::factory()->create(['name' => 'محمد الساعدي']);
        $order = Order::factory()->create(['customer_id' => $customer->id]);
        $vendor = Vendor::factory()->create(['name' => 'مصنع الأكياس']);
        $purchase = PurchaseOrder::factory()->create(['vendor_id' => $vendor->id]);

        $this->cash(CashEntryType::Deposit, '5000.00', 'investor_wallet_entry', $this->walletDeposit($investor, '5000.00'), '2026-09-20 10:00:00');
        $this->cash(CashEntryType::Purchase, '3000.00', 'purchase_order', (int) $purchase->id, '2026-09-21 10:00:00');
        $this->cash(CashEntryType::SaleProceeds, '800.00', 'order', (int) $order->id, '2026-09-23 10:00:00');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/cash');

        // Assert — الأحدثُ أوّلاً، بإشارته، وبما بقي في الخزينة بعده.
        $response->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.type', 'sale_proceeds')
            ->assertJsonPath('data.0.type_label', 'تحصيل مبيعات')
            ->assertJsonPath('data.0.signed_amount', '800.00')
            ->assertJsonPath('data.0.balance_after', '2800.00')
            ->assertJsonPath('data.0.description', 'طلبية '.$order->fresh()->code.' · محمد الساعدي')
            ->assertJsonPath('data.0.order_id', $order->id)
            ->assertJsonPath('data.1.type', 'purchase')
            ->assertJsonPath('data.1.signed_amount', '-3000.00')
            ->assertJsonPath('data.1.balance_after', '2000.00')
            ->assertJsonPath('data.1.description', 'أمر شراء #'.$purchase->id.' · مصنع الأكياس')
            ->assertJsonPath('data.1.purchase_order_id', $purchase->id)
            ->assertJsonPath('data.2.type', 'deposit')
            ->assertJsonPath('data.2.signed_amount', '5000.00')
            ->assertJsonPath('data.2.balance_after', '5000.00')
            ->assertJsonPath('data.2.description', 'عبدالرحمن')
            ->assertJsonPath('data.2.investor_id', $investor->id);

        // والرصيدُ هو نقدُ اللوحة بعينه.
        $response->assertJsonPath('meta.balance', '2800.00');
        $this->assertSame($this->value()['cash'], $response->json('meta.balance'));
    }

    public function test_a_corrected_collection_shows_once_at_the_figure_that_stands(): void
    {
        // Arrange — العميلُ دفع على دفعتين، فصُحّح تحصيلُ الصندوق: عُكس الأول وكُتب الثاني بالمجموع.
        // صفّا التصحيح يتعادلان، والسجلُّ يقول ما بقي قائماً لا خطواتِ الحساب.
        $investor = Investor::factory()->create();
        $order = Order::factory()->create();

        $this->cash(CashEntryType::Deposit, '1000.00', 'investor_wallet_entry', $this->walletDeposit($investor, '1000.00'), '2026-09-19 10:00:00');
        $first = $this->cash(CashEntryType::SaleProceeds, '100.00', 'order', (int) $order->id, '2026-09-20 10:00:00');
        $this->reverseCash($first, '100.00', '2026-09-22 10:00:00');
        $this->cash(CashEntryType::SaleProceeds, '250.00', 'order', (int) $order->id, '2026-09-22 10:00:00', sequence: 2);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/cash');

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.signed_amount', '250.00')
            ->assertJsonPath('data.0.balance_after', '1250.00')
            ->assertJsonPath('data.1.signed_amount', '1000.00')
            ->assertJsonPath('meta.balance', '1250.00');

        $this->assertSame(app(FundCash::class)(), $response->json('meta.balance'));
    }

    public function test_money_that_left_names_what_it_left_for(): void
    {
        // Arrange — مصروفٌ باسمه، ونصيبُ الشركة بفترته.
        $period = InvestmentPeriod::factory()->create(['code' => 'P1']);
        $expense = (int) DB::table('investor_deal_expenses')->insertGetId([
            'investor_deal_id' => app(FundDeal::class)()->id,
            'kind' => DealExpenseKind::Transport->value,
            'name' => 'أجرة شاحنة',
            'amount' => '120.00',
            'incurred_on' => '2026-09-22',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->cash(CashEntryType::Expense, '120.00', 'investor_deal_expense', $expense, '2026-09-22 10:00:00');
        $this->cash(CashEntryType::CompanyPayout, '300.00', 'investment_period', (int) $period->id, '2026-09-23 10:00:00');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/cash');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.type_label', 'نصيب الشركة')
            ->assertJsonPath('data.0.description', 'الفترة P1')
            ->assertJsonPath('data.0.signed_amount', '-300.00')
            ->assertJsonPath('data.1.type_label', 'مصروف')
            ->assertJsonPath('data.1.description', 'أجرة شاحنة')
            ->assertJsonPath('data.1.signed_amount', '-120.00')
            ->assertJsonPath('meta.balance', '-420.00');
    }

    public function test_the_cash_log_pages_and_keeps_its_running_balance_across_pages(): void
    {
        // Arrange — اثنان وثلاثون إيداعاً بمئةٍ كلٌّ، يوماً بعد يوم.
        $investor = Investor::factory()->create();

        foreach (range(1, 32) as $day) {
            $this->cash(
                CashEntryType::Deposit,
                '100.00',
                'investor_wallet_entry',
                $this->walletDeposit($investor, '100.00'),
                Carbon::parse('2026-08-01 10:00:00')->addDays($day)->toDateTimeString(),
            );
        }

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/cash?page=2');

        // Assert — الصفحةُ الثانية أقدمُ صفّين، ورصيدُ كلٍّ منهما ما كان يومَه لا ما هو اليوم.
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.current_page', 2)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonPath('meta.total', 32)
            ->assertJsonPath('data.0.balance_after', '200.00')
            ->assertJsonPath('data.1.balance_after', '100.00')
            ->assertJsonPath('meta.balance', '3200.00');
    }

    public function test_reading_the_cash_log_needs_the_investors_view(): void
    {
        // Arrange
        $headers = $this->headersFor([PermissionName::ViewOrders]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund/cash');

        // Assert
        $response->assertForbidden();
    }

    // ── البضاعة على الرفّ ────────────────────────────────────────────────────────────────

    public function test_the_shelf_lists_each_material_at_cost_and_adds_up_to_the_dashboard(): void
    {
        // Arrange — طبقتان من الأكياس وطبقةٌ من الرول للصندوق، وطبقةٌ للشركة ليست ماله، وطبقةٌ
        // فرغت فلا تساوي شيئاً على الرفّ.
        $fund = app(FundDeal::class)();
        $bags = StockItem::factory()->named('كيس 30×40')->create(['unit' => PricingUnit::Piece]);
        $rolls = StockItem::factory()->named('رول نايلون')->create(['unit' => PricingUnit::Kilogram]);

        StockBatch::factory()->create(['investor_deal_id' => $fund->id, 'stock_item_id' => $bags->id, 'quantity_remaining' => '400.000', 'unit_cost' => '10.000']);
        StockBatch::factory()->create(['investor_deal_id' => $fund->id, 'stock_item_id' => $bags->id, 'quantity_remaining' => '100.000', 'unit_cost' => '12.000']);
        StockBatch::factory()->create(['investor_deal_id' => $fund->id, 'stock_item_id' => $rolls->id, 'quantity_remaining' => '50.000', 'unit_cost' => '20.000', 'unit' => PricingUnit::Kilogram]);
        StockBatch::factory()->create(['investor_deal_id' => null, 'stock_item_id' => $bags->id, 'quantity_remaining' => '999.000', 'unit_cost' => '10.000']);
        StockBatch::factory()->create(['investor_deal_id' => $fund->id, 'stock_item_id' => $rolls->id, 'quantity_remaining' => '0.000', 'unit_cost' => '20.000']);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/shelf');

        // Assert — الأغلى أوّلاً، بكمّيته ووحدته وتكلفته.
        $response->assertOk()
            ->assertJsonPath('data.total', '6200.00')
            ->assertJsonCount(2, 'data.materials')
            ->assertJsonPath('data.materials.0.stock_item_id', $bags->id)
            ->assertJsonPath('data.materials.0.name', 'كيس 30×40')
            ->assertJsonPath('data.materials.0.quantity', '500.000')
            ->assertJsonPath('data.materials.0.unit_label', 'قطعة')
            ->assertJsonPath('data.materials.0.value', '5200.00')
            ->assertJsonPath('data.materials.1.name', 'رول نايلون')
            ->assertJsonPath('data.materials.1.quantity', '50.000')
            ->assertJsonPath('data.materials.1.unit_label', 'كجم')
            ->assertJsonPath('data.materials.1.value', '1000.00');

        $this->assertSame($this->value()['stock_on_shelf'], $response->json('data.total'));
    }

    // ── بضاعة خرجت ────────────────────────────────────────────────────────────────────────

    /**
     * سحبٌ من طبقةٍ لطلبية — الحركةُ واستهلاكُها وسطرُ الطلبية الذي خرجت له.
     *
     * @param  array<string, mixed>  $order
     */
    private function draw(
        StockBatch $batch,
        string $quantity,
        string $cost,
        array $order,
        bool $reversed = false,
        bool $boughtByThePress = false,
    ): Order {
        $movement = StockMovement::factory()->create([
            'movement_type' => 'order_fulfillment',
            'stock_item_id' => $batch->stock_item_id,
        ]);

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->id,
            'stock_movement_id' => $movement->id,
            'quantity' => $quantity,
            'unit_cost' => bcdiv($cost, $quantity, 3),
            'total_cost' => $cost,
        ]);

        $placed = Order::factory()->create($order);

        OrderItem::factory()->create([
            'order_id' => $placed->id,
            'fulfillment_stock_movement_id' => $movement->id,
            'stock_purchased_at' => $boughtByThePress ? now() : null,
        ]);

        if ($reversed) {
            StockMovement::factory()->create([
                'movement_type' => 'order_reversal',
                'stock_item_id' => $batch->stock_item_id,
                'reverses_movement_id' => $movement->id,
            ]);
        }

        return $placed->fresh();
    }

    /**
     * المشهدُ الواحد للبندين: طلبيةٌ في الطريق، وأخرى سُلِّمت ولم تُحصَّل، وثالثةٌ سُلِّمت وحُصِّلت،
     * ورابعةٌ اشترت المطبعةُ بضاعتَها سادةً، وخامسةٌ رجعت بضاعتُها إلى الرفّ.
     *
     * @return array{in_flight: Order, uncollected: Order, bags: StockItem}
     */
    private function goodsOut(): array
    {
        $fund = app(FundDeal::class)();
        $bags = StockItem::factory()->named('كيس 30×40')->create(['unit' => PricingUnit::Piece]);
        $batch = StockBatch::factory()->create(['investor_deal_id' => $fund->id, 'stock_item_id' => $bags->id]);
        $priced = StockBatch::factory()->create([
            'investor_deal_id' => $fund->id,
            'stock_item_id' => $bags->id,
            'printing_sale_price' => '15.000',
        ]);
        $customer = Customer::factory()->create(['name' => 'محمد الساعدي']);

        $inFlight = $this->draw($batch, '30.000', '300.00', [
            'customer_id' => $customer->id,
            'status' => 'out_for_delivery',
            'grand_total' => '600.00',
            'paid_amount' => '0.00',
            'placed_at' => '2026-09-21 10:00:00',
        ]);

        $uncollected = $this->draw($batch, '20.000', '200.00', [
            'customer_id' => $customer->id,
            'status' => 'delivered',
            'grand_total' => '500.00',
            'paid_amount' => '100.00',
            'placed_at' => '2026-09-18 10:00:00',
            'delivered_at' => '2026-09-20 10:00:00',
        ]);

        $this->draw($batch, '10.000', '100.00', [
            'status' => 'delivered',
            'grand_total' => '250.00',
            'paid_amount' => '250.00',
        ]);

        $this->draw($priced, '10.000', '100.00', ['status' => 'printing'], boughtByThePress: true);
        $this->draw($batch, '5.000', '50.00', ['status' => 'printing'], reversed: true);

        return ['in_flight' => $inFlight, 'uncollected' => $uncollected, 'bags' => $bags];
    }

    public function test_goods_in_flight_are_listed_by_order_with_the_materials_they_took(): void
    {
        // Arrange
        ['in_flight' => $order, 'bags' => $bags] = $this->goodsOut();

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/in-flight');

        // Assert — طلبيةٌ واحدة: ما اشترته المطبعةُ ليس مالَ الصندوق، وما رجع عاد إلى الرفّ.
        $response->assertOk()
            ->assertJsonPath('data.total', '300.00')
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', $order->id)
            ->assertJsonPath('data.orders.0.code', $order->code)
            ->assertJsonPath('data.orders.0.status_label', 'جاري التوصيل')
            ->assertJsonPath('data.orders.0.customer_name', 'محمد الساعدي')
            ->assertJsonPath('data.orders.0.cost', '300.00')
            ->assertJsonPath('data.orders.0.goods.0.stock_item_id', $bags->id)
            ->assertJsonPath('data.orders.0.goods.0.name', 'كيس 30×40')
            ->assertJsonPath('data.orders.0.goods.0.quantity', '30.000')
            ->assertJsonPath('data.orders.0.goods.0.unit_label', 'قطعة')
            ->assertJsonPath('data.orders.0.goods.0.cost', '300.00');

        $this->assertSame($this->value()['goods_in_flight'], $response->json('data.total'));
    }

    public function test_uncollected_goods_are_listed_with_what_the_customer_still_owes(): void
    {
        // Arrange
        ['uncollected' => $order] = $this->goodsOut();

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/receivables');

        // Assert — المحصَّلةُ كاملاً ليست هنا؛ والمتبقّي على العميل بجانب التكلفة.
        $response->assertOk()
            ->assertJsonPath('data.total', '200.00')
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', $order->id)
            ->assertJsonPath('data.orders.0.status_label', 'تم الاستلام')
            ->assertJsonPath('data.orders.0.cost', '200.00')
            ->assertJsonPath('data.orders.0.grand_total', '500.00')
            ->assertJsonPath('data.orders.0.paid_amount', '100.00')
            ->assertJsonPath('data.orders.0.remaining', '400.00')
            ->assertJsonPath('data.orders.0.goods.0.quantity', '20.000');

        $this->assertSame($this->value()['receivables_at_cost'], $response->json('data.total'));
    }

    // ── الأرباح المستحقّة ───────────────────────────────────────────────────────────────

    /** صفٌّ في دفتر المحافظ كما تكتبه الأفعال — بلا مرورٍ عليها، فما يلزم هنا أرصدتُه. */
    private function walletRow(
        Investor $investor,
        ?InvestmentPeriod $period,
        WalletEntryType $type,
        string $amount,
        ?string $sourceType = null,
        ?int $sourceId = null,
    ): void {
        $moved = in_array($type, [WalletEntryType::Deposit, WalletEntryType::Withdrawal, WalletEntryType::ProfitWithdrawal], true);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $moved ? null : app(FundDeal::class)()->id,
            'investment_period_id' => $period?->id,
            'type' => $type->value,
            'amount' => $amount,
            'method' => $moved ? 'cash' : null,
            'source_type' => $sourceType,
            'source_id' => $sourceId,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function openPeriod(): InvestmentPeriod
    {
        return InvestmentPeriod::factory()->create([
            'status' => PeriodStatus::Open,
            'starts_on' => '2026-09-01',
            'ends_on' => '2026-09-30',
        ]);
    }

    /**
     * أغسطس، انتهت نافذتُه — «قيد الإغلاق» أو مغلقاً بأرقامه.
     *
     * والمغلقةُ لا تُكتب إلا بأرقام إقفالها كلِّها: شرطُ `investment_periods_shape` يرفض
     * مغلقةً بلا ما أُقفلت عليه. وأصفارُها هنا لا تعني شيئاً — ما يُقرأ في هذا الملفّ صفوفُ
     * الدفتر المختومةُ بها، لا أرقامُ صفّها.
     */
    private function augustPeriod(PeriodStatus $status): InvestmentPeriod
    {
        $figures = $status !== PeriodStatus::Closed ? [] : [
            'closed_at' => '2026-09-02 09:00:00',
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
            'starts_on' => '2026-08-01',
            'ends_on' => '2026-08-31',
            'subscription_closes_on' => '2026-08-07',
            ...$figures,
        ]);
    }

    public function test_unreleased_profit_is_listed_order_by_order_with_each_partners_share(): void
    {
        // Arrange — فترةٌ مفتوحة: طلبيتان أعطتا شريكين، ومصروفٌ أكل من ربح أحدهما.
        $period = $this->openPeriod();
        $ahmed = Investor::factory()->create(['name' => 'أحمد']);
        $omar = Investor::factory()->create(['name' => 'عمر']);
        $first = Order::factory()->create();
        $second = Order::factory()->create();
        $expense = (int) DB::table('investor_deal_expenses')->insertGetId([
            'investor_deal_id' => app(FundDeal::class)()->id,
            'kind' => DealExpenseKind::Transport->value,
            'name' => 'أجرة شاحنة',
            'amount' => '20.00',
            'incurred_on' => '2026-09-22',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->walletRow($ahmed, $period, WalletEntryType::Profit, '60.00', 'order', (int) $first->id);
        $this->walletRow($omar, $period, WalletEntryType::Profit, '40.00', 'order', (int) $first->id);
        $this->walletRow($ahmed, $period, WalletEntryType::Profit, '30.00', 'order', (int) $second->id);
        $this->walletRow($ahmed, $period, WalletEntryType::Loss, '10.00', 'investor_deal_expense', $expense);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/profit-owed');

        // Assert — ١٢٠ = أحمد ٨٠ (٦٠ + ٣٠ − ١٠) + عمر ٤٠، وهو دَينُ اللوحة بعينه.
        $response->assertOk()
            ->assertJsonPath('data.total', '120.00')
            ->assertJsonPath('data.unreleased.total', '120.00')
            ->assertJsonPath('data.in_wallets.total', '0.00')
            ->assertJsonCount(2, 'data.unreleased.orders');

        $orders = collect($response->json('data.unreleased.orders'))->keyBy('order_id');
        $this->assertSame('100.00', $orders[$first->id]['investors_total']);
        $this->assertSame(
            [['name' => 'أحمد', 'amount' => '60.00'], ['name' => 'عمر', 'amount' => '40.00']],
            array_map(fn (array $share): array => ['name' => $share['name'], 'amount' => $share['amount']], $orders[$first->id]['investors']),
        );
        $this->assertSame('30.00', $orders[$second->id]['investors_total']);

        $response->assertJsonPath('data.unreleased.adjustments.0.kind', 'expense')
            ->assertJsonPath('data.unreleased.adjustments.0.label', 'مصروف: أجرة شاحنة')
            ->assertJsonPath('data.unreleased.adjustments.0.amount', '-10.00');

        $this->assertSame($this->value()['profit_owed'], $response->json('data.total'));
    }

    public function test_released_profit_not_yet_withdrawn_waits_in_its_owners_wallet(): void
    {
        // Arrange — فترةٌ أُقفلت فأُفرج عن ربحها، وسحب صاحبُه بعضَه.
        $closed = $this->augustPeriod(PeriodStatus::Closed);
        $ahmed = Investor::factory()->create(['name' => 'أحمد']);
        $order = Order::factory()->create(['grand_total' => '400.00', 'paid_amount' => '400.00']);

        $this->walletRow($ahmed, $closed, WalletEntryType::Profit, '100.00', 'order', (int) $order->id);
        $this->walletRow($ahmed, $closed, WalletEntryType::ProfitRelease, '100.00');
        $this->walletRow($ahmed, null, WalletEntryType::ProfitWithdrawal, '30.00');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/profit-owed');

        // Assert — لا طلبيةَ تنتظر إفراجاً؛ السبعون في محفظته حتى يسحبها.
        $response->assertOk()
            ->assertJsonPath('data.total', '70.00')
            ->assertJsonPath('data.unreleased.total', '0.00')
            ->assertJsonCount(0, 'data.unreleased.orders')
            ->assertJsonPath('data.in_wallets.total', '70.00')
            ->assertJsonPath('data.in_wallets.investors.0.investor_id', $ahmed->id)
            ->assertJsonPath('data.in_wallets.investors.0.name', 'أحمد')
            ->assertJsonPath('data.in_wallets.investors.0.amount', '70.00');

        $this->assertSame($this->value()['profit_owed'], $response->json('data.total'));
    }

    public function test_a_period_awaiting_its_money_lists_only_the_orders_still_unpaid(): void
    {
        // Arrange — §٠.٨: الفترةُ «قيد الإغلاق» أفرجت عن ربح ما حُصِّل، وبقي ربحُ ما لم يُحصَّل.
        $closing = $this->augustPeriod(PeriodStatus::Closing);
        $ahmed = Investor::factory()->create(['name' => 'أحمد']);
        $paid = Order::factory()->create(['grand_total' => '400.00', 'paid_amount' => '400.00']);
        $unpaid = Order::factory()->create(['grand_total' => '500.00', 'paid_amount' => '100.00']);

        $this->walletRow($ahmed, $closing, WalletEntryType::Profit, '50.00', 'order', (int) $paid->id);
        $this->walletRow($ahmed, $closing, WalletEntryType::Profit, '70.00', 'order', (int) $unpaid->id);
        $this->walletRow($ahmed, $closing, WalletEntryType::ProfitRelease, '50.00');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/profit-owed');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total', '120.00')
            ->assertJsonPath('data.unreleased.total', '70.00')
            ->assertJsonCount(1, 'data.unreleased.orders')
            ->assertJsonPath('data.unreleased.orders.0.order_id', $unpaid->id)
            ->assertJsonPath('data.unreleased.orders.0.investors_total', '70.00')
            ->assertJsonPath('data.in_wallets.investors.0.amount', '50.00');

        $this->assertSame($this->value()['profit_owed'], $response->json('data.total'));
    }

    public function test_a_partner_whose_losses_outweigh_his_profit_owes_nothing_here(): void
    {
        // Arrange — §٠.٨: السالبُ مطالبةٌ على صاحبه لا دَينٌ على الصندوق، فلا يُطرح من ربح شريكه
        // ولا تظهر طلبيتُه الخاسرة بين ما يُدان به.
        $period = $this->openPeriod();
        $earner = Investor::factory()->create(['name' => 'أحمد']);
        $loser = Investor::factory()->create(['name' => 'عمر']);
        $good = Order::factory()->create();
        $bad = Order::factory()->create();

        $this->walletRow($earner, $period, WalletEntryType::Profit, '100.00', 'order', (int) $good->id);
        $this->walletRow($loser, $period, WalletEntryType::Loss, '30.00', 'order', (int) $bad->id);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/profit-owed');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total', '100.00')
            ->assertJsonCount(1, 'data.unreleased.orders')
            ->assertJsonPath('data.unreleased.orders.0.order_id', $good->id);

        $this->assertSame($this->value()['profit_owed'], $response->json('data.total'));
    }

    public function test_a_loss_carried_in_from_a_past_period_is_netted_on_its_own_line(): void
    {
        // Arrange — خسارةٌ متأخّرة رُحِّلت إلى الفترة المفتوحة: تُستنزل من ربح صاحبها القادم.
        $period = $this->openPeriod();
        $ahmed = Investor::factory()->create();
        $order = Order::factory()->create();

        $this->walletRow($ahmed, $period, WalletEntryType::Profit, '100.00', 'order', (int) $order->id);
        $this->walletRow($ahmed, $period, WalletEntryType::LossCarriedIn, '30.00');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/investment/fund/profit-owed');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total', '70.00')
            ->assertJsonPath('data.unreleased.orders.0.investors_total', '100.00')
            ->assertJsonPath('data.unreleased.adjustments.0.kind', 'carried_loss')
            ->assertJsonPath('data.unreleased.adjustments.0.amount', '-30.00');

        $this->assertSame($this->value()['profit_owed'], $response->json('data.total'));
    }
}
