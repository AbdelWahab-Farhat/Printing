<?php

declare(strict_types=1);

namespace Tests\Feature\Inventory;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Order\Actions\RedrawOrderLineStock;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «حركات المخزون» for one order — `GET /stock-movements?order_id=`.
 *
 * The rows that belong are the ones the order itself wrote; the rows that must stay out are the
 * ones that only carry its number in `reference_id`. Most tests here plant both.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderStockMovementsTest extends TestCase
{
    use RefreshDatabase;

    private User $foreman;

    /** @var array<string, string> */
    private array $headers;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        $this->foreman = User::factory()->create();
        $this->foreman->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::MoveOrderToReadyToPrint->value,
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::MoveOrderToReady->value,
            PermissionName::CancelOrders->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        $this->headers = ['Authorization' => 'Bearer '.$this->foreman->createToken('test')->plainTextToken];
    }

    /**
     * An order whose one line has drawn 40 off a stocked shelf — the draw happens at the
     * handover to «جاهزة للطباعة». `$toReady` walks it on to «جاهزة», where scrap may be recorded.
     *
     * @return array{Order, OrderItem, Warehouse, ProductVariant}
     */
    private function drawnOrder(bool $toReady = false): array
    {
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();

        $this->withHeaders($this->headers)->postJson('/api/v1/stock-movements/arrivals', [
            'stock_item_id' => $variant->stock_item_id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 100, 'unit_cost' => 4,
        ])->assertCreated();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => '40',
        ]);

        $this->withHeaders($this->headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::ReadyToPrint->value,
            'fields' => ['warehouse_id' => $warehouse->id],
        ])->assertOk();

        if ($toReady) {
            foreach ([OrderStatus::Printing, OrderStatus::Ready] as $step) {
                $this->withHeaders($this->headers)->postJson("/api/v1/orders/{$order->id}/status", [
                    'status' => $step->value,
                ])->assertOk();
            }
        }

        return [$order->refresh(), $item->refresh(), $warehouse, $variant];
    }

    /** @return list<int> */
    private function idsFor(int $orderId, array $query = []): array
    {
        return $this->withHeaders($this->headers)
            ->getJson('/api/v1/stock-movements?'.http_build_query(['order_id' => $orderId, ...$query]))
            ->assertOk()
            ->collect('data')
            ->pluck('id')
            ->all();
    }

    private function latest(string $type): StockMovement
    {
        return StockMovement::query()->where('movement_type', $type)->latest('id')->firstOrFail();
    }

    /**
     * Rows that carry the order's number without being the order's: a receipt and a hand-typed
     * issue, both posted through the generic endpoints that take any reference at all.
     */
    private function plantLookalikes(Order $order, Warehouse $warehouse, ProductVariant $variant): void
    {
        $this->withHeaders($this->headers)->postJson('/api/v1/stock-movements/arrivals', [
            'stock_item_id' => $variant->stock_item_id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 5, 'unit_cost' => 4, 'reference_id' => $order->id,
        ])->assertCreated();

        $this->withHeaders($this->headers)->postJson('/api/v1/stock-movements/fulfillments', [
            'stock_item_id' => $variant->stock_item_id, 'from_warehouse_id' => $warehouse->id,
            'quantity' => 2, 'reference_id' => $order->id,
        ])->assertCreated();
    }

    public function test_an_order_lists_its_draw_the_redraw_that_replaced_it_and_its_scrap(): void
    {
        // Arrange — drawn 40, restated to 30 (reversal + fresh draw), then 5 spoiled
        [$order, $item, $warehouse, $variant] = $this->drawnOrder(toReady: true);
        $firstDraw = (int) $item->fulfillment_stock_movement_id;

        DB::transaction(fn () => app(RedrawOrderLineStock::class)($order, $item, '30', (int) $this->foreman->id));
        $reversal = $this->latest('order_reversal');
        $secondDraw = (int) $item->refresh()->fulfillment_stock_movement_id;

        $this->withHeaders($this->headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 5, 'notes' => 'انحراف في الطباعة'],
        )->assertCreated();
        $scrap = $this->latest('scrap_loss');

        $this->plantLookalikes($order, $warehouse, $variant);
        $this->drawnOrder(); // somebody else's order, drawing from its own shelf

        // Act
        $ids = $this->idsFor($order->id);

        // Assert — newest first, and nothing that merely shares the number
        $this->assertNotSame($firstDraw, $secondDraw);
        $this->assertSame([$scrap->id, $secondDraw, $reversal->id, $firstDraw], $ids);
    }

    public function test_a_cancelled_order_still_shows_what_left_and_what_came_back(): void
    {
        // Arrange — cancelled before printing, so the 40 go back on the shelf
        [$order, $item] = $this->drawnOrder();
        $draw = (int) $item->fulfillment_stock_movement_id;

        $this->withHeaders($this->headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'العميل ألغى',
        ])->assertOk();
        $reversal = $this->latest('order_reversal');

        // Act
        $ids = $this->idsFor($order->id);

        // Assert
        $this->assertSame($reversal->reverses_movement_id, $draw);
        $this->assertSame([$reversal->id, $draw], $ids);
    }

    public function test_the_order_filter_narrows_the_other_filters_rather_than_widening_them(): void
    {
        // Arrange — a draw and a scrap on the order, and a look-alike beside them
        [$order, $item, $warehouse, $variant] = $this->drawnOrder(toReady: true);

        $this->withHeaders($this->headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 5, 'notes' => 'تلف'],
        )->assertCreated();
        $scrap = $this->latest('scrap_loss');

        $this->plantLookalikes($order, $warehouse, $variant);

        // Act
        $scrapOnly = $this->idsFor($order->id, ['movement_type' => 'scrap_loss']);
        $fulfillmentsOnly = $this->idsFor($order->id, ['movement_type' => 'order_fulfillment']);

        // Assert — the OR set is grouped, so the type filter still applies to every branch of it
        $this->assertSame([$scrap->id], $scrapOnly);
        $this->assertSame([(int) $item->fulfillment_stock_movement_id], $fulfillmentsOnly);
    }

    public function test_an_order_that_never_drew_has_no_movements(): void
    {
        // Arrange — stock moves elsewhere, and a receipt happens to carry this order's number
        [, , $warehouse, $variant] = $this->drawnOrder();
        $untouched = Order::factory()->create();
        $this->plantLookalikes($untouched, $warehouse, $variant);

        // Act
        $ids = $this->idsFor($untouched->id);

        // Assert
        $this->assertSame([], $ids);
    }

    public function test_reading_an_orders_movements_needs_the_inventory_grant(): void
    {
        // Arrange — may see the order, may not see the stock
        [$order] = $this->drawnOrder();
        $clerk = User::factory()->create();
        $clerk->givePermissionTo(PermissionName::ViewOrders->value);

        // Act
        $response = $this->withHeaders(['Authorization' => 'Bearer '.$clerk->createToken('test')->plainTextToken])
            ->getJson("/api/v1/stock-movements?order_id={$order->id}");

        // Assert
        $response->assertForbidden();
    }
}
