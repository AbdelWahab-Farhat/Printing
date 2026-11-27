<?php

declare(strict_types=1);

namespace Tests\Feature\InstantOrders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\SellsAtTheCounter;
use Tests\TestCase;

/**
 * An instant sale off stock an investor funded — INSTANT-ORDERS-PLAN.md §19.5, risk 2.
 *
 * The counter takes the stock at creation instead of at «جاهزة», so these tests hold it to the
 * normal order's road on the same goods: the plain line is not bought off the shelf, the investor
 * is paid out of the order's profit at handover, an edit moves the difference on the deal's own
 * layer, and a cancel puts the goods back on that layer with nothing paid.
 *
 * One shipment carries every case:
 *
 * ```
 * أمر شراء   500 كغ بتكلفة 25.000  =  12,500.00
 * تمويل      1,000 + 1,000 = 2,000   → الشركاء يملكون 16% ، ونصيبهم 50% من الربح
 * سعر البيع  40.000 للكيلو عند الكاونتر
 * ```
 *
 * Arrange - Act - Assert throughout.
 */
class InstantOrderInvestorStockTest extends TestCase
{
    use RefreshDatabase;
    use SellsAtTheCounter;

    protected function setUp(): void
    {
        parent::setUp();

        $this->registerPermissions();
    }

    /** @return array<string, string> */
    private function partner(): array
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

        $this->app['auth']->forgetGuards();

