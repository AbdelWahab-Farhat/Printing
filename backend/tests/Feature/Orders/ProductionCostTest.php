<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
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
 * What entering `printing` costs an order's lines: the FIFO material draw, plus whatever
 * manufacturing rates apply — and what happens when one of those inputs is missing.
 *
 * Arrange - Act - Assert throughout.
 */
class ProductionCostTest extends TestCase
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
            PermissionName::MoveOrderToShortage->value,
            PermissionName::ViewInventory->value,
            PermissionName::ManageInventory->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function enterPrinting(array $headers, Order $order, Warehouse $warehouse): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
            'fields' => ['warehouse_id' => $warehouse->id],
        ])->assertOk();
    }

    public function test_entering_printing_costs_material_labor_and_overhead_onto_the_line_and_the_order(): void
    {
        // Arrange — a real costed batch, and rates for both cost types this product carries
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => 100,
            'unit_cost' => 4,
        ])->assertCreated();

        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Labor)->rate('2.000')->create();
        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Overhead)->rate('0.500')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'quantity' => '100',
        ]);

        // Act
        $this->enterPrinting($headers, $order, $warehouse);

        // Assert — material: 100 @ 4 = 400.00; labor: 100 @ 2 = 200.00; overhead: 100 @ 0.5 = 50.00
        $item->refresh();
        $this->assertSame('400.00', (string) $item->material_cost);
        $this->assertSame('200.00', (string) $item->labor_cost);
        $this->assertSame('50.00', (string) $item->overhead_cost);
        $this->assertSame('650.00', (string) $item->cogs);

        $order->refresh();
        $this->assertSame('650.00', (string) $order->total_cogs);
        $this->assertSame(
            bcsub((string) $order->grand_total, '650.00', 2),
            $order->grossProfit(),
        );

        // And the entries are individually recorded, not just the cached sum
        $this->assertDatabaseHas('production_cost_entries', [
            'order_item_id' => $item->id, 'cost_type' => 'labor', 'quantity' => '100.000',
            'rate' => '2.000', 'amount' => '200.00',
        ]);
        $this->assertDatabaseHas('production_cost_entries', [
            'order_item_id' => $item->id, 'cost_type' => 'overhead', 'amount' => '50.00',
        ]);
    }

    public function test_a_cost_type_with_no_applicable_rate_is_skipped_not_zeroed(): void
    {
        // Arrange — a product-specific labor rate, but nothing for overhead at all
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => 50,
            'unit_cost' => 2,
        ])->assertCreated();

        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Labor)->rate('1.000')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'quantity' => '50',
        ]);

        // Act
        $this->enterPrinting($headers, $order, $warehouse);

        // Assert — overhead was never computed, not computed as 0
        $item->refresh();
        $this->assertSame('100.00', (string) $item->material_cost); // 50 @ 2
        $this->assertSame('50.00', (string) $item->labor_cost);     // 50 @ 1
        $this->assertNull($item->overhead_cost);
        $this->assertSame('150.00', (string) $item->cogs);          // material + labor only
    }

    public function test_the_default_rate_applies_when_the_product_has_none_of_its_own(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => 20,
            'unit_cost' => 1,
        ])->assertCreated();

        ManufacturingCostRate::factory()->default()->type(ManufacturingCostType::Labor)->rate('0.750')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'quantity' => '20',
        ]);

        // Act
        $this->enterPrinting($headers, $order, $warehouse);

        // Assert — 20 @ 0.75 = 15.00
        $this->assertSame('15.00', (string) $item->refresh()->labor_cost);
    }

    public function test_a_product_specific_rate_wins_over_the_default(): void
    {
        // Arrange
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => 10,
            'unit_cost' => 1,
        ])->assertCreated();

        ManufacturingCostRate::factory()->default()->type(ManufacturingCostType::Labor)->rate('9.000')->create();
        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Labor)->rate('2.000')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'quantity' => '10',
        ]);

        // Act
        $this->enterPrinting($headers, $order, $warehouse);

        // Assert — 10 @ 2, not 10 @ 9
        $this->assertSame('20.00', (string) $item->refresh()->labor_cost);
    }

    public function test_a_reprint_does_not_reapply_manufacturing_rates(): void
    {
        // Arrange — already printed once, with a labor rate in place
        $product = Product::factory()->create();
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        $warehouse = Warehouse::factory()->create();
        $headers = $this->foreman();

        $this->withHeaders($headers)->postJson('/api/v1/stock-movements/arrivals', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => 100,
            'unit_cost' => 1,
        ])->assertCreated();

        ManufacturingCostRate::factory()->forProduct($product)->type(ManufacturingCostType::Labor)->rate('1.000')->create();

        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->id,
            'product_variant_id' => $variant->id,
            'quantity' => '40',
        ]);

        $this->enterPrinting($headers, $order, $warehouse);
        $order->refresh();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Shortage->value,
            'fields' => ["shortage_{$item->id}" => 5],
        ])->assertOk();

        // Act — the reprint
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Printing->value,
        ])->assertOk();

        // Assert — still only the first application
        $this->assertSame(1, ProductionCostEntry::query()->where('order_item_id', $item->id)->count());
    }
}
