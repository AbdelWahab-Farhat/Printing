<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\FundExpenseChargeKind;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\FundExpenseCharge;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundExpensesQuery;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Queries\PeriodExpensesQuery;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Actions\RedrawOrderLineStock;
use App\Domain\Order\Actions\ResolveOrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * مصروفُ الصندوق على البضاعة — يتبع البضاعةَ لا تاريخَه.
 *
 * المواصفة: Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md. مصروفٌ مربوطٌ بطلب شراء يتوزّع على كل
 * وحدةٍ أدخلها الطلب: حصةُ الباقي على الرفّ تدخل تكلفتَه، وحصةُ المباع تُكتب على **فترة البيع**
 * بنسب مستثمريها — كما كُتب لهم ربحُه.
 *
 * ```
 * إيداع        20,000.00 نقداً في الصندوق
 * أمر شراء     500 كغ بتكلفة 25.000  =  12,500.00
 * المصروف      1,000.00 شحن — 2.000 على كل كيلو
 * ```
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundExpenseOnGoodsTest extends TestCase
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
            PermissionName::RecordDealExpenses->value,
            PermissionName::ReverseInvestorMoney->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
            PermissionName::ViewPurchaseOrders->value,
            PermissionName::ManagePurchaseOrders->value,
            // تكاليفُ الوصول تسمّي الدرجَ الذي دفع.
            PermissionName::RecordTreasuryOperations->value,
        ]);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function foreman(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::MoveOrderToReadyToPrint->value,
            PermissionName::CancelOrders->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    // ─────────────────────────── the fund ───────────────────────────

    /** مالٌ على الطاولة، ثم اشتراكٌ به في الصندوق. */
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

    /** سبتمبر مفتوح، وفيه شريكٌ بعشرين ألفاً. */
    private function founder(): Investor
    {
        app(OpenInvestmentPeriod::class)(actorId: null);

        return $this->subscribe('20000.00');
    }

    private function close(?string $overrideReason = null): InvestmentPeriod
    {
        return app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: $overrideReason);
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
     * أمرُ شراءٍ بأسطره — `[المقاس، الكيلوات، تكلفة الكيلو]` — بلا تكاليف إضافية.
     *
     * @param  list<array{0: ProductVariant, 1: string, 2: string}>  $lines
     */
    private function purchaseOrder(Warehouse $warehouse, array $lines): PurchaseOrder
    {
        $order = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        foreach ($lines as [$size, $kilos, $unitCost]) {
            $total = bcmul($kilos, $unitCost, 2);

            PurchaseOrderItem::factory()->forOrder($order)->create([
                'stock_item_id' => $size->stock_item_id,
                'quantity_ordered' => $kilos,
                'base_total_cost' => $total,
                'base_unit_cost' => $unitCost,
                'allocated_additional_cost' => '0.00',
                'final_unit_cost' => $unitCost,
                'final_total_cost' => $total,
            ]);
        }

        return $order->refresh();
    }

    /**
     * الصندوقُ يشتري `$fundSizes` من الطلب، ثم يُستلم كلُّه.
     *
     * @param  list<ProductVariant>  $fundSizes
     * @param  list<array{0: ProductVariant, 1: string, 2: string}>  $lines
     * @param  array<string, string>  $headers
     */
    private function receive(array $headers, PurchaseOrder $order, array $fundSizes, array $lines, ?string $printingSalePrice = null): void
    {
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            array_filter([
                'stock_item_ids' => array_map(fn (ProductVariant $size) => $size->stock_item_id, $fundSizes),
                'printing_sale_prices' => $printingSalePrice === null ? null : array_combine(
                    array_map(fn (ProductVariant $size) => $size->stock_item_id, $fundSizes),
                    array_fill(0, count($fundSizes), $printingSalePrice),
                ),
            ]),
        )->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => array_map(
                fn (array $line) => ['stock_item_id' => $line[0]->stock_item_id, 'quantity' => $line[1]],
                $lines,
            )],
        )->assertCreated();
    }

    /**
     * الطريقُ المعتاد: 500 كغ بتكلفة 25.000 يشتريها الصندوق كلَّها.
     *
     * @param  array<string, string>  $headers
     * @return array{0: ProductVariant, 1: Warehouse, 2: PurchaseOrder}
     */
    private function shipment(array $headers, ?string $printingSalePrice = null): array
    {
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $lines = [[$size, '500.000', '25.000']];
        $order = $this->purchaseOrder($warehouse, $lines);

        $this->receive($headers, $order, [$size], $lines, $printingSalePrice);

        return [$size, $warehouse, $order];
    }

    /** طلبيةُ طباعةٍ لـ`$kilos` كيلو — بلا إضافاتٍ تُعكّر الأرقام. */
    private function sale(ProductVariant $size, string $kilos): Order
    {
        $order = Order::factory()->create([
            'design_fee' => '0.00',
            'delivery_price' => '0.00',
            'discount' => '0.00',
            'additional_cost' => '0.00',
            'placed_at' => now(),
        ]);

        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => $kilos,
            'unit_price' => '60.000',
            'line_total' => bcmul($kilos, '60.000', 2),
            'pricing_unit' => PricingUnit::Kilogram,
        ]);

        app(RecalculateOrderTotals::class)($order->refresh());
        app(ResolveOrderFlow::class)($order->refresh());

        return $order->refresh();
    }

    /** البضاعةُ تخرج من الرفّ إلى المطبعة — وهذا هو «البيع» في نظر الرفّ. */
    private function sell(ProductVariant $size, string $kilos, Warehouse $warehouse): Order
    {
        $order = $this->sale($size, $kilos);

        $this->withHeaders($this->foreman())->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->getKey()],
        ])->assertOk();

        return $order->refresh();
    }

    private function cancel(Order $order): void
    {
        $this->withHeaders($this->foreman())->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'تراجع الزبون',
        ])->assertOk();
    }

    // ─────────────────────────── the expense ───────────────────────────

    /**
     * @param  array<string, string>  $headers
     */
    private function expenseOn(array $headers, PurchaseOrder $order, string $amount): InvestorDealExpense
    {
        $id = $this->withHeaders($headers)->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => 'شحن الحاوية',
            'amount' => $amount,
            'incurred_on' => now()->toDateString(),
            'purchase_order_id' => $order->id,
        ])->assertOk()->json('data.id');

        return InvestorDealExpense::query()->findOrFail($id);
    }

    /** @param  array<string, string>  $headers */
    private function reverse(array $headers, InvestorDealExpense $expense): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/investment/expenses/{$expense->id}/reverse",
            ['reason' => 'مبلغٌ خاطئ'],
        );
    }

    private function unitCostOf(ProductVariant $size): string
    {
        return (string) StockBatch::query()->where('stock_item_id', $size->stock_item_id)->orderBy('id')->firstOrFail()->unit_cost;
    }

    /** ما تحمّله مستثمرٌ من المصاريف ولم يُرَدّ إليه — صافياً. */
    private function chargedTo(Investor $investor): string
    {
        $loss = (string) InvestorWalletEntry::query()
            ->where('investor_id', $investor->id)
            ->where('type', WalletEntryType::Loss->value)
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        $credit = (string) InvestorWalletEntry::query()
            ->where('investor_id', $investor->id)
            ->where('type', WalletEntryType::Profit->value)
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        return bcsub($loss, $credit, 2);
    }

    /** @return Collection<int, FundExpenseCharge> */
    private function liveConsumerCharges(InvestorDealExpense $expense): Collection
    {
        return FundExpenseCharge::query()
            ->where('investor_deal_expense_id', $expense->id)
            ->where('kind', FundExpenseChargeKind::Consumer->value)
            ->whereNull('reverses_charge_id')
            ->whereDoesntHave('reversedBy')
            ->get();
    }

    // ─────────────────────────── the rule ───────────────────────────

    public function test_nothing_sold_puts_the_whole_expense_into_the_goods(): void
    {
        // Arrange
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, , $order] = $this->shipment($headers);

        // Act
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — 1,000 على 500 كغ = 2.000 لكل كيلو، في التكلفة لا على أحد.
        $this->assertSame('27.000', $this->unitCostOf($size));
        $this->assertSame((int) $order->id, (int) $expense->purchase_order_id);
        $this->assertSame('0.00', $this->chargedTo($founder));

        // النقدُ نقص بالمصروف كلِّه، والبضاعةُ زادت به كلِّه — فقيمةُ الصندوق لم تتحرّك.
        $value = app(FundValuation::class)();
        $this->assertSame('6500.00', $value['cash']);
        $this->assertSame('13500.00', $value['stock_on_shelf']);
    }

    public function test_what_was_sold_is_charged_to_the_period_of_the_sale_and_the_rest_rides_on_the_goods(): void
    {
        // Arrange — 300 كغ خرجت إلى المطبعة قبل أن تصل فاتورةُ الشحن.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $sale = $this->sell($size, '300', $warehouse);
        Carbon::setTestNow('2026-09-15 09:00:00');

        // Act
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — 200 كغ باقية تحمل 400 في تكلفتها، و600 على الطلبية التي أخذت الـ300.
        $this->assertSame('27.000', $this->unitCostOf($size));

        $charge = $this->liveConsumerCharges($expense)->sole();
        $this->assertSame('600.00', (string) $charge->amount);
        $this->assertSame((int) $sale->id, (int) $charge->order_id);

        // نصفُها على الشركاء (نسبتُهم من الربح 50٪)، ونصفُها تدفعه الشركة نقداً كما في كل مصروف.
        $this->assertSame('300.00', $this->chargedTo($founder));

        $september = InvestmentPeriod::query()->orderBy('starts_on')->firstOrFail();
        $this->assertSame((int) $september->id, (int) InvestorWalletEntry::query()
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->where('source_id', $charge->id)
            ->value('investment_period_id'));

        $this->assertSame('300.00', (string) InvestmentCashEntry::query()
            ->where('type', CashEntryType::ExpenseCoveredByCompany->value)
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->where('source_id', $charge->id)
            ->value('amount'));
    }

    public function test_a_partner_who_joined_after_the_sale_is_not_charged_for_it(): void
    {
        // Arrange — سبتمبر: المؤسّسُ وحده، وطلبيةٌ أخذت 300 كغ وما زالت عند المطبعة.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);

        // أكتوبر: سبتمبر ينتظر طلبيتَه، والداخلُ الجديد يكتتب فيشارك من نوفمبر.
        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = $this->close();
        app(OpenInvestmentPeriod::class)(actorId: null);
        $newcomer = $this->subscribe('20000.00');

        Carbon::setTestNow('2026-11-02 09:00:00');
        $this->close();
        app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-11-05 09:00:00');

        // Act — فاتورةُ الشحن تصل في نوفمبر، والداخلُ الجديد شريكٌ فيه.
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — بيعُ سبتمبر على سبتمبر: المؤسّسُ وحده يحمل نصيبَ الشركاء منه.
        $charge = $this->liveConsumerCharges($expense)->sole();
        $this->assertSame((int) $september->id, (int) $charge->investment_period_id);
        $this->assertSame('300.00', $this->chargedTo($founder));
        $this->assertSame('0.00', $this->chargedTo($newcomer));
    }

    public function test_a_sale_whose_period_has_closed_hands_its_share_to_the_open_one(): void
    {
        // Arrange — سبتمبر أُقفل وأُعلنت أرقامُه.
        $headers = $this->manager();
        $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close('إقفالٌ مبكّر للاختبار');
        $october = app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-10-05 09:00:00');

        // Act
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — كأيّ تصحيحٍ لفترةٍ أُقفلت: يقع على المفتوحة.
        $this->assertSame((int) $october->id, (int) $this->liveConsumerCharges($expense)->sole()->investment_period_id);
    }

    public function test_when_everything_was_sold_it_is_all_charged_to_the_sales(): void
    {
        // Arrange
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '200', $warehouse);
        $this->sell($size, '300', $warehouse);

        // Act
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — 400 و600 بكمياتهما، ولا شيء على رفٍّ فارغ.
        $charges = $this->liveConsumerCharges($expense)->pluck('amount')->map(fn ($a) => (string) $a)->sort()->values()->all();
        $this->assertSame(['400.00', '600.00'], $charges);
        $this->assertSame('500.00', $this->chargedTo($founder));
    }

    public function test_two_fund_lines_share_it_by_value_and_a_company_line_takes_none(): void
    {
        // Arrange — ورقٌ بـ2,500 وحبرٌ بـ5,000 للصندوق، وكرتونٌ للشركة في الطلب نفسه.
        $headers = $this->manager();
        $this->founder();
        $warehouse = Warehouse::factory()->create();
        $paper = $this->bagSize();
        $ink = $this->bagSize();
        $carton = $this->bagSize();
        $lines = [
            [$paper, '100.000', '25.000'],
            [$ink, '100.000', '50.000'],
            [$carton, '100.000', '25.000'],
        ];
        $order = $this->purchaseOrder($warehouse, $lines);
        $this->receive($headers, $order, [$paper, $ink], $lines);

        // Act
        $this->expenseOn($headers, $order, '750.00');

        // Assert — 250 على الورق (2.500 للكيلو) و500 على الحبر (5.000)، والكرتونُ كما كان.
        $this->assertSame('27.500', $this->unitCostOf($paper));
        $this->assertSame('55.000', $this->unitCostOf($ink));
        $this->assertSame('25.000', $this->unitCostOf($carton));
    }

    public function test_goods_moved_to_another_warehouse_carry_their_share_and_the_move_is_no_sale(): void
    {
        // Arrange — 200 كغ نُقلت إلى المخزن الثاني قبل الفاتورة.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $second = Warehouse::factory()->create();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/transfers', [
            'stock_item_id' => $size->stock_item_id,
            'from_warehouse_id' => $warehouse->id,
            'to_warehouse_id' => $second->id,
            'quantity' => '200',
        ])->assertCreated();

        // Act
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Assert — الطبقتان ارتفعتا، ولا أحد حُمِّل شيئاً.
        $costs = StockBatch::query()
            ->where('stock_item_id', $size->stock_item_id)
            ->where('quantity_remaining', '>', 0)
            ->pluck('unit_cost')
            ->map(fn ($c) => (string) $c)
            ->unique()
            ->values()
            ->all();

        $this->assertSame(['27.000'], $costs);
        $this->assertCount(0, $this->liveConsumerCharges($expense));
        $this->assertSame('0.00', $this->chargedTo($founder));
    }

    // ─────────────────────────── after the landing ───────────────────────────

    public function test_an_order_cancelled_after_the_expense_gives_back_its_share_and_its_bags_carry_it(): void
    {
        // Arrange — الطلبيةُ حُمِّلت 600 ثم أُلغيت فرجعت أكياسُها إلى الرفّ.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $sale = $this->sell($size, '300', $warehouse);
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Act
        $this->cancel($sale);

        // Assert — حصتُها رُدّت، والـ500 كلُّها على الرفّ بتكلفةٍ تحمل المصروفَ كلَّه.
        $this->assertCount(0, $this->liveConsumerCharges($expense));
        $this->assertSame('0.00', $this->chargedTo($founder));
        $this->assertSame('13500.00', app(FundValuation::class)()['stock_on_shelf']);
    }

    public function test_bags_the_press_bought_stay_charged_when_their_order_is_cancelled(): void
    {
        // Arrange — رفٌّ مسعَّر: المطبعةُ اشترت الـ300 عند الباب، والإلغاءُ لا يعيدها إلى الصندوق.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers, printingSalePrice: '32.000');
        $sale = $this->sell($size, '300', $warehouse);
        $expense = $this->expenseOn($headers, $order, '1000.00');

        // Act
        $this->cancel($sale);

        // Assert — البيعُ قائم، فحصتُه قائمة.
        $this->assertSame('600.00', (string) $this->liveConsumerCharges($expense)->sole()->amount);
        $this->assertSame('300.00', $this->chargedTo($founder));
    }

    public function test_a_line_redrawn_after_the_expense_moves_its_share_into_the_cost(): void
    {
        // Arrange — طلبيةٌ أخذت 300 ثم عُدِّل سطرُها إلى 200.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $sale = $this->sell($size, '300', $warehouse);
        $expense = $this->expenseOn($headers, $order, '1000.00');
        $line = $sale->items()->firstOrFail();

        // Act
        app(RedrawOrderLineStock::class)($sale->refresh(), $line, '200', (int) User::factory()->create()->id);

        // Assert — الحصةُ رُدّت، والسحبُ الجديد بالتكلفة التي فيها المصروف: 200 × 27 = 5,400.
        $this->assertCount(0, $this->liveConsumerCharges($expense));
        $this->assertSame('0.00', $this->chargedTo($founder));
        $this->assertSame('5400.00', (string) StockBatchConsumption::query()
            ->where('stock_movement_id', $line->refresh()->fulfillment_stock_movement_id)
            ->sum('total_cost'));
    }

    // ─────────────────────────── reversing ───────────────────────────

    public function test_reversing_the_expense_undoes_both_halves_and_pays_back_what_sold_at_the_new_cost(): void
    {
        // Arrange — 300 كغ قبل الفاتورة، و100 بعدها بتكلفةٍ فيها المصروف.
        $headers = $this->manager();
        $founder = $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);
        $expense = $this->expenseOn($headers, $order, '1000.00');
        $this->sell($size, '100', $warehouse);

        // Act
        $this->reverse($headers, $expense)->assertCreated();

        // Assert — التكلفةُ عادت، وحصةُ الـ300 رُدّت، والـ100 يُردّ إليها ما حملته: 200، نصفُه للشركاء.
        $this->assertSame('25.000', $this->unitCostOf($size));
        $this->assertSame('-100.00', $this->chargedTo($founder));

        // والنقدُ: المصروفُ عاد كلُّه، وغطاءُ الشركة لحصة الـ300 عُكس، ونصيبُها من الـ200 خرج إليها.
        $value = app(FundValuation::class)();
        $this->assertSame('100.00', (string) InvestmentCashEntry::query()
            ->where('type', CashEntryType::CompanyPayout->value)
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount'));
        $this->assertSame('2500.00', $value['stock_on_shelf']);
    }

    public function test_reversing_is_refused_once_a_charge_sits_in_a_closed_period(): void
    {
        // Arrange — حصةُ البيع على سبتمبر، وسبتمبر أُقفل بعدها.
        $headers = $this->manager();
        $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);
        $expense = $this->expenseOn($headers, $order, '1000.00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close('إقفالٌ مبكّر للاختبار');
        app(OpenInvestmentPeriod::class)(actorId: null);

        // Act
        $response = $this->reverse($headers, $expense);

        // Assert
        $response->assertStatus(422);
        $this->assertSame('27.000', $this->unitCostOf($size));
    }

    public function test_reversing_the_receipt_takes_the_expense_with_it(): void
    {
        // Arrange — القرار ٨: التراجعُ عن الاستلام يعكس المصروفَ المربوطَ به، لا يُرفض.
        $headers = $this->manager();
        $this->founder();
        [, , $order] = $this->shipment($headers);
        $expense = $this->expenseOn($headers, $order, '1000.00');
        $cashBefore = app(FundValuation::class)()['cash'];

        // Act
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/receipt-reversal",
            ['reason' => 'استلامٌ بالخطأ'],
        )->assertOk();

        // Assert — المصروفُ معكوس، ومالُه عاد إلى نقد الصندوق.
        $this->assertTrue($expense->refresh()->isReversed());
        $this->assertSame(bcadd($cashBefore, '1000.00', 2), app(FundValuation::class)()['cash']);
    }

    // ─────────────────────────── the receipt itself ───────────────────────────

    public function test_an_arrival_cost_on_a_fund_line_goes_into_the_goods(): void
    {
        // Arrange — القرار ٥: تكاليفُ الوصول على بند الصندوق تدخل التكلفةَ كما على بند الشركة.
        $headers = $this->manager();
        $founder = $this->founder();
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $order = $this->purchaseOrder($warehouse, [[$size, '500.000', '25.000']]);
        $drawer = app(TreasuryService::class)->accountFor('cash', null, incoming: false);

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            ['stock_item_ids' => [$size->stock_item_id]],
        )->assertOk();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/purchase-orders/{$order->id}/arrivals", [
            'items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '500.000']],
            'additional_costs' => [['name' => 'نقل', 'amount' => '500', 'treasury_account_id' => $drawer->id]],
        ])->assertCreated();

        // Assert — 500 على 500 كغ = 1.000 للكيلو، ولا شيء على أحد.
        $this->assertSame('26.000', $this->unitCostOf($size));
        $this->assertSame('0.00', $this->chargedTo($founder));
        $this->assertSame((int) $order->id, (int) InvestorDealExpense::query()->sole()->purchase_order_id);
    }

    // ─────────────────────────── the figures ───────────────────────────

    public function test_a_period_counts_only_its_share_of_the_sales_and_both_screens_agree(): void
    {
        // Arrange — 600 على مبيعات سبتمبر، و400 على الرفّ.
        $headers = $this->manager();
        $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);
        $this->expenseOn($headers, $order, '1000.00');
        $september = InvestmentPeriod::query()->orderBy('starts_on')->firstOrFail();

        // Act
        $periodScreen = app(PeriodExpensesQuery::class)($september);
        $filtered = app(FundExpensesQuery::class)->page($september);
        $all = app(FundExpensesQuery::class)->page(null);

        // Assert — حصةُ الرفّ ليست مصروفَ فترة؛ تظهر في تكلفة البضاعة يومَ تُباع.
        $this->assertSame('600.00', $periodScreen['totals']['expenses_total']);
        $this->assertSame('600.00', $filtered['expenses_total']);
        $this->assertSame('1000.00', $all['expenses_total']);
        $this->assertSame('600.00', $periodScreen['expenses'][0]['amount']);
        $this->assertSame((int) $order->id, $periodScreen['expenses'][0]['purchase_order']['id']);
    }

    public function test_the_list_says_how_much_the_goods_cost_before_and_after(): void
    {
        // Arrange — طلبُ المالك: «توضيح تغيير تكلفة بضاعة من كم لكم بناء على مصروف».
        $headers = $this->manager();
        $this->founder();
        [$size, , $order] = $this->shipment($headers);
        $this->expenseOn($headers, $order, '1000.00');

        // Act
        $row = app(FundExpensesQuery::class)->page(null)['rows'][0];

        // Assert — 25.000 كانت، و27.000 صارت، على 500 كيلو كانت على الرفّ.
        $this->assertCount(1, $row['goods']);
        $this->assertSame((int) $size->stock_item_id, $row['goods'][0]['stock_item_id']);
        $this->assertSame('25.000', $row['goods'][0]['cost_before']);
        $this->assertSame('27.000', $row['goods'][0]['cost_after']);
        $this->assertSame('500.000', $row['goods'][0]['quantity']);
        $this->assertSame('كجم', $row['goods'][0]['unit_label']);
    }

    public function test_the_pennies_always_add_up(): void
    {
        // Arrange — 100 على 3 كغ لا تنقسم، وكيلو منها بِيع.
        $headers = $this->manager();
        $this->founder();
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $lines = [[$size, '3.000', '25.000']];
        $order = $this->purchaseOrder($warehouse, $lines);
        $this->receive($headers, $order, [$size], $lines);
        $this->sell($size, '1', $warehouse);

        // Act
        $expense = $this->expenseOn($headers, $order, '100.00');

        // Assert — ما على الرفّ وما على المبيعات يساويان المصروفَ بقرشه.
        $total = (string) FundExpenseCharge::query()
            ->where('investor_deal_expense_id', $expense->id)
            ->sum('amount');

        $this->assertSame('100.00', number_format((float) $total, 2, '.', ''));
        $this->assertSame('58.333', $this->unitCostOf($size));
    }

    // ─────────────────────────── refusals ───────────────────────────

    public function test_a_purchase_order_that_brought_the_fund_nothing_is_refused(): void
    {
        // Arrange — طلبٌ للشركة وحدها.
        $headers = $this->manager();
        $this->founder();
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $lines = [[$size, '100.000', '25.000']];
        $order = $this->purchaseOrder($warehouse, $lines);
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '100.000']]],
        )->assertCreated();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => 'شحن',
            'amount' => '100',
            'incurred_on' => now()->toDateString(),
            'purchase_order_id' => $order->id,
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['purchase_order_id']);
        $this->assertSame(0, InvestorDealExpense::query()->count());
    }

    public function test_each_charge_has_its_own_history(): void
    {
        // Arrange — قاعدةُ كل نموذج: سجلٌّ يُقرأ من مسارٍ باسمه.
        $headers = $this->manager();
        $this->founder();
        [$size, $warehouse, $order] = $this->shipment($headers);
        $this->sell($size, '300', $warehouse);
        $charge = $this->liveConsumerCharges($this->expenseOn($headers, $order, '1000.00'))->sole();
        $auditor = User::factory()->create();
        $auditor->givePermissionTo(PermissionName::ViewActivityLogs->value);
        $this->app['auth']->forgetGuards();

        // Act
        $response = $this->withHeaders(['Authorization' => 'Bearer '.$auditor->createToken('test')->plainTextToken])
            ->getJson("/api/v1/investment/expense-charges/{$charge->id}/logs");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.event', 'created')
            ->assertJsonPath('data.0.subject_type', 'fund_expense_charge');
    }

    public function test_the_picker_lists_the_purchase_orders_that_brought_the_fund_goods(): void
    {
        // Arrange — طلبٌ للصندوق وآخرُ للشركة.
        $headers = $this->manager();
        $this->founder();
        [, , $fundOrder] = $this->shipment($headers);
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $companyOrder = $this->purchaseOrder($warehouse, [[$size, '100.000', '25.000']]);
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$companyOrder->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '100.000']]],
        )->assertCreated();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/purchase-orders');

        // Assert
        $response->assertOk();
        $this->assertSame([(int) $fundOrder->id], array_map('intval', array_column($response->json('data'), 'id')));
    }
}
