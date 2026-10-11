<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Actions\ResolveOrderFlow;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;
use App\Domain\Order\Support\TransitionFields;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Adding and removing products before «قيد الطباعة» — Docs/orders/ORDER-LINES-ADD-REMOVE.md.
 *
 * Two zones, and the file is laid out the same way:
 *
 * - **Zone 1, the stock still on the shelf** (جديدة · العربون · نواقص): an edit changes the lines
 *   and nothing else. Kept lines keep their id, price and shortage.
 * - **Zone 2, the stock already drawn** («جاهزة للطباعة» onwards, until the press): an edit moves
 *   each changed line's stock and re-posts the investors who sold it.
 *
 * And the question the owner asked first: **an order whose lines come back untouched behaves
 * exactly as before** — no price moves, no line is recreated, no stock moves.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderLinesAddRemoveTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    // ─────────────────────────── people ───────────────────────────

    /**
     * @param  list<PermissionName>  $extra
     * @return array<string, string>
     */
    private function staff(array $extra = []): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p): string => $p->value, [
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            ...$extra,
        ]));

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function foreman(): array
    {
        return $this->staff([
            PermissionName::MoveOrderToReadyToPrint,
            PermissionName::MoveOrderToPrinting,
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
        ]);
    }

    /** @return array<string, string> */
    private function partner(): array
    {
        return $this->staff([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
            PermissionName::ViewPurchaseOrders,
            PermissionName::ManagePurchaseOrders,
        ]);
    }

    // ─────────────────────────── goods ───────────────────────────

    /**
     * A size on a shelf of its own, priced 1.100 from 100 up.
     *
     * Sold by the piece and stocked by the piece unless told otherwise — the common case, where
     * what is sold is what leaves the shelf.
     */
    private function bagSize(
        string $label = '25*35',
        ?ProductCategory $category = null,
        PricingUnit $sold = PricingUnit::Piece,
        PricingUnit $stocked = PricingUnit::Piece,
    ): ProductVariant {
        $product = Product::factory()->create([
            'pricing_unit' => $sold,
            'product_category_id' => $category?->getKey(),
            'is_active' => true,
        ]);

        $variant = ProductVariant::factory()->for($product)->create([
            'label' => $label,
            'stock_item_id' => StockItem::factory()->unit($stocked)->create()->getKey(),
        ]);

        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->getKey(),
            'min_quantity' => '1',
            'unit_price' => '1.100',
        ]);

        return $variant;
    }

    /** `$quantity` of `$size` on `$warehouse`'s shelf, in one costed layer. */
    private function shelve(Warehouse $warehouse, ProductVariant $size, string $quantity): void
    {
        $shelf = StockItem::query()->findOrFail($size->stock_item_id);

        WarehouseStock::factory()->quantity($quantity)->unit($shelf->unit)->create([
            'warehouse_id' => $warehouse->getKey(),
            'stock_item_id' => $shelf->getKey(),
        ]);

        StockBatch::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'stock_item_id' => $shelf->getKey(),
            'quantity_received' => $quantity,
            'quantity_remaining' => $quantity,
            'unit_cost' => '2.000',
            'unit' => $shelf->unit,
        ]);
    }

    /**
     * An order holding one line per `[size, quantity]` pair, priced and totalled like a real one.
     *
     * @param  list<array{0: ProductVariant, 1: string}>  $lines
     */
    private function order(array $lines, OrderStatus $status = OrderStatus::New): Order
    {
        $order = Order::factory()->status($status)->create(['delivery_price' => '0.00']);

        foreach ($lines as $position => [$size, $quantity]) {
            OrderItem::factory()->for($order)->create([
                'product_id' => $size->product_id,
                'product_variant_id' => $size->getKey(),
                'product_name' => $size->product->name,
                'variant_label' => $size->label,
                'pricing_unit' => $size->product->pricing_unit,
                'quantity' => $quantity,
                'unit_price' => '1.100',
                'line_total' => bcmul($quantity, '1.100', 3),
                'sort_order' => $position,
            ]);
        }

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

    /**
     * @param  list<array<string, mixed>>  $items
     * @param  array<string, mixed>  $extra
     */
    private function edit(array $headers, Order $order, array $items, array $extra = []): TestResponse
    {
        return $this->withHeaders($headers)->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $order->city_id,
            'items' => $items,
            ...$extra,
        ]);
    }

    /**
     * A kept line, at its own quantity unless told otherwise.
     *
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function keep(OrderItem $line, ?string $quantity = null, array $extra = []): array
    {
        return [
            'id' => $line->getKey(),
            'product_id' => $line->product_id,
            'product_variant_id' => $line->product_variant_id,
            'quantity' => $quantity ?? (string) $line->quantity,
            ...$extra,
        ];
    }

    /**
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function add(ProductVariant $size, string $quantity, array $extra = []): array
    {
        return [
            'product_id' => $size->product_id,
            'product_variant_id' => $size->getKey(),
            'quantity' => $quantity,
            ...$extra,
        ];
    }

    private function balanceOf(Warehouse $warehouse, ProductVariant $size): string
    {
        return (string) (WarehouseStock::query()
            ->where('warehouse_id', $warehouse->getKey())
            ->where('stock_item_id', $size->stock_item_id)
            ->first()?->quantity ?? '0.000');
    }

    private function movementsOf(Order $order): int
    {
        return StockMovement::query()->where('reference_id', $order->getKey())->count();
    }

    /** Walks a fresh order into «جاهزة للطباعة», drawing its stock from `$warehouse`. */
    private function drawn(Order $order, Warehouse $warehouse, array $fields = []): Order
    {
        $this->move($this->foreman(), $order, OrderStatus::ReadyToPrint, [
            'warehouse_id' => $warehouse->getKey(),
            ...$fields,
        ])->assertOk();

        return $order->refresh();
    }

    // ─────────────────────── the normal flow, untouched ───────────────────────

    public function test_lines_sent_back_unchanged_keep_their_ids_and_prices(): void
    {
        // Arrange — the catalogue moves after the order was taken.
        $size = $this->bagSize();
        $order = $this->order([[$size, '300']]);
        $line = $order->items()->sole();
        ProductPriceTier::query()->where('product_variant_id', $size->getKey())->update(['unit_price' => '2.000']);

        // Act — what the edit screen sends when somebody only changed the notes.
        $response = $this->edit($this->staff(), $order, [$this->keep($line)], ['notes' => 'قبل الخميس']);

        // Assert — the same row, at the price the customer agreed to.
        $response->assertOk();
        $this->assertSame([$line->getKey()], $order->items()->pluck('id')->all());
        $this->assertSame('1.100', (string) $line->refresh()->unit_price);
        $this->assertSame('330.00', (string) $order->refresh()->grand_total);
        $this->assertSame(0, OrderItem::onlyTrashed()->where('order_id', $order->id)->count());
    }

    public function test_an_untouched_drawn_order_moves_no_stock_and_needs_no_extra_grant(): void
    {
        // Arrange — drawn at «جاهزة للطباعة».
        $size = $this->bagSize();
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '1000');
        $order = $this->drawn($this->order([[$size, '300']]), $warehouse);
        $line = $order->items()->sole();
        $movements = $this->movementsOf($order);

        // Act — a clerk without the stock grant saves the order with its lines as they were.
        $response = $this->edit($this->staff(), $order, [$this->keep($line)], ['notes' => 'تأكيد']);

        // Assert — nothing moved, and nobody was asked for a grant the edit did not need.
        $response->assertOk();
        $this->assertSame($movements, $this->movementsOf($order));
        $this->assertSame('700.000', $this->balanceOf($warehouse, $size));
        $this->assertSame($line->fulfillment_stock_movement_id, $line->refresh()->fulfillment_stock_movement_id);
    }

    public function test_the_lines_close_when_the_press_starts(): void
    {
        // Arrange
        $size = $this->bagSize();
        $order = $this->order([[$size, '300']], OrderStatus::Printing);

        // Act
        $response = $this->edit($this->staff(), $order, [$this->keep($order->items()->sole(), '500')]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame('300.000', (string) $order->items()->sole()->quantity);
    }

    // ─────────────────────── zone 1 — nothing drawn yet ───────────────────────

    public function test_a_product_can_be_added_to_a_new_order(): void
    {
        // Arrange
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $order = $this->order([[$first, '300']]);
        $line = $order->items()->sole();

        // Act
        $response = $this->edit($this->staff(), $order, [$this->keep($line), $this->add($second, '200')]);

        // Assert — both lines, the first still the same row, and the total over both.
        $response->assertOk();
        $this->assertSame(2, $order->items()->count());
        $this->assertTrue($order->items()->whereKey($line->getKey())->exists());
        $this->assertSame('550.00', (string) $order->refresh()->grand_total);
    }

    public function test_a_product_can_be_removed_while_the_deposit_is_awaited(): void
    {
        // Arrange
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $order = $this->order([[$first, '300'], [$second, '200']], OrderStatus::AwaitingDeposit);
        [$kept, $dropped] = $order->items()->orderBy('sort_order')->get()->all();

        // Act
        $response = $this->edit($this->staff(), $order, [$this->keep($kept)]);

        // Assert — removed one row at a time, so the history names it.
        $response->assertOk();
        $this->assertSame([$kept->getKey()], $order->items()->pluck('id')->all());
        $this->assertSoftDeleted($dropped);
        $this->assertSame('330.00', (string) $order->refresh()->grand_total);
    }

    public function test_a_changed_quantity_is_priced_again_at_its_new_tier(): void
    {
        // Arrange — 0.900 from 1,000 up.
        $size = $this->bagSize();
        ProductPriceTier::factory()->create([
            'product_variant_id' => $size->getKey(),
            'min_quantity' => '1000',
            'unit_price' => '0.900',
        ]);
        $order = $this->order([[$size, '300']]);
        $line = $order->items()->sole();

        // Act
        $this->edit($this->staff(), $order, [$this->keep($line, '1000')])->assertOk();

        // Assert — the same row, at the price 1,000 bags cost.
        $line->refresh();
        $this->assertSame('1000.000', (string) $line->quantity);
        $this->assertSame('0.900', (string) $line->unit_price);
    }

    public function test_a_hand_priced_line_keeps_its_price_when_none_is_sent(): void
    {
        // Arrange — a «حسب الطلب» product, priced by the clerk when the order was taken.
        $product = Product::factory()->quoteOnRequest()->create(['pricing_unit' => PricingUnit::Piece]);
        $size = ProductVariant::factory()->for($product)->create(['label' => 'كرتون']);
        $order = $this->order([[$size, '100']]);
        $line = $order->items()->sole();
        $line->forceFill(['unit_price' => '4.500', 'line_total' => '450.000'])->save();

        // Act — the edit screen never sent a price, which used to refuse every save.
        $response = $this->edit($this->staff(), $order, [$this->keep($line, '200')]);

        // Assert
        $response->assertOk();
        $this->assertSame('4.500', (string) $line->refresh()->unit_price);
        $this->assertSame('900.00', (string) $line->line_total);
    }

    public function test_a_shortage_survives_an_edit_to_the_order(): void
    {
        // Arrange — 50 of 300 missing, recorded on the line.
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $order = $this->order([[$first, '300']], OrderStatus::Shortage);
        $line = $order->items()->sole();
        $line->forceFill(['shortage_quantity' => '50.000'])->save();

        // Act — a product added beside it.
        $this->edit($this->staff(), $order, [$this->keep($line), $this->add($second, '100')])->assertOk();

        // Assert — the replace-everything edit used to wipe this.
        $this->assertSame('50.000', (string) $line->refresh()->shortage_quantity);
    }

    public function test_a_quantity_below_the_shortage_is_refused(): void
    {
        // Arrange
        $size = $this->bagSize();
        $order = $this->order([[$size, '300']], OrderStatus::Shortage);
        $line = $order->items()->sole();
        $line->forceFill(['shortage_quantity' => '50.000'])->save();

        // Act
        $response = $this->edit($this->staff(), $order, [$this->keep($line, '40')]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame('300.000', (string) $line->refresh()->quantity);
    }

    public function test_a_line_from_another_order_is_refused(): void
    {
        // Arrange
        $size = $this->bagSize();
        $order = $this->order([[$size, '300']]);
        $stranger = $this->order([[$size, '100']])->items()->sole();

        // Act
        $response = $this->edit($this->staff(), $order, [$this->keep($stranger)]);

        // Assert — and the stranger's own order is untouched.
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertNull($stranger->refresh()->deleted_at);
        $this->assertSame(1, $order->items()->count());
    }

    public function test_an_outsourced_product_cannot_join_an_in_house_order(): void
    {
        // Arrange
        $printed = $this->bagSize('25*35');
        $outsourced = $this->bagSize('علبة', ProductCategory::factory()->outsourced()->create());
        $order = $this->order([[$printed, '300']]);

        // Act
        $response = $this->edit($this->staff(), $order, [
            $this->keep($order->items()->sole()),
            $this->add($outsourced, '100'),
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame(1, $order->items()->count());
    }

    public function test_a_printed_product_added_while_the_deposit_is_paid_puts_the_order_on_the_press(): void
    {
        // Arrange — plain bags only, so the order skips the press.
        $plain = $this->bagSize('سادة', ProductCategory::factory()->skipsProduction()->create());
        $printed = $this->bagSize('مطبوع');
        $order = $this->order([[$plain, '300']], OrderStatus::DepositPaid);
        $this->assertSame(OrderFlow::NoProduction, $order->production_flow);

        // Act
        $this->edit($this->staff(), $order, [
            $this->keep($order->items()->sole()),
            $this->add($printed, '100'),
        ])->assertOk();

        // Assert
        $this->assertSame(OrderFlow::Standard, $order->refresh()->production_flow);
    }

    // ─────────────────────── zone 2 — the stock has left ───────────────────────

    public function test_a_product_added_after_the_draw_comes_off_the_same_shelf(): void
    {
        // Arrange
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $first, '1000');
        $this->shelve($warehouse, $second, '500');
        $order = $this->drawn($this->order([[$first, '300']]), $warehouse);

        // Act
        $response = $this->edit($this->foreman(), $order, [
            $this->keep($order->items()->sole()),
            $this->add($second, '200'),
        ]);

        // Assert — drawn from the order's own warehouse, and the line points at the draw.
        $response->assertOk();
        $this->assertSame('300.000', $this->balanceOf($warehouse, $second));
        $this->assertSame('700.000', $this->balanceOf($warehouse, $first));
        $added = $order->items()->where('product_variant_id', $second->getKey())->sole();
        $this->assertNotNull($added->fulfillment_stock_movement_id);
        $this->assertNotNull($added->material_cost);
    }

    public function test_a_product_removed_after_the_draw_goes_back_on_the_shelf(): void
    {
        // Arrange
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $first, '1000');
        $this->shelve($warehouse, $second, '500');
        $order = $this->drawn($this->order([[$first, '300'], [$second, '200']]), $warehouse);
        [$kept, $dropped] = $order->items()->orderBy('sort_order')->get()->all();
        $this->assertSame('300.000', $this->balanceOf($warehouse, $second));

        // Act
        $response = $this->edit($this->foreman(), $order, [$this->keep($kept)]);

        // Assert — every bag back, the line gone, and nothing left drawn on it for a later
        // cancellation to credit back a second time.
        $response->assertOk();
        $this->assertSame('500.000', $this->balanceOf($warehouse, $second));
        $this->assertSoftDeleted($dropped);
        $this->assertNull($dropped->refresh()->fulfillment_stock_movement_id);
        $this->assertSame('700.000', $this->balanceOf($warehouse, $first));
    }

    public function test_a_quantity_changed_after_the_draw_is_drawn_again(): void
    {
        // Arrange
        $size = $this->bagSize();
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '1000');
        $order = $this->drawn($this->order([[$size, '300']]), $warehouse);

        // Act
        $this->edit($this->foreman(), $order, [$this->keep($order->items()->sole(), '500')])->assertOk();

        // Assert
        $this->assertSame('500.000', $this->balanceOf($warehouse, $size));
        $this->assertSame('500.000', (string) $order->items()->sole()->quantity);
    }

    public function test_cancelling_after_an_edit_returns_exactly_what_the_edit_left_drawn(): void
    {
        // Arrange — drawn at 300, edited to 500.
        $size = $this->bagSize();
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '1000');
        $order = $this->drawn($this->order([[$size, '300']]), $warehouse);
        $this->edit($this->foreman(), $order, [$this->keep($order->items()->sole(), '500')])->assertOk();

        // Act
        $this->withHeaders($this->staff([PermissionName::CancelOrders]))
            ->postJson("/api/v1/orders/{$order->id}/status", [
                'status' => OrderStatus::Cancelled->value,
                'reason' => 'العميل ألغى',
            ])
            ->assertOk();

        // Assert — the whole thousand back, no more and no less.
        $this->assertSame('1000.000', $this->balanceOf($warehouse, $size));
    }

    public function test_changing_drawn_lines_needs_the_grant_that_drew_them(): void
    {
        // Arrange
        $size = $this->bagSize();
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '1000');
        $order = $this->drawn($this->order([[$size, '300']]), $warehouse);

        // Act — a clerk with `orders.manage` alone.
        $response = $this->edit($this->staff(), $order, [$this->keep($order->items()->sole(), '500')]);

        // Assert
        $response->assertForbidden();
        $this->assertSame('700.000', $this->balanceOf($warehouse, $size));
        $this->assertSame('300.000', (string) $order->items()->sole()->quantity);
    }

    public function test_a_restored_order_cannot_have_its_drawn_lines_changed(): void
    {
        // Arrange — stamped the way a restore stamps it.
        $size = $this->bagSize();
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '1000');
        $order = $this->drawn($this->order([[$size, '300']]), $warehouse);
        $order->forceFill(['stock_redrawn_at' => now()])->save();

        // Act
        $response = $this->edit($this->foreman(), $order, [$this->keep($order->items()->sole(), '500')]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame('700.000', $this->balanceOf($warehouse, $size));
    }

    public function test_a_product_the_shelf_cannot_cover_is_refused_by_name(): void
    {
        // Arrange — only 10 of the new size on the shelf.
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $first, '1000');
        $this->shelve($warehouse, $second, '10');
        $order = $this->drawn($this->order([[$first, '300']]), $warehouse);

        // Act
        $response = $this->edit($this->foreman(), $order, [
            $this->keep($order->items()->sole()),
            $this->add($second, '200'),
        ]);

        // Assert — nothing written, nothing moved.
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame(1, $order->items()->count());
        $this->assertSame('10.000', $this->balanceOf($warehouse, $second));
    }

    public function test_a_kilo_shelf_line_changed_after_the_draw_needs_its_weight(): void
    {
        // Arrange — sold by the piece, stocked by the kilo, 50 kg weighed out at the draw.
        $size = $this->bagSize('25*35', null, PricingUnit::Piece, PricingUnit::Kilogram);
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $size, '200');
        $order = $this->order([[$size, '1000']]);
        $line = $order->items()->sole();
        $order = $this->drawn($order, $warehouse, [TransitionFields::stockQuantityKey($line) => '50.000']);
        $this->assertSame('150.000', $this->balanceOf($warehouse, $size));

        // Act — the quantity changed and no weight came with it.
        $refused = $this->edit($this->foreman(), $order, [$this->keep($line, '2000')]);

        // Assert — asked under that line, and nothing moved.
        $refused->assertStatus(422)->assertJsonValidationErrors('items.0.warehouse_quantity');
        $this->assertSame('150.000', $this->balanceOf($warehouse, $size));

        // Act — the same edit with the weight.
        $this->edit($this->foreman(), $order, [$this->keep($line, '2000', ['warehouse_quantity' => '95.000'])])
            ->assertOk();

        // Assert
        $this->assertSame('105.000', $this->balanceOf($warehouse, $size));
    }

    public function test_a_line_with_spoilage_recorded_cannot_be_removed(): void
    {
        // Arrange
        $first = $this->bagSize('25*35');
        $second = $this->bagSize('30*40');
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $first, '1000');
        $this->shelve($warehouse, $second, '500');
        $order = $this->drawn($this->order([[$first, '300'], [$second, '200']]), $warehouse);
        [$kept, $spoiled] = $order->items()->orderBy('sort_order')->get()->all();
        ProductionCostEntry::factory()->forItem($spoiled)->scrapLoss()->create();

        // Act
        $response = $this->edit($this->foreman(), $order, [$this->keep($kept)]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertNull($spoiled->refresh()->deleted_at);
        $this->assertSame('300.000', $this->balanceOf($warehouse, $second));
    }

    public function test_an_edit_that_leaves_nothing_to_print_after_the_draw_is_refused(): void
    {
        // Arrange — one printed line and one plain one, drawn.
        $printed = $this->bagSize('مطبوع');
        $plain = $this->bagSize('سادة', ProductCategory::factory()->skipsProduction()->create());
        $warehouse = Warehouse::factory()->create();
        $this->shelve($warehouse, $printed, '1000');
        $this->shelve($warehouse, $plain, '1000');
        $order = $this->drawn($this->order([[$printed, '300'], [$plain, '100']]), $warehouse);
        $plainLine = $order->items()->where('product_variant_id', $plain->getKey())->sole();

        // Act — the printed line taken off.
        $response = $this->edit($this->foreman(), $order, [$this->keep($plainLine)]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame(2, $order->items()->count());
        $this->assertSame('700.000', $this->balanceOf($warehouse, $printed));
    }

    // ─────────────────────── the investors who sold the stock ───────────────────────

    public function test_removing_a_line_bought_from_a_deal_takes_the_investors_money_back(): void
    {
        // Arrange — 500 kg financed at 25.000 and sold to the press at 32.000, and a second size
        // of the company's own.
        $partner = $this->partner();
        $warehouse = Warehouse::factory()->create();
        $category = ProductCategory::factory()->investable()->create();
        $funded = $this->bagSize('25*35', $category, PricingUnit::Kilogram, PricingUnit::Kilogram);
        $own = $this->bagSize('30*40', $category, PricingUnit::Kilogram, PricingUnit::Kilogram);

        $deal = $this->fundedArrival($partner, $funded, $warehouse, '500.000', '25.000', '32.000');
        $this->shelve($warehouse, $own, '500');

        $order = $this->drawn($this->order([[$funded, '300'], [$own, '100']]), $warehouse);
        [$bought, $kept] = $order->items()->orderBy('sort_order')->get()->all();

        // 300 × (32 − 25) = 2,100; the partners own 2,000 ÷ 12,500 = 16% and keep half.
        $this->assertNotNull($bought->refresh()->stock_purchased_at);
        $paid = $this->paid($deal);
        $this->assertNotSame('0', $paid);

        // Act
        $this->edit($this->foreman(), $order, [$this->keep($kept)])->assertOk();

        // Assert — the goods are back on the deal's shelf and the payment for them is reversed,
        // written as a reversal rather than erased.
        $this->assertSame('500.000', $this->balanceOf($warehouse, $funded));
        $this->assertSame('0', $this->paid($deal));
        $this->assertSame($paid, (string) InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('type', WalletEntryType::Reversal->value)
            ->sum('amount'));
    }

    private function fundedArrival(
        array $headers,
        ProductVariant $size,
        Warehouse $warehouse,
        string $kilos,
        string $unitCost,
        string $printingSalePrice,
    ): InvestorDeal {
        $purchase = PurchaseOrder::factory()->create([
            'warehouse_id' => $warehouse->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        PurchaseOrderItem::factory()->forOrder($purchase)->create([
            'stock_item_id' => $size->stock_item_id,
            'quantity_ordered' => $kilos,
            'base_total_cost' => bcmul($kilos, $unitCost, 2),
            'base_unit_cost' => $unitCost,
            'allocated_additional_cost' => '0.00',
            'final_unit_cost' => $unitCost,
            'final_total_cost' => bcmul($kilos, $unitCost, 2),
        ]);

        $this->withHeaders($headers)->postJson("/api/v1/purchase-orders/{$purchase->id}/investor-funding", [
            'investor_profit_share_percent' => 50,
            'printing_sale_price' => $printingSalePrice,
            'investors' => [
                ['investor_id' => $this->investorHolding('5000.00')->getKey(), 'amount' => '1000.00'],
                ['investor_id' => $this->investorHolding('5000.00')->getKey(), 'amount' => '1000.00'],
            ],
        ])->assertCreated();

        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$purchase->id}/arrivals",
            ['items' => [['stock_item_id' => $size->stock_item_id, 'quantity' => $kilos]]],
        )->assertCreated();

        return InvestorDeal::query()->where('purchase_order_id', $purchase->id)->firstOrFail();
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

    private function paid(InvestorDeal $deal): string
    {
        return (string) InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('type', WalletEntryType::Profit->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');
    }
}
