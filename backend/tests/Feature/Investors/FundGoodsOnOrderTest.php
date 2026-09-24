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
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Queries\FundGoodsOnOrder;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Actions\CancelPurchaseOrder;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * بضاعةٌ اشتراها الصندوقُ بماله ولم تصل الرفَّ بعد — «بضاعة مشتراة لم تصل».
 *
 * طلبُ المالك 2026-09-24: «تقدر تعرض القيمة الموجودة في عمليات الشراء التي لم تصل بعد واشتُريت
 * بمال الصندوق حتى أعرف إجماليها».
 *
 * **عرضٌ لا بندٌ في القيمة — قرارُ المالك 2026-09-24: «عرض لأن المال استُعمل بالفعل».** ثمنُ
 * اللوري خرج من الخزينة يومَ الشراء، والرقمُ هنا يقول أين هو حتى يصل الرفّ؛ وقيمةُ الصندوق وسعرُ
 * الوحدة لا يعدّانه.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundGoodsOnOrderTest extends TestCase
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

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** مالٌ على الطاولة، ثم اشتراكٌ به في الصندوق. */
    private function fundHolding(string $amount): void
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
    }

    /**
     * أمرُ شراءٍ جديد بسطرين: أكياسٌ 500 كغ بـ25 (12,500)، ورولٌ 100 كغ بـ20 (2,000).
     *
     * @return array{0: PurchaseOrder, 1: StockItem, 2: StockItem}
     */
    private function purchaseOrder(): array
    {
        $order = PurchaseOrder::factory()->create([
            'vendor_id' => Vendor::factory()->create(['name' => 'مصنع الشرق للأكياس'])->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'status' => PurchaseOrderStatus::New,
            'order_date' => '2026-08-30',
        ]);

        $bags = $this->investableShelf('كيس 25×35');
        $rolls = $this->investableShelf('رول نايلون');

        PurchaseOrderItem::factory()->forOrder($order)->create([
            'stock_item_id' => $bags->id,
            'quantity_ordered' => '500.000',
            'base_total_cost' => '12500.00',
            'base_unit_cost' => '25.000',
            'final_unit_cost' => '25.000',
            'final_total_cost' => '12500.00',
            'unit' => PricingUnit::Kilogram,
        ]);

        PurchaseOrderItem::factory()->forOrder($order)->create([
            'stock_item_id' => $rolls->id,
            'quantity_ordered' => '100.000',
            'base_total_cost' => '2000.00',
            'base_unit_cost' => '20.000',
            'final_unit_cost' => '20.000',
            'final_total_cost' => '2000.00',
            'unit' => PricingUnit::Kilogram,
        ]);

        return [$order->refresh(), $bags, $rolls];
    }

    /**
     * رفٌّ يجوز للصندوق أن يملكه — حارسُ «كلّ منتج» في `CatalogService::stockItemInvestability`
     * يرفض مادّةً لا يبيعها منتجٌ من صنفٍ مفتوحٍ للاستثمار.
     */
    private function investableShelf(string $name): StockItem
    {
        $shelf = StockItem::factory()->named($name)->unit(PricingUnit::Kilogram)->create();
        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Kilogram,
            'product_category_id' => ProductCategory::factory()->investable()->create()->getKey(),
            'is_active' => true,
        ]);

        ProductVariant::factory()->for($product)->create(['stock_item_id' => $shelf->getKey()]);

        return $shelf;
    }

    /** @param  array<string, string>  $headers */
    private function fundBuys(array $headers, PurchaseOrder $order, StockItem $shelf): void
    {
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            ['stock_item_ids' => [$shelf->id]],
        )->assertOk();
    }

    /** @param  array<string, string>  $headers */
    private function receive(array $headers, PurchaseOrder $order, StockItem $shelf, string $quantity): void
    {
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => [['stock_item_id' => $shelf->id, 'quantity' => $quantity]]],
        )->assertCreated();
    }

    /** رقمُ «بضاعة مشتراة لم تصل» كما تعرضه اللوحة. */
    private function onOrder(): string
    {
        return Money::round(app(FundGoodsOnOrder::class)->value());
    }

    public function test_a_paid_lorry_on_its_way_is_counted_at_what_left_the_treasury(): void
    {
        // Arrange — عشرون ألفاً في الخزينة، واشترى الصندوقُ الأكياسَ بـ12,500.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();

        // Act
        $this->fundBuys($headers, $order, $bags);

        // Assert — ما خرج من الخزينة بعينه.
        $this->assertSame('12500.00', $this->onOrder());
    }

    public function test_the_fund_value_leaves_it_out_because_the_money_is_already_spent(): void
    {
        // Arrange — قرارُ المالك: «عرض لأن المال استُعمل بالفعل».
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();

        // Act
        $this->fundBuys($headers, $order, $bags);

        // Assert — القيمةُ بنودُها الخمسة كما كانت، واللوحةُ تقول الرقمَ بجانبها لا داخلها.
        $value = app(FundValuation::class)();
        $this->assertSame('7500.00', $value['cash']);
        $this->assertSame('7500.00', $value['total']);
        $this->assertArrayNotHasKey('goods_on_order', $value);

        $dashboard = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');
        $dashboard->assertOk()
            ->assertJsonPath('data.goods_on_order', '12500.00')
            ->assertJsonPath('data.valuation.total', '7500.00');
    }

    public function test_a_short_delivery_leaves_only_what_is_still_owed_on_order(): void
    {
        // Arrange — وصل 300 كغ من 500: ما وصل على الرفّ، وما بقي عند المورّد ما زال مالَ الصندوق.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();
        $this->fundBuys($headers, $order, $bags);

        // Act
        $this->receive($headers, $order, $bags, '300.000');

        // Assert
        $this->assertSame('7500.00', app(FundValuation::class)()['stock_on_shelf']);
        $this->assertSame('5000.00', $this->onOrder());
    }

    public function test_a_full_delivery_leaves_nothing_on_order(): void
    {
        // Arrange
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();
        $this->fundBuys($headers, $order, $bags);

        // Act
        $this->receive($headers, $order, $bags, '500.000');

        // Assert — عدٌّ مرّتين هو ما يُحذَر هنا: الواصلُ على الرفّ وحده.
        $this->assertSame('0.00', $this->onOrder());
        $this->assertSame('12500.00', app(FundValuation::class)()['stock_on_shelf']);
    }

    public function test_a_line_the_fund_did_not_buy_is_not_its_money(): void
    {
        // Arrange — الأمرُ سطران، والصندوقُ اشترى الأكياسَ وحدها؛ الرولُ على حساب الشركة.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();

        // Act
        $this->fundBuys($headers, $order, $bags);

        // Assert
        $this->assertSame('12500.00', $this->onOrder());
    }

    public function test_a_cancelled_order_brings_nothing_so_it_holds_no_value_on_order(): void
    {
        // Arrange — أمرٌ اشتراه الصندوقُ ثم أُلغي: لن يصل منه شيء.
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();
        $this->fundBuys($headers, $order, $bags);

        // Act
        app(CancelPurchaseOrder::class)($order->refresh());

        // Assert — لا يُعدّ بضاعةً قادمة. وما خرج من الخزينة له لا يعود بالإلغاء وحده — سؤالٌ
        // مفتوحٌ للمالك، لا يُحسم هنا بأن يُعدَّ ما لن يأتي.
        $this->assertSame('0.00', $this->onOrder());
    }

    public function test_the_list_names_each_order_its_vendor_and_what_is_still_to_come(): void
    {
        // Arrange
        $headers = $this->manager();
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->purchaseOrder();
        $this->fundBuys($headers, $order, $bags);
        $this->receive($headers, $order, $bags, '300.000');

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund/on-order');

        // Assert — والمجموعُ رقمُ اللوحة بعينه.
        $response->assertOk()
            ->assertJsonPath('data.total', '5000.00')
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.purchase_order_id', $order->id)
            ->assertJsonPath('data.orders.0.vendor_name', 'مصنع الشرق للأكياس')
            ->assertJsonPath('data.orders.0.order_date', '2026-08-30')
            ->assertJsonPath('data.orders.0.value', '5000.00')
            ->assertJsonCount(1, 'data.orders.0.lines')
            ->assertJsonPath('data.orders.0.lines.0.stock_item_id', $bags->id)
            ->assertJsonPath('data.orders.0.lines.0.name', 'كيس 25×35')
            ->assertJsonPath('data.orders.0.lines.0.unit_label', 'كجم')
            ->assertJsonPath('data.orders.0.lines.0.quantity_ordered', '500.000')
            ->assertJsonPath('data.orders.0.lines.0.quantity_received', '300.000')
            ->assertJsonPath('data.orders.0.lines.0.quantity_remaining', '200.000')
            ->assertJsonPath('data.orders.0.lines.0.value', '5000.00');

        $this->assertSame($this->onOrder(), $response->json('data.total'));
    }

    public function test_reading_the_list_needs_the_investors_view(): void
    {
        // Arrange
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewPurchaseOrders->value);
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund/on-order');

        // Assert
        $response->assertForbidden();
    }
}
