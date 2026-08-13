<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Bags spoiled during production: a real stock loss, FIFO-costed, and a real entry on the
 * order's own cost ledger — but never a rewrite of what the line's own fulfillment already cost.
 *
 * Arrange - Act - Assert throughout.
 */
class ScrapLossTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** @return array<string, string> */
    private function foreman(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function balanceOf(Warehouse $warehouse, ProductVariant $variant): string
    {
        return (string) (WarehouseStock::query()
            ->where('warehouse_id', $warehouse->id)
            ->where('product_variant_id', $variant->id)
            ->first()?->quantity ?? '0.000');
    }

    private function printedOrder(array $headers): array
    {
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 100, 'unit_cost' => 4,
        ])->assertCreated();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => '40',
        ]);

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
            'fields' => ['warehouse_id' => $warehouse->id],
        ])->assertOk();

        return [$order->refresh(), $item->refresh(), $warehouse, $variant];
    }

    public function test_scrap_draws_stock_and_records_its_fifo_cost(): void
    {
        // Arrange — 40 drawn on entering printing, 60 left at 4 each
        $headers = $this->foreman();
        [$order, $item, $warehouse, $variant] = $this->printedOrder($headers);
        $this->assertSame('60.000', $this->balanceOf($warehouse, $variant));

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 10, 'notes' => 'انحراف في طباعة الشعار'],
        );

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.cost_type', 'scrap_loss')
            ->assertJsonPath('data.amount', '40.00')   // 10 @ 4
            ->assertJsonPath('data.rate', null);

        $this->assertSame('50.000', $this->balanceOf($warehouse, $variant)); // 60 - 10
        $this->assertDatabaseHas('production_cost_entries', [
            'order_id' => $order->id, 'order_item_id' => $item->id,
            'cost_type' => 'scrap_loss', 'amount' => '40.00',
        ]);
        $this->assertDatabaseHas('stock_movements', [
            'movement_type' => 'scrap_loss', 'from_warehouse_id' => $warehouse->id,
            'to_warehouse_id' => null, 'quantity' => '10.000', 'reference_id' => $order->id,
        ]);
    }

    public function test_scrap_does_not_rewrite_the_lines_own_material_cost(): void
    {
        // Arrange
        $headers = $this->foreman();
        [$order, $item] = $this->printedOrder($headers);
        $originalMaterialCost = $item->material_cost;
        $originalCogs = $item->cogs;

        // Act
        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 5, 'notes' => 'كيس ممزق'],
        )->assertCreated();

        // Assert — the original fulfillment's own cost is untouched
        $item->refresh();
        $this->assertSame((string) $originalMaterialCost, (string) $item->material_cost);
        $this->assertSame((string) $originalCogs, (string) $item->cogs);
    }

    public function test_scrap_is_refused_before_the_order_has_reached_printing(): void
    {
        // Arrange
        $headers = $this->foreman();
        $order = Order::factory()->status(OrderStatus::Designing)->create();
        $item = OrderItem::factory()->for($order)->create();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 1, 'notes' => 'تجربة'],
        );

        // Assert
        $response->assertStatus(422);
        $this->assertDatabaseCount('stock_movements', 0);
        $this->assertDatabaseCount('production_cost_entries', 0);
    }

    public function test_a_scrap_quantity_that_exceeds_the_shelf_is_refused(): void
    {
        // Arrange
        $headers = $this->foreman();
        [$order, $item, $warehouse, $variant] = $this->printedOrder($headers);

        // Act — more than the 60 remaining
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 1000, 'notes' => 'تجربة'],
        );

        // Assert
        $response->assertStatus(422);
        $this->assertSame('60.000', $this->balanceOf($warehouse, $variant));
    }

    public function test_an_item_belonging_to_another_order_is_not_found(): void
    {
        // Arrange
        $headers = $this->foreman();
        [$order] = $this->printedOrder($headers);
        $otherOrder = Order::factory()->create();
        $foreignItem = OrderItem::factory()->for($otherOrder)->create();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$foreignItem->id}/scrap",
            ['quantity' => 1, 'notes' => 'تجربة'],
        );

        // Assert
        $response->assertNotFound();
    }

    public function test_recording_scrap_needs_the_inventory_manage_permission(): void
    {
        // Arrange
        $headers = $this->foreman();
        [$order, $item] = $this->printedOrder($headers);
        $user = User::factory()->create();
        $user->givePermissionTo([PermissionName::ViewOrders->value, PermissionName::ManageOrders->value]);
        $viewerHeaders = ['Authorization' => 'Bearer '.$user->createToken('t')->plainTextToken];

        // The container is reused within one test, so the auth guard would otherwise keep
        // resolving the foreman from the setup requests above.
        $this->app->get('auth')->forgetGuards();

        // Act
        $response = $this->withHeaders($viewerHeaders)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 1, 'notes' => 'تجربة'],
        );

        // Assert
        $response->assertForbidden();
    }

    public function test_notes_are_required(): void
    {
        // Arrange
        $headers = $this->foreman();
        [$order, $item] = $this->printedOrder($headers);

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/scrap",
            ['quantity' => 1],
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('notes');
    }
}
