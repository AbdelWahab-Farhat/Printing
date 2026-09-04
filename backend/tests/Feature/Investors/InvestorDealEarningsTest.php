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
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\DTOs\DealItemData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\StockItemIsNotInvestable;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealItem;
use App\Domain\Investor\Models\InvestorDealShare;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * A deal buys stock, an order sells it, and the investor is paid — end to end, through the API.
 *
 * The whole feature in one path. Every figure below is arithmetic somebody can check by hand,
 * which is the point: an investor's share is the one number in this system that will be added up
 * on paper by a person who did not write it.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestorDealEarningsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @return array<string, string>
     */
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
            PermissionName::SettleOrders->value,
            PermissionName::CancelOrders->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** A shelf standing behind one product, under a heading the business invests in. */
    private function investableSize(): ProductVariant
    {
        $category = ProductCategory::factory()->create(['is_investable' => true]);

        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $category->getKey(),
            'is_active' => true,
        ]);

        return ProductVariant::factory()->for($product)->create([
            'label' => '25*35',
            'stock_item_id' => StockItem::factory()->unit(PricingUnit::Piece)->create()->getKey(),
        ]);
    }

    /**
     * A deal, open, with one investor holding all of it and 30,000 of his money in it.
     *
     * @return array{0: InvestorDeal, 1: Investor}
     */
    private function fundedDeal(ProductVariant $size, string $sharePercent = '100.0000'): array
    {
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->open()->create(['investor_profit_share_percent' => '50.00']);

        InvestorDealItem::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'stock_item_id' => $size->stock_item_id,
        ]);

        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'investor_id' => $investor->getKey(),
            'share_percent' => $sharePercent,
            'committed_amount' => '30000.00',
        ]);

        return [$deal, $investor];
    }

    /**
     * Stock arriving on a shelf, financed by [$deal] when one is named.
     *
     * **Posted through the real arrival path**, not built with a factory. `WarehouseStockFactory`
     * opens an opening-balance layer at cost zero dated 1970-01-01 — faithfully, because that is
     * what the backfill did to every shelf that existed before batch costing — and FIFO drains
     * those first. A test that arranged its balance that way would sell the deal's goods at a
     * cost of nothing and measure a profit that does not exist.
     */
    private function layer(
        ProductVariant $size,
        Warehouse $warehouse,
        string $quantity,
        string $unitCost,
        ?InvestorDeal $deal = null,
    ): StockBatch {
        app(InventoryService::class)->recordMovement(
            StockMovementData::arrival([
                'stock_item_id' => $size->stock_item_id,
                'to_warehouse_id' => $warehouse->getKey(),
                'quantity' => $quantity,
                'unit_cost' => $unitCost,
                // What `ReceivePurchaseOrder` stamps after asking Investment which deal claimed
                // this line — the one place the answer enters the ledger.
                'investor_deal_id' => $deal?->getKey(),
            ], (int) (User::query()->first() ?? User::factory()->create())->getKey()),
        );

        return StockBatch::query()->latest('id')->firstOrFail();
    }

    /**
     * @param  array<string, mixed>  $fields
     */
    private function move(array $headers, Order $order, OrderStatus $to, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            array_filter(['status' => $to->value, 'fields' => $fields ?: null]),
        );
    }

    /** Walk an order all the way to the customer's hands. */
    private function deliver(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->move($headers, $order, OrderStatus::ReadyToPrint, ['warehouse_id' => $warehouse->getKey()])->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Printing)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Ready)->assertOk();
        $carrier = ShippingCompany::factory()->create();
        $this->move($headers, $order->refresh(), OrderStatus::OutForDelivery, [
            'shipping_company_id' => $carrier->getKey(),
        ])->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Delivered)->assertOk();
    }

    // ─────────────────────────── the whole path ───────────────────────────

    public function test_an_investor_earns_his_half_of_what_his_stock_sold_for(): void
    {
        // Arrange — 1,000 units at 2.000 financed by the deal, sold at 5.000 apiece.
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal, $investor] = $this->fundedDeal($size);
        $this->layer($size, $warehouse, '1000', '2.000', $deal);

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '1000',
            'unit_price' => '5.000',
            'line_total' => '5000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());

        // Act
        $this->deliver($this->foreman(), $order->refresh(), $warehouse);

        // Assert — revenue 5,000.00, cost 2,000.00, so the order made 3,000.00. Half of it is
        // the investors' by this deal's terms, and this investor holds all of that half.
        $entry = InvestorWalletEntry::query()
            ->where('investor_id', $investor->getKey())
            ->where('type', WalletEntryType::Profit->value)
            ->sole();

        $this->assertSame('1500.00', (string) $entry->amount);
        $this->assertSame((int) $order->getKey(), (int) $entry->source_id);

        // And it is profit, not capital: his wallet's two pots stay apart.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('1500.00', $balances['deals'][$deal->getKey()]['profit']);
        $this->assertSame('0.00', $balances['wallet']['profit']);
    }

    public function test_a_deal_is_paid_only_for_the_units_it_actually_financed(): void
    {
        // Arrange — the line draws 2,000 of the company's own stock first (it is older) and then
        // 1,000 of the deal's. This is the case a proportional split gets wrong.
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal, $investor] = $this->fundedDeal($size);

        $company = $this->layer($size, $warehouse, '2000', '1.800');
        $company->forceFill(['received_at' => now()->subDays(10)])->save();

        $funded = $this->layer($size, $warehouse, '6000', '2.000', $deal);
        $funded->forceFill(['received_at' => now()->subDay()])->save();

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '3000',
            'unit_price' => '5.000',
            'line_total' => '15000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());

        // Act
        $this->deliver($this->foreman(), $order->refresh(), $warehouse);

        // Assert — the deal's third of the line is 5,000.00 of revenue against 2,000.00 of its
        // own cost, so it made 3,000.00 and the investors' half is 1,500.00.
        //
        // **Allocating across the deal's own draw alone would have credited it the whole
        // 15,000.00** — a largest-remainder split hands its total to whatever weights it is
        // given, and one weight takes all of it. That is a threefold overpayment that no
        // quantity or cost invariant in this system would notice.
        $entry = InvestorWalletEntry::query()
            ->where('investor_id', $investor->getKey())
            ->where('type', WalletEntryType::Profit->value)
            ->sole();

        $this->assertSame('1500.00', (string) $entry->amount);
    }

    public function test_two_investors_split_their_half_by_their_own_percentages(): void
    {
        // Arrange — 60/40 of the investors' half.
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal, $ahmed] = $this->fundedDeal($size, '60.0000');

        $mohamed = Investor::factory()->create();
        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'investor_id' => $mohamed->getKey(),
            'share_percent' => '40.0000',
            'committed_amount' => '20000.00',
        ]);

        $this->layer($size, $warehouse, '1000', '2.000', $deal);

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '1000',
            'unit_price' => '5.000',
            'line_total' => '5000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());

        // Act
        $this->deliver($this->foreman(), $order->refresh(), $warehouse);

        // Assert — 1,500.00 between them: 900.00 and 600.00, summing to the pool exactly.
        $amounts = InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Profit->value)
            ->orderBy('id')
            ->pluck('amount', 'investor_id')
            ->map(fn ($amount) => (string) $amount)
            ->all();

        $this->assertSame('900.00', $amounts[$ahmed->getKey()]);
        $this->assertSame('600.00', $amounts[$mohamed->getKey()]);
    }

    public function test_a_sale_that_lost_money_is_shared_the_same_way_a_profit_is(): void
    {
        // Arrange — bought at 6.000, sold at 5.000.
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal, $investor] = $this->fundedDeal($size);
        $this->layer($size, $warehouse, '1000', '6.000', $deal);

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '1000',
            'unit_price' => '5.000',
            'line_total' => '5000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());

        // Act
        $this->deliver($this->foreman(), $order->refresh(), $warehouse);

        // Assert — 1,000.00 lost on the order, half of it his: «لو خسرنا نتقاسمها زي مانتقاسم
        // الربح». Recorded as its own row type rather than as a negative amount, because every
        // amount in this ledger is positive and the direction lives in the type.
        $entry = InvestorWalletEntry::query()
            ->where('investor_id', $investor->getKey())
            ->where('type', WalletEntryType::Loss->value)
            ->sole();

        $this->assertSame('500.00', (string) $entry->amount);

        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('-500.00', $balances['deals'][$deal->getKey()]['profit']);
    }

    public function test_an_order_that_never_reached_the_customer_pays_nobody(): void
    {
        // Arrange
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal] = $this->fundedDeal($size);
        $this->layer($size, $warehouse, '1000', '2.000', $deal);

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '1000',
            'unit_price' => '5.000',
            'line_total' => '5000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        $headers = $this->foreman();

        // Act — the stock leaves at «جاهزة للطباعة», days before anybody is paid.
        $this->move($headers, $order->refresh(), OrderStatus::ReadyToPrint, ['warehouse_id' => $warehouse->getKey()])
            ->assertOk();

        // Assert — nothing is booked. Until an order is delivered it can still come home and be
        // cancelled, and its profit with it; writing the money early would mean taking it back.
        $this->assertSame(0, InvestorWalletEntry::query()->count());
    }

    public function test_delivering_the_same_order_twice_pays_once(): void
    {
        // Arrange
        $size = $this->investableSize();
        $warehouse = Warehouse::factory()->create();
        [$deal, $investor] = $this->fundedDeal($size);
        $this->layer($size, $warehouse, '1000', '2.000', $deal);

        $order = Order::factory()->create(['design_fee' => '0.00', 'delivery_price' => '0.00', 'discount' => '0.00']);
        OrderItem::factory()->for($order)->create([
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => '1000',
            'unit_price' => '5.000',
            'line_total' => '5000.00',
            'pricing_unit' => PricingUnit::Piece,
        ]);
        app(RecalculateOrderTotals::class)($order->refresh());
        $headers = $this->foreman();
        $this->deliver($headers, $order->refresh(), $warehouse);

        // Act — the same finalisation runs again, which is what a settlement after a delivery
        // does and what a retried job would do.
        app(InvestorService::class)->postEarningsForOrder((int) $order->getKey());
        app(InvestorService::class)->postEarningsForOrder((int) $order->getKey());

        // Assert — one row, one payment. The action compares what it would write against what
        // already stands and writes nothing when they agree; the partial unique index behind
        // (investor, deal, source, sequence) is the database's own backstop for the day a caller
        // forgets the lock.
        $this->assertSame(
            1,
            InvestorWalletEntry::query()
                ->where('investor_id', $investor->getKey())
                ->where('type', WalletEntryType::Profit->value)
                ->count(),
        );
    }

    public function test_a_deal_may_not_be_opened_against_a_shelf_a_non_investable_product_also_stands_on(): void
    {
        // Arrange — one shelf, two products: bags the business invests in, and stickers it does
        // not. This is the real shape of the catalogue, not a contrived one.
        $size = $this->investableSize();

        $stickers = ProductCategory::factory()->create(['is_investable' => false]);
        $sticker = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $stickers->getKey(),
            'is_active' => true,
        ]);
        ProductVariant::factory()->for($sticker)->create([
            'label' => '25*35',
            'stock_item_id' => $size->stock_item_id,
        ]);

        $deal = InvestorDeal::factory()->create();

        // Act
        $refused = false;

        try {
            app(InvestorService::class)->syncDealItems($deal, [
                new DealItemData(stockItemId: (int) $size->stock_item_id),
            ]);
        } catch (StockItemIsNotInvestable $e) {
            $refused = true;
        }

        // Assert — FIFO draws from the oldest layer whatever product is on the invoice, so a
        // shelf shared with a sticker would have the investor financing bags and being paid a
        // sticker's margin. The guard is «every product here is investable», not «one of them».
        $this->assertTrue($refused);
    }
}
