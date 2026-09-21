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
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundValuation;
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
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * سعرُ السادة في الصندوق المستمرّ — سعرٌ لكل مادة، وثمنٌ يعود إلى الخزينة.
 *
 * ما كان يمنع هذا الطريقَ عن الصندوق شيئان، وهذا الملفُّ يحرسهما معاً:
 *
 * 1. **السعرُ كان على الصفقة**، والصندوقُ صفقةٌ واحدةٌ أبداً — فسعرٌ عليه سعرٌ واحدٌ لكل مادةٍ
 *    يملكها ما دام. فنزل السعرُ إلى صفّ التوريد: لكل رفٍّ في كل أمر شراءٍ سعرُه.
 * 2. **والثمنُ لم يكن يعود.** البضاعةُ تغادر الرفّ فتسقط من القيمة، والمستثمرُ يُقيَّد له
 *    الهامشُ وحدَه — ورأسُ المال الذي اشتراها لا يدخل من أيّ باب. فصار للمطبعة صفٌّ في الخزينة.
 *
 * ```
 * إيداع        20,000.00 نقداً في الصندوق
 * أمر شراء     500 كغ بتكلفة 25.000  =  12,500.00
 * سعر السادة   32.000 للكيلو — على السطر لا على الصندوق
 * طلبيةُ طباعة 300 كغ
 * ```
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PressBuysFundStockTest extends TestCase
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
        ]);

        // The guard caches the first user a test resolves; a second person in the same test
        // would otherwise be authorised as the first.
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
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::MoveOrderToReady->value,
            PermissionName::DispatchOrders->value,
            PermissionName::MarkOrdersDelivered->value,
            PermissionName::CancelOrders->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    // ─────────────────────────── the fund ───────────────────────────

    /** مالٌ على الطاولة أولاً، ثم اشتراكٌ به في الصندوق — حدثان في يومين. */
    private function fundHolding(string $amount): Investor
    {
        app(OpenInvestmentPeriod::class)(actorId: null);

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

    /** 500 كغ بتكلفة 25.000 — سطرٌ واحد، رفٌّ واحد. */
    private function purchaseOrder(ProductVariant $size, Warehouse $warehouse): PurchaseOrder
    {
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

        return $order->refresh();
    }

    /**
     * الصندوقُ يشتري اللوري — بسعر سادةٍ على السطر أو بلا سعر.
     *
     * @return array{0: ProductVariant, 1: Warehouse, 2: PurchaseOrder}
     */
    private function shipment(array $headers, ?string $printingSalePrice = '32.000'): array
    {
        $warehouse = Warehouse::factory()->create();
        $size = $this->bagSize();
        $order = $this->purchaseOrder($size, $warehouse);

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            array_filter([
                'stock_item_ids' => [$size->stock_item_id],
                'printing_sale_prices' => $printingSalePrice === null
                    ? null
                    : [$size->stock_item_id => $printingSalePrice],
            ]),
        )->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => '500.000']]],
        )->assertCreated();

        return [$size, $warehouse, $order];
    }

    /** طلبيةُ طباعةٍ لـ`$kilos` كيلو بسعر `$unitPrice` — بلا إضافاتٍ تُعكّر الأرقام. */
    private function sale(ProductVariant $size, string $kilos, string $unitPrice): Order
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
            'unit_price' => $unitPrice,
            'line_total' => bcmul($kilos, $unitPrice, 2),
            'pricing_unit' => PricingUnit::Kilogram,
        ]);

        app(RecalculateOrderTotals::class)($order->refresh());
        app(ResolveOrderFlow::class)($order->refresh());

        return $order->refresh();
    }

    /** الحركةُ التي تُخرج البضاعة من الرفّ إلى المطبعة. */
    private function toThePress(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->getKey()],
        ])->assertOk();
    }

    /** الطريقُ كلُّه إلى باب العميل — تُقفَل الفترةُ على طلبيةٍ وصلت، لا على واحدةٍ في الطريق. */
    private function deliver(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->toThePress($headers, $order, $warehouse);

        foreach ([OrderStatus::Printing, OrderStatus::Ready] as $status) {
            $this->withHeaders($headers)->postJson(
                "/api/v1/orders/{$order->id}/status",
                ['status' => $status->value],
            )->assertOk();
        }

        $carrier = ShippingCompany::factory()->create();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::OutForDelivery->value,
            'fields' => ['shipping_company_id' => $carrier->getKey()],
        ])->assertOk();

        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            ['status' => OrderStatus::Delivered->value],
        )->assertOk();
    }

    /** إلى «جاهزة» فقط — بعدها تحمل البضاعةُ شعارَ زبونها ولا تعود إلى رفٍّ يُباع منه. */
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

    private function cancel(array $headers, Order $order): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'تراجع الزبون بعد الطباعة',
        ])->assertOk();
    }

    private function pressPaid(): string
    {
        return (string) InvestmentCashEntry::query()
            ->where('type', CashEntryType::StockSoldToPress->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');
    }

    // ─────────────────────────── the price ───────────────────────────

    public function test_the_price_is_frozen_on_the_line_not_on_the_fund(): void
    {
        // Arrange — الصندوقُ صفقةٌ واحدةٌ أبداً، فسعرٌ عليه سعرٌ لكل مادةٍ يملكها ما دام.
        $headers = $this->manager();
        $this->fundHolding('20000.00');

        // Act
        [$size, , $purchaseOrder] = $this->shipment($headers);

        // Assert — السطرُ يحمله، والصندوقُ لا يحمل شيئاً.
        $supply = InvestorDealSupply::query()
            ->where('source_id', $purchaseOrder->id)
            ->where('stock_item_id', $size->stock_item_id)
            ->firstOrFail();

        $this->assertSame('32.000', (string) $supply->printing_sale_price);
        $this->assertNull(app(FundDeal::class)()->printing_sale_price);

        // وطبقةُ التكلفة تُختم به عند الاستلام، فلا يُقرأ حيّاً بعد اليوم.
        $batch = StockBatch::query()->where('stock_item_id', $size->stock_item_id)->firstOrFail();
        $this->assertSame('32.000', (string) $batch->printing_sale_price);
    }

    public function test_two_shelves_may_carry_two_different_prices(): void
    {
        // Arrange — الورقُ والحبرُ لا يُباعان بالرقم نفسه، وهو ما لم يكن عمودُ الصفقة يسعه.
        $headers = $this->manager();
        $this->fundHolding('40000.00');

        $warehouse = Warehouse::factory()->create();
        $paper = $this->bagSize();
        $ink = $this->bagSize();

        $order = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        foreach ([$paper, $ink] as $size) {
            PurchaseOrderItem::factory()->forOrder($order)->create([
                'stock_item_id' => $size->stock_item_id,
                'quantity_ordered' => '100.000',
                'base_total_cost' => '2500.00',
                'base_unit_cost' => '25.000',
                'allocated_additional_cost' => '0.00',
                'final_unit_cost' => '25.000',
                'final_total_cost' => '2500.00',
            ]);
        }

        // Act
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            [
                'stock_item_ids' => [$paper->stock_item_id, $ink->stock_item_id],
                'printing_sale_prices' => [
                    $paper->stock_item_id => '32.000',
                    $ink->stock_item_id => '41.500',
                ],
            ],
        )->assertOk();

        // Assert
        $prices = InvestorDealSupply::query()
            ->where('source_id', $order->id)
            ->pluck('printing_sale_price', 'stock_item_id')
            ->map(fn ($price) => (string) $price)
            ->all();

        $this->assertSame('32.000', $prices[$paper->stock_item_id]);
        $this->assertSame('41.500', $prices[$ink->stock_item_id]);
    }

    public function test_a_shelf_may_be_bought_without_a_price_at_all(): void
    {
        // Arrange — الغيابُ هو الطريقُ القديم بعينه: يركب صاحبُه البيعَ إلى التسليم.
        $headers = $this->manager();
        $this->fundHolding('20000.00');

        // Act
        [$size, , $purchaseOrder] = $this->shipment($headers, printingSalePrice: null);

        // Assert
        $supply = InvestorDealSupply::query()
            ->where('source_id', $purchaseOrder->id)
            ->where('stock_item_id', $size->stock_item_id)
            ->firstOrFail();

        $this->assertNull($supply->printing_sale_price);
        $this->assertNull(StockBatch::query()
            ->where('stock_item_id', $size->stock_item_id)
            ->firstOrFail()
            ->printing_sale_price);
    }

    // ─────────────────────────── the money ───────────────────────────

    public function test_the_press_pays_the_fund_the_moment_it_takes_the_goods(): void
    {
        // Arrange — 300 كغ من رفٍّ سعرُه 32، بلا تسليمٍ ولا عميلٍ ولا فاتورةٍ محصَّلة.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');

        // Act
        $this->toThePress($this->foreman(), $order, $warehouse);

        // Assert — الثمنُ كاملاً: 300 × 32 = 9,600، لا الهامشُ وحدَه.
        $this->assertSame('9600.00', $this->pressPaid());

        // والهامشُ إلى المحافظ كما كان: 300 × (32 − 25) = 2,100، نصفُها للمستثمرين.
        $this->assertSame('1050.00', (string) InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Profit->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount'));
    }

    public function test_the_goods_the_press_bought_leave_the_valuation(): void
    {
        // Arrange — لولا هذا لحُسب المالُ مرّتين: نقداً في الدرج وبضاعةً في المطبعة.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');

        // Act
        $this->toThePress($this->foreman(), $order, $warehouse);

        // Assert
        $value = app(FundValuation::class)();

        // 20,000 − 12,500 (الشراء) + 9,600 (ثمن السادة)
        $this->assertSame('17100.00', $value['cash']);
        // 200 كغ بقيت على الرفّ بتكلفتها
        $this->assertSame('5000.00', $value['stock_on_shelf']);
        // ولا شيء «في الطريق»: تلك البضاعة بِيعت عند باب المخزن
        $this->assertSame('0.00', $value['goods_in_flight']);
    }

    public function test_a_cancelled_order_does_not_take_the_price_back_out_of_the_fund(): void
    {
        // Arrange — البضاعةُ عند المطبعة والثمنُ في الخزينة.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');
        $foreman = $this->foreman();
        $this->toThePress($foreman, $order, $warehouse);

        // Act — «استلم الزبون ما استلمش، المطبعة تتحمّل».
        $this->withHeaders($foreman)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'رفض الزبون استلام الطلبية',
        ])->assertOk();

        // Assert — البيعُ تمَّ عند باب المخزن، فلا الثمنُ يرجع ولا الهامشُ يُعكس. والبضاعةُ
        // الراجعةُ صارت للشركة لا للصندوق، فليس للصندوق ما يُردّ عنه.
        $this->assertSame('9600.00', $this->pressPaid());
        $this->assertSame('1050.00', (string) InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Profit->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount'));

        $value = app(FundValuation::class)();
        $this->assertSame('17100.00', $value['cash']);
        $this->assertSame('5000.00', $value['stock_on_shelf']);
    }

    public function test_bags_spoiled_at_the_press_are_paid_for_on_their_own_row(): void
    {
        // Arrange — الشغلُ في المطبعة، و20 كغ منه خرجت غلطاً.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');
        $foreman = $this->foreman();
        $this->toThePress($foreman, $order, $warehouse);

        $line = $order->items()->firstOrFail();

        // Act
        $this->withHeaders($foreman)->postJson(
            "/api/v1/orders/{$order->id}/items/{$line->id}/scrap",
            ['quantity' => '20', 'notes' => 'طباعة خرجت غلط'],
        )->assertCreated();

        // Assert — سحبٌ ثانٍ بجانب الأول لا بدلاً منه: 9,600 + 20 × 32 = 10,240، وصفّاه
        // منفصلان لأن مصدرَيهما مختلفان — السطرُ ثم الحركة.
        $this->assertSame('10240.00', $this->pressPaid());
        $this->assertSame(2, InvestmentCashEntry::query()
            ->where('type', CashEntryType::StockSoldToPress->value)
            ->count());

        // والهامشُ كذلك: 1,050 + 20 × (32 − 25) × 50% = 1,120.
        $this->assertSame('1120.00', (string) InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Profit->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount'));
    }

    public function test_the_close_pays_the_company_its_half_and_leaves_the_fund_on_its_capital(): void
    {
        // Arrange — المطبعةُ اشترت، فالهامشُ 2,100 نصفُه في المحافظ ونصفُه ما زال في الصندوق.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');

        // والطلبيةُ تمشي إلى بابها: الفترةُ لا تُقفَل على طلبيةٍ في الطريق، وهو حارسٌ قائمٌ قبل
        // اليوم. ولا يغيّر التسليمُ للصندوق شيئاً — بضاعتُه بِيعت عند باب المخزن.
        $this->deliver($this->foreman(), $order, $warehouse);

        // Act — تُقفل الفترة بعد شهرها.
        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = app(CloseInvestmentPeriod::class)(actorId: null);

        // Assert — الربحُ هامشُ السادة نفسُه، ونصفُه نصيبُ الشركة يخرج نقداً.
        $this->assertSame('2100.00', (string) $period->net_profit);
        $this->assertSame('1050.00', (string) $period->company_share);

        $this->assertSame('1050.00', (string) InvestmentCashEntry::query()
            ->where('type', CashEntryType::CompanyPayout->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount'));

        // **والثابتُ الذي يقوم عليه النموذجُ كلُّه:** ما دام الربحُ يُوزَّع كاملاً، يعود الصندوقُ
        // على رأس ماله عند الحافّة — 17,100 − 1,050 نقداً، و5,000 على الرفّ، و1,050 ديناً
        // لأصحابه. فلا قيمةَ محتجزةٌ يخفّفها داخلٌ جديد.
        $value = app(FundValuation::class)();
        $this->assertSame('16050.00', $value['cash']);
        $this->assertSame('20000.00', $value['total']);
    }

    public function test_a_priced_shelf_loses_nothing_when_printed_bags_are_cancelled(): void
    {
        // Arrange — طُبعت البضاعة وحملت شعارَ زبونها، ثم تراجع.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers);
        $order = $this->sale($size, '300', '60.000');
        $foreman = $this->foreman();
        $this->toReady($foreman, $order, $warehouse);

        // Act
        $this->cancel($foreman, $order);

        // Assert — البيعُ تمَّ عند باب المخزن قبل أن تمرّ على المكينة، فالثمنُ والهامشُ يبقيان
        // والخسارةُ كلُّها على المطبعة.
        $value = app(FundValuation::class)();

        $this->assertSame('9600.00', $this->pressPaid());
        $this->assertSame('17100.00', $value['cash']);
        $this->assertSame('5000.00', $value['stock_on_shelf']);
        $this->assertSame('21050.00', $value['total']);
    }

    public function test_an_unpriced_shelf_carries_the_loss_when_printed_bags_are_cancelled(): void
    {
        // Arrange — نفسُ المشهد بلا سعر سادة: البضاعةُ ما زالت مال الصندوق حين دخلت المكينة.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers, printingSalePrice: null);
        $order = $this->sale($size, '300', '60.000');
        $foreman = $this->foreman();
        $this->toReady($foreman, $order, $warehouse);

        // Act
        $this->cancel($foreman, $order);

        // Assert — **وهذا هو الفرق.** أكياسٌ طُبعت بشعار زبونٍ تراجع لا تعود إلى رفٍّ تُباع منه،
        // فتُشطب — ولا ثمنَ قُبض عنها. فينزل الصندوقُ بتكلفتها: 20,000 − 7,500.
        $value = app(FundValuation::class)();

        $this->assertSame('0', $this->pressPaid());
        $this->assertSame('7500.00', $value['cash']);
        $this->assertSame('5000.00', $value['stock_on_shelf']);
        $this->assertSame('0.00', $value['goods_in_flight']);
        $this->assertSame('12500.00', $value['total']);
    }

    public function test_an_unpriced_shelf_stays_in_the_valuation_and_pays_nothing_yet(): void
    {
        // Arrange — نفسُ المشهد بلا سعر: الطريقُ الآخر، والبضاعةُ ما زالت مال الصندوق.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$size, $warehouse] = $this->shipment($headers, printingSalePrice: null);
        $order = $this->sale($size, '300', '60.000');

        // Act
        $this->toThePress($this->foreman(), $order, $warehouse);

        // Assert — لا المطبعةُ دفعت، ولا المستثمرُ قُبض، والبضاعةُ محسوبةٌ بتكلفتها.
        $this->assertSame('0', $this->pressPaid());
        $this->assertSame('0', (string) InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Profit->value)
            ->sum('amount'));

        $value = app(FundValuation::class)();
        $this->assertSame('7500.00', $value['goods_in_flight']);
        $this->assertSame('7500.00', $value['cash']);
    }
}
