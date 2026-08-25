<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\ManufacturingCostRate;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * What a cancelled order gives back, once its stock already left the warehouse:
 *
 * > **the exact cost layers its fulfillment drew from, not a fresh one at an averaged cost** —
 * > and every production-cost entry it carries, voided by a further entry rather than rewritten.
 *
 * The order's own cost columns — `material_cost`, `labor_cost`, `overhead_cost`, `cogs`,
 * `total_cogs` — are asserted to stay exactly as they were: a cancellation is a separate
 * accounting event, not a rewrite of what production actually cost.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderCancellationReversalTest extends TestCase
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
            PermissionName::MoveOrderToReady->value,
            PermissionName::CancelOrders->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function balanceOf(Warehouse $warehouse, ProductVariant $variant): string
    {
        return (string) (WarehouseStock::query()
            ->where('warehouse_id', $warehouse->id)
            ->where('stock_item_id', $variant->stock_item_id)
            ->first()?->quantity ?? '0.000');
    }

    public function test_cancelling_after_ready_credits_back_the_exact_batches_it_drew_from(): void
    {
        // Arrange — two cost layers, so the fulfillment must span both
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'stock_item_id' => $variant->stock_item_id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 60, 'unit_cost' => 5,
        ])->assertCreated();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'stock_item_id' => $variant->stock_item_id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 60, 'unit_cost' => 8,
        ])->assertCreated();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => '90',
        ]);

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
        ])->assertOk();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Ready->value,
            'fields' => ['warehouse_id' => $warehouse->id],
        ])->assertOk();

        // 90 drawn: the whole 60@5 layer, then 30 of the 60@8 layer
        $batches = StockBatch::query()->where('warehouse_id', $warehouse->id)->orderBy('unit_cost')->get();
        $this->assertSame('0.000', (string) $batches[0]->quantity_remaining);
        $this->assertSame('30.000', (string) $batches[1]->quantity_remaining);
        $this->assertSame('30.000', $this->balanceOf($warehouse, $variant));

        // Act
        $order->refresh();
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'العميل ألغى الطلب',
        ])->assertOk();

        // Assert — both original layers restored exactly, not one averaged batch
        $batches->each->refresh();
        $this->assertSame('60.000', (string) $batches[0]->quantity_remaining);
        $this->assertSame('60.000', (string) $batches[1]->quantity_remaining);
        $this->assertSame('120.000', $this->balanceOf($warehouse, $variant));

        // No third, fourth layer was opened
        $this->assertDatabaseCount('stock_batches', 2);

        // And it is its own movement type, not an adjustment
        $this->assertDatabaseHas('stock_movements', [
            'movement_type' => 'order_reversal',
            'to_warehouse_id' => $warehouse->id,
            'from_warehouse_id' => null,
            'quantity' => '90.000',
            'reference_id' => $order->id,
        ]);

        // The line's own cost history is untouched
        $item->refresh();
        $this->assertNotNull($item->material_cost);
        $this->assertSame('540.00', (string) $item->material_cost); // 60@5 + 30@8 = 300 + 240
    }

    public function test_cancelling_after_ready_reverses_every_production_cost_entry(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'stock_item_id' => $variant->stock_item_id, 'to_warehouse_id' => $warehouse->id,
            'quantity' => 50, 'unit_cost' => 1,
        ])->assertCreated();

        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Labor)->rate('2.000')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => '50',
        ]);

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
        ])->assertOk();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Ready->value,
            'fields' => ['warehouse_id' => $warehouse->id],
        ])->assertOk();

        $order->refresh();
        $originalLaborCost = $item->refresh()->labor_cost;
        $originalCogs = $item->cogs;

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'العميل ألغى الطلب',
        ])->assertOk();

        // Assert — the original entry stands, and a reversal now points back at it
        $labor = ProductionCostEntry::query()
            ->where('order_item_id', $item->id)->where('cost_type', 'labor')
            ->whereNull('reverses_entry_id')->first();
        $this->assertNotNull($labor);
        $this->assertNotNull($labor->reversal);
        $this->assertSame((string) $labor->amount, (string) $labor->reversal->amount);

        // The cached cost columns are history, not recomputed
        $item->refresh();
        $this->assertSame((string) $originalLaborCost, (string) $item->labor_cost);
        $this->assertSame((string) $originalCogs, (string) $item->cogs);
        $this->assertSame((string) $originalCogs, (string) $order->refresh()->total_cogs);
    }

    public function test_cancelling_an_order_that_never_reached_ready_moves_no_stock(): void
    {
        // Arrange — Designing is reachable from New and, unlike Ready, deducts nothing; a
        // factory-built order starts there directly rather than walking guardDesigning's own
        // artwork requirement, which is not what this test is about.
        $order = Order::factory()->status(OrderStatus::Designing)->create();
        OrderItem::factory()->for($order)->create();
        $headers = $this->foreman();

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'لم يبدأ العمل بعد',
        ]);

        // Assert
        $response->assertOk();
        $this->assertDatabaseCount('stock_movements', 0);
    }

    public function test_a_reversal_credits_back_only_lines_that_actually_reached_ready(): void
    {
        // Arrange — a line that never reached ready carries no fulfillment_stock_movement_id;
        // the guard is expected to skip it rather than refuse the cancellation.
        $order = Order::factory()->status(OrderStatus::Designing)->create();
        $item = OrderItem::factory()->for($order)->create();
        $this->assertNull($item->fulfillment_stock_movement_id);

        $headers = $this->foreman();

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Cancelled->value,
            'reason' => 'إلغاء',
        ]);

        // Assert
        $response->assertOk();
        $this->assertSame(0, StockMovement::query()->where('movement_type', 'order_reversal')->count());
    }
}
