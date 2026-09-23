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
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\FoldDealIntoFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\DealCannotFoldIntoFund;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\DealStockPosition;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Support\FundDeal;
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
 * تحويلُ صفقةٍ قديمة إلى الصندوق — عبدالرحمن أوّلُ شركاء الفترة الأولى.
 *
 * المواصفة: §٠.٩ و§س١٣ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}. «نخلي اول فترة
 * صاحبها عبدالرحمن مباشرة وهكذا مع بضاعته هذي»، والتوصياتُ الخمس كلُّها.
 *
 * صفقةٌ على صورة D1 بأرقامٍ تُحسب على الورق:
 *
 * ```
 * أمرُ شراء      500 كغ × 25.000 = 12,500 — الشريكُ 11,000 (88٪) والشركةُ 1,500 (12٪)
 * سعرُ السادة    32.000 — المطبعةُ تشتري عند «جاهزة للطباعة»، والهامشُ 7 للكيلو
 * طلبيةٌ أ       100 كغ وصلت          ← ربحُه 100 × 7 × 88٪ × 50٪ = 308
 * طلبيةٌ ب        50 كغ عند المطبعة     ← ربحُه  50 × 7 × 88٪ × 50٪ = 154، ولم تبلغ «جاهزة»
 * على الرفّ      350 كغ × 25 = 8,750
 * ```
 *
 * ```
 * يبقى في D1 لطلبيةٍ في الطريق     88٪ × 1,250           = 1,100
 * يدخل الصندوق                      11,000 − 1,100         = 9,900  ← 9,900 وحدة بسعر 1
 *   بضاعة                                                  8,750
 *   نقدٌ من الشركة باسمه             9,900 − 8,750          = 1,150
 *     = نصيبُه المحقَّق 88٪ × 2,500 − حصةُ الشركة من الرفّ 12٪ × 8,750
 * ربحُ D1 إلى محفظته، ونقدُه في الخزينة                     462
 * ```
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FoldDealIntoFundTest extends TestCase
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

    // ─────────────────────────── the legacy deal ───────────────────────────

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
     * D1 على الورق: 500 كغ بـ25، الشريكُ 11,000 منها، وسعرُ السادة 32.
     *
     * @return array{0: InvestorDeal, 1: Investor, 2: ProductVariant, 3: Warehouse}
     */
    private function legacyDeal(array $headers, string $partnerAmount = '11000.00'): array
    {
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();

        $order = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        PurchaseOrderItem::factory()->forOrder($order)->create([
            'stock_item_id' => $size->stock_item_id,
            'quantity_ordered' => '500.000',
            'base_total_cost' => '12500.00',
            'base_unit_cost' => '25.000',
            'allocated_additional_cost' => '0.00',
            'final_unit_cost' => '25.000',
            'final_total_cost' => '12500.00',
        ]);

        $partner = Investor::factory()->create();

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $partner->getKey(),
                type: WalletEntryType::Deposit,
                amount: $partnerAmount,
                method: 'cash',
            ),
            null,
        );

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/investor-funding",
            [
                'investor_profit_share_percent' => 50,
                'printing_sale_price' => '32.000',
                'investors' => [['investor_id' => $partner->getKey(), 'amount' => $partnerAmount]],
            ],
        )->assertCreated();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '500.000']]],
        )->assertCreated();

        return [
            InvestorDeal::query()->where('purchase_order_id', $order->id)->firstOrFail(),
            $partner,
            $size,
            $warehouse,
        ];
    }

    private function sale(ProductVariant $size, string $kilos): Order
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
            'quantity' => $kilos,
            'unit_price' => '60.000',
            'line_total' => bcmul($kilos, '60.000', 2),
            'pricing_unit' => PricingUnit::Kilogram,
        ]);

        app(RecalculateOrderTotals::class)($order->refresh());
        app(ResolveOrderFlow::class)($order->refresh());

        return $order->refresh();
    }

    /** @param array<string, mixed> $fields */
    private function move(array $headers, Order $order, OrderStatus $to, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            array_filter(['status' => $to->value, 'fields' => $fields ?: null]),
        );
    }

    /** المطبعةُ تشتري السادةَ هنا — والطلبيةُ «في الطريق» إلى أن تبلغ «جاهزة». */
    private function toThePress(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->move($headers, $order, OrderStatus::ReadyToPrint, ['warehouse_id' => $warehouse->getKey()])->assertOk();
    }

    private function toReady(array $headers, Order $order): void
    {
        $this->move($headers, $order->refresh(), OrderStatus::Printing)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Ready)->assertOk();
    }

    private function deliver(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->toThePress($headers, $order, $warehouse);
        $this->toReady($headers, $order);

        $this->move($headers, $order->refresh(), OrderStatus::OutForDelivery, [
            'shipping_company_id' => ShippingCompany::factory()->create()->getKey(),
        ])->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Delivered)->assertOk();
    }

    /**
     * D1 كاملةً قبل الصندوق بأسبوعين، ثم الفترةُ الأولى تُفتح يوم رفع الميزة.
     *
     * @return array{0: InvestorDeal, 1: Investor, 2: Warehouse, 3: ProductVariant, 4: Order}
     */
    private function d1BeforeTheFund(): array
    {
        Carbon::setTestNow('2026-09-05 09:00:00');
        $headers = $this->manager();
        [$deal, $partner, $size, $warehouse] = $this->legacyDeal($headers);

        $this->deliver($headers, $this->sale($size, '100'), $warehouse);

        $onTheRoad = $this->sale($size, '50');
        $this->toThePress($headers, $onTheRoad, $warehouse);

        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);

        Carbon::setTestNow('2026-09-24 10:00:00');

        return [$deal->refresh(), $partner, $warehouse, $size, $onTheRoad];
    }

    /** التحويلُ قرارُ إنسانٍ يُكتب باسمه — وحركتا المخزن تطلبان يداً. */
    private function fold(InvestorDeal $deal): array
    {
        return app(FoldDealIntoFund::class)($deal, actorId: (int) User::factory()->create()->getKey());
    }

    // ─────────────────────────── the goods ───────────────────────────

    public function test_the_shelf_moves_into_the_fund_at_its_cost_its_age_and_its_press_price(): void
    {
        // Arrange
        [$deal, , $warehouse, $size] = $this->d1BeforeTheFund();
        $original = StockBatch::query()->where('investor_deal_id', $deal->id)->firstOrFail();

        // Act
        $this->fold($deal);

        // Assert — 350 كغ بتكلفة 25 وسعرِ سادة 32 وتاريخِ استلامها، للصندوق لا لـD1.
        $fundId = app(FundDeal::class)()->getKey();
        $moved = StockBatch::query()->where('investor_deal_id', $fundId)->get();

        $this->assertSame('350.000', number_format((float) $moved->sum('quantity_remaining'), 3, '.', ''));
        $this->assertSame(['25.000'], $moved->pluck('unit_cost')->map(fn ($c) => (string) $c)->unique()->values()->all());
        $this->assertSame(['32.000'], $moved->pluck('printing_sale_price')->map(fn ($p) => (string) $p)->unique()->values()->all());
        $this->assertSame(
            $original->received_at->toDateTimeString(),
            $moved->first()->received_at->toDateTimeString(),
        );
        $this->assertSame('0.000', number_format((float) StockBatch::query()->where('investor_deal_id', $deal->id)->sum('quantity_remaining'), 3, '.', ''));

        // والرفُّ نفسُه لم يتحرّك: الملكيةُ تغيّرت، لا الكمية.
        $balance = WarehouseStock::query()
            ->where('warehouse_id', $warehouse->id)
            ->where('stock_item_id', $size->stock_item_id)
            ->value('quantity');
        $this->assertSame('350.000', (string) $balance);
    }

    public function test_the_movement_ledger_nets_to_nothing_on_the_shelf(): void
    {
        // Arrange — «الرصيد = الدفتر»: حركتان متقابلتان، خروجٌ من D1 ودخولٌ للصندوق.
        [$deal, , $warehouse] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert
        $moves = StockMovement::query()->where('movement_type', 'ownership_transfer')->get();

        $this->assertCount(2, $moves);
        $this->assertSame(1, $moves->where('from_warehouse_id', $warehouse->id)->count());
        $this->assertSame(1, $moves->where('to_warehouse_id', $warehouse->id)->count());
        $this->assertSame(['350.000'], $moves->pluck('quantity')->map(fn ($q) => (string) $q)->unique()->values()->all());
    }

    public function test_the_deal_screen_counts_the_handed_over_stock_as_transferred(): void
    {
        // Arrange — بلا بندٍ لها يصير «وصل» 150 بدل 500: ما انتقل ليس مبيعاً ولا تالفاً.
        [$deal] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);
        $position = app(DealStockPosition::class)((int) $deal->id);

        // Assert
        $this->assertSame('500.000', $position['quantity_received']);
        $this->assertSame('150.000', $position['quantity_sold']);
        $this->assertSame('350.000', $position['quantity_transferred']);
        $this->assertSame('0.000', $position['quantity_remaining']);
    }

    // ─────────────────────────── the partner ───────────────────────────

    public function test_he_enters_the_first_period_with_all_his_capital_not_riding_an_order(): void
    {
        // Arrange
        [$deal, $partner] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert — 9,900 وحدة بسعر 1، وهو وحده في الفترة الأولى.
        $units = InvestmentUnit::query()->where('investor_id', $partner->id)->firstOrFail();
        $this->assertSame('9900.000000', (string) $units->units);
        $this->assertSame('1.000000', (string) $units->unit_price);

        $shares = app(PeriodShares::class)->current();
        $this->assertSame('100.000000', $shares[(int) $partner->id] ?? null);

        $pots = app(InvestorBalances::class)->forInvestor((int) $partner->id);
        $fundId = (int) app(FundDeal::class)()->getKey();
        $this->assertSame('9900.00', $pots['deals'][$fundId]['capital']);
        $this->assertSame('1100.00', $pots['deals'][(int) $deal->id]['capital']);
        $this->assertSame('0.00', $pots['wallet']['capital']);
    }

    public function test_who_subscribes_after_the_fold_waits_for_the_next_period(): void
    {
        // Arrange — قرارُ المالك 2026-09-23: «اريد عبدالرحمن فقط شريك هذه الفترة وينضمون للفترة
        // التي تليها». الصفقةُ القديمة تؤسّس الصندوق، ومن اكتتب بعدها في النافذة ينتظر.
        [$deal, $partner] = $this->d1BeforeTheFund();
        $this->fold($deal);

        Carbon::setTestNow('2026-09-24 12:00:00');
        $newcomer = Investor::factory()->create();
        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $newcomer->getKey(),
                type: WalletEntryType::Deposit,
                amount: '9900.00',
                method: 'cash',
            ),
            null,
        );
        app(DepositToFund::class)(investorId: (int) $newcomer->getKey(), amount: '9900.00', actorId: null);

        // Act
        $now = app(PeriodShares::class)->current();
        $next = app(PeriodShares::class)->upcoming();

        // Assert — هو وحده في هذه الفترة، والوافدُ نصيبُه من التالية بوحداته.
        $this->assertSame([(int) $partner->id => '100.000000'], $now);
        $this->assertArrayHasKey((int) $partner->id, $next);
        $this->assertArrayHasKey((int) $newcomer->id, $next);
        $this->assertSame('100.000000', bcadd($next[(int) $partner->id], $next[(int) $newcomer->id], 6));
    }

    public function test_the_company_share_of_the_shelf_is_bought_from_his_realised_cash(): void
    {
        // Arrange — §١٣أ: «صاحبها عبدالرحمن مباشرة». الشركةُ تستردّ 1,050، ويدخل الباقي 1,150.
        [$deal] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert — والصندوقُ يساوي وحداتِه بالضبط: 8,750 بضاعةً + 1,150 نقداً.
        $capitalCash = InvestmentCashEntry::query()
            ->where('type', CashEntryType::LegacyTransfer->value)
            ->where('source_id', InvestorWalletEntry::query()->where('type', WalletEntryType::Allocation->value)->value('id'))
            ->sum('amount');
        $this->assertSame('1150.00', number_format((float) $capitalCash, 2, '.', ''));

        $value = app(FundValuation::class)((int) app(FundDeal::class)()->getKey());
        $this->assertSame('9900.00', $value['total']);
    }

    public function test_his_d1_profit_reaches_his_wallet_with_its_cash_behind_it(): void
    {
        // Arrange — §١٣ج: صُنع بقواعد D1 وD1 تنتهي. والسحبُ يخرج من خزينة الصندوق، فنقدُه يدخلها.
        [$deal, $partner] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert
        $pots = app(InvestorBalances::class)->forInvestor((int) $partner->id);
        $this->assertSame('462.00', $pots['wallet']['profit']);
        $this->assertSame('0.00', $pots['deals'][(int) $deal->id]['profit']);

        $release = InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->id)
            ->where('type', WalletEntryType::ProfitRelease->value)
            ->firstOrFail();
        $backing = InvestmentCashEntry::query()
            ->where('type', CashEntryType::LegacyTransfer->value)
            ->where('source_id', $release->id)
            ->value('amount');
        $this->assertSame('462.00', (string) $backing);
    }

    public function test_his_units_are_locked_a_year_from_the_fold(): void
    {
        // Arrange — §١٣هـ: من يوم التحويل، كأيّ دفعةٍ تدخل الصندوق.
        [$deal, $partner] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert
        $units = InvestmentUnit::query()->where('investor_id', $partner->id)->firstOrFail();
        $this->assertSame('2027-09-24', $units->locked_until->toDateString());
    }

    // ─────────────────────────── what stays behind ───────────────────────────

    public function test_the_order_on_the_road_stays_with_the_deal_and_the_deal_stays_open(): void
    {
        // Arrange — §١٣د: طلبيةٌ بدأت قبل الصندوق تكمل بعقدها.
        [$deal] = $this->d1BeforeTheFund();

        // Act
        $this->fold($deal);

        // Assert
        $deal->refresh();
        $this->assertSame(DealStatus::Open, $deal->status);
        $this->assertNotNull($deal->folded_into_fund_at);
    }

    public function test_the_deal_closes_itself_once_its_last_order_is_through(): void
    {
        // Arrange — الطلبيةُ تبلغ «جاهزة»، فلا يبقى لـD1 ما تنتظره.
        [$deal, $partner, , , $onTheRoad] = $this->d1BeforeTheFund();
        $this->fold($deal);
        $this->toReady($this->manager(), $onTheRoad);

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — رأسُ مالها الأخير 1,100 في محفظته حرّاً.
        $this->assertSame(DealStatus::Closed, $deal->refresh()->status);
        $pots = app(InvestorBalances::class)->forInvestor((int) $partner->id);
        $this->assertSame('1100.00', $pots['wallet']['capital']);
    }

    // ─────────────────────────── the fund period does not touch it ───────────────────────────

    public function test_closing_the_first_period_leaves_a_folded_deal_alone(): void
    {
        // Arrange — صفُّ الإفراج الذي كتبه التحويلُ لا يعني «ربحُ هذه الفترة دُفع». لو قرأه
        // إقفالُ الفترة كذلك لرحّل على الرجل خسارةً وهميةً بـ462، ولأفرج عن ربح D1 مرّةً ثانية.
        [$deal, $partner] = $this->d1BeforeTheFund();
        $this->fold($deal);

        // Act
        Carbon::setTestNow('2026-10-01 03:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null);

        // Assert
        $this->assertSame(0, InvestorWalletEntry::query()
            ->whereIn('type', [WalletEntryType::LossCarriedOut->value, WalletEntryType::LossCarriedIn->value])
            ->count());
        $this->assertSame(1, InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->id)
            ->where('type', WalletEntryType::ProfitRelease->value)
            ->count());
        $this->assertSame('462.00', app(InvestorBalances::class)->forInvestor((int) $partner->id)['wallet']['profit']);
    }

    // ─────────────────────────── refusals ───────────────────────────

    public function test_it_refuses_the_fund_itself(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $fund = app(FundDeal::class)();

        // Assert
        $this->expectException(DealCannotFoldIntoFund::class);

        // Act
        $this->fold($fund);
    }

    public function test_it_refuses_when_his_free_cash_cannot_buy_the_company_share(): void
    {
        // Arrange — لم يُبَع شيء: رأسُ ماله 11,000 كلُّه بضاعة، وحصةُ الشركة 1,500 لا نقدَ يشتريها.
        Carbon::setTestNow('2026-09-05 09:00:00');
        [$deal] = $this->legacyDeal($this->manager());
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);

        // Assert
        $this->expectException(DealCannotFoldIntoFund::class);

        // Act
        $this->fold($deal->refresh());
    }

    public function test_a_dry_run_says_the_figures_and_writes_nothing(): void
    {
        // Arrange
        [$deal] = $this->d1BeforeTheFund();

        // Act — سطرٌ لكل رقم: الرفُّ بتكلفته، ثم الشريكُ بوحداته.
        $this->artisan('investment:fold-deal', ['deal' => $deal->code, '--dry-run' => true])
            ->expectsOutputToContain('بتكلفة 8750.00')
            ->expectsOutputToContain('9900.000000 وحدة')
            ->assertSuccessful();

        // Assert
        $this->assertSame(0, InvestmentUnit::query()->count());
        $this->assertNull($deal->refresh()->folded_into_fund_at);
    }
}