        return $this->headersFor($user);
    }

    private function investorHolding(string $amount): Investor
    {
        $investor = Investor::factory()->create();

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        return $investor;
    }

    /**
     * A plain size sold by the kilo at the counter, in an investable category.
     *
     * @return array{0: Product, 1: ProductVariant}
     */
    private function investablePlainProduct(): array
    {
        $category = ProductCategory::factory()->investable()->skipsProduction()->create();

        $product = Product::factory()->perKilogram()->create([
            'name' => 'أكياس شحن',
            'product_category_id' => $category->getKey(),
            'min_order_quantity' => 1,
            'is_active' => true,
            'is_instant_sale' => true,
        ]);

        $variant = ProductVariant::factory()
            ->drawingFrom(StockItem::factory()->unit(PricingUnit::Kilogram)->create())
            ->create(['product_id' => $product->getKey(), 'label' => '25*35']);

        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->getKey(),
            'min_quantity' => 1,
            'unit_price' => '40.000',
        ]);

        return [$product->refresh(), $variant->refresh()];
    }

    /**
     * 500 kg funded by two partners and received into the branch's own warehouse.
     *
     * @return array{0: InvestorDeal, 1: City, 2: User, 3: Product, 4: ProductVariant}
     */
    private function fundedCounter(): array
    {
        $warehouse = Warehouse::factory()->create(['name' => 'مخزن بريمولا']);
        $branch = $this->counterBranch($warehouse);
        $this->branchAccounts($branch);
        [$product, $variant] = $this->investablePlainProduct();

        $purchase = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        PurchaseOrderItem::factory()->forOrder($purchase)->create([
            'stock_item_id' => $variant->stock_item_id,
            'quantity_ordered' => '500.000',
            'base_total_cost' => '12500.00',
            'base_unit_cost' => '25.000',
            'allocated_additional_cost' => '0.00',
            'final_unit_cost' => '25.000',
            'final_total_cost' => '12500.00',
        ]);

        $headers = $this->partner();

        $this->withHeaders($headers)->postJson("/api/v1/purchase-orders/{$purchase->id}/investor-funding", [
            'investor_profit_share_percent' => 50,
            'investors' => array_map(
                fn (Investor $partner) => ['investor_id' => $partner->getKey(), 'amount' => '1000.00'],
                [$this->investorHolding('5000.00'), $this->investorHolding('5000.00')],
            ),
        ])->assertCreated();

        $this->withHeaders($headers)->postJson("/api/v1/purchase-orders/{$purchase->id}/arrivals", [
            'items' => [['stock_item_id' => $variant->stock_item_id, 'quantity' => '500.000']],
        ])->assertCreated();

        $this->app['auth']->forgetGuards();

        return [
            InvestorDeal::query()->where('purchase_order_id', $purchase->id)->firstOrFail(),
            $branch,
            $this->branchEmployee($branch),
            $product,
            $variant,
        ];
    }

    /** What this deal has paid out of one type, reversals excluded. */
    private function paid(InvestorDeal $deal, WalletEntryType $type): string
    {
        return (string) InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('type', $type->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');
    }

    /** What is left on the deal's own layer. */
    private function onTheDealsLayer(InvestorDeal $deal): string
    {
        return (string) StockBatch::query()->where('investor_deal_id', $deal->getKey())->sum('quantity_remaining');
    }

    private function handOver(User $employee, Order $order, int $amount): void
    {
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Delivered->value,
            'fields' => ['payment_amount' => $amount, 'payment_method' => 'cash'],
        ])->assertOk();
    }

    public function test_the_investor_is_paid_from_the_sale_at_handover_not_at_creation(): void
    {
        // Arrange
        [$deal, $branch, $employee, $product, $variant] = $this->fundedCounter();
        $this->assertSame('16.0000', (string) $deal->investor_funded_percent);

        // Act — 300 kg taken at the counter.
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 300);

        // Assert — the stock left the deal's layer, but a plain line is not bought off the shelf:
        // nothing is paid yet, exactly as a normal plain order at «جاهزة».
        $this->assertSame('200.000', $this->onTheDealsLayer($deal));
        $this->assertNull($order->items()->sole()->stock_purchased_at);
        $this->assertSame('0', $this->paid($deal, WalletEntryType::Profit));

        // Act — the customer pays 300 × 40 = 12,000 and takes the bags.
        $this->handOver($employee, $order->refresh(), 12000);

        // Assert — 12,000 − 7,500 = 4,500, of which the partners own 16% and keep half: 360.00.
        $this->assertSame('360.00', $this->paid($deal, WalletEntryType::Profit));
        $this->assertSame('0', $this->paid($deal, WalletEntryType::Loss));
    }

    public function test_an_edit_down_returns_the_difference_to_the_deal_and_pays_on_what_was_sold(): void
    {
        // Arrange — 300 kg taken.
        [$deal, $branch, $employee, $product, $variant] = $this->fundedCounter();
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 300);
        $line = $order->items()->sole();

        // Act — the customer wants 200 after all.
        $this->withHeaders($this->headersFor($employee))->putJson("/api/v1/instant-orders/{$order->id}", [
            'items' => [['id' => $line->id, 'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => 200]],
        ])->assertOk();

        // Assert — the 100 kg went back to the deal's own layer, not to the company's.
        $this->assertSame('300.000', $this->onTheDealsLayer($deal));
        $this->assertSame('0', $this->paid($deal, WalletEntryType::Profit));

        // Act — handed over at 200 × 40 = 8,000.
        $this->handOver($employee, $order->refresh(), 8000);

        // Assert — 8,000 − 5,000 = 3,000 × 16% × 50% = 240.00, on the edited quantity only.
        $this->assertSame('240.00', $this->paid($deal, WalletEntryType::Profit));
    }

    public function test_a_cancel_puts_the_goods_back_on_the_deal_with_nothing_paid(): void
    {
        // Arrange — 300 kg taken.
        [$deal, $branch, $employee, $product, $variant] = $this->fundedCounter();
        $order = $this->takeInstantOrder($branch, $employee, $product, $variant, 300);

        // Act
        $this->withHeaders($this->headersFor($employee))->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'غيّر رأيه',
        ])->assertOk();

        // Assert — all 500 are the deal's again, none became the company's, and nobody was paid.
        $this->assertSame('500.000', $this->onTheDealsLayer($deal));
        $this->assertSame(0, StockBatch::query()
            ->where('stock_item_id', $variant->stock_item_id)
            ->whereNull('investor_deal_id')
            ->where('quantity_remaining', '>', 0)
            ->count());
        $this->assertSame('0', $this->paid($deal, WalletEntryType::Profit));
        $this->assertSame('0', $this->paid($deal, WalletEntryType::Loss));
    }
}
