<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\PurchaseOrder\Actions\SendPurchaseOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNeedsAtLeastOneItem;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Purchase orders — stock ordered from a vendor ahead of it arriving: `new → arrived →
 * completed`, with `cancelled` reachable from either open status.
 *
 * Drafting, editing, sending and cancelling are guarded by `purchase_orders.*`; receiving a
 * shipment against one is guarded by `inventory.*` instead, the same pair `stock-arrivals`
 * already sits behind — several tests below exist specifically to pin that split down.
 *
 * The receiving tests assert the document, the order's own line quantities and status, the
 * ledger row each line produced, and the balance it left behind together — asserting only one of
 * those would miss the failure mode this feature exists to prevent, the same reasoning
 * `StockArrivalTest` documents for a plain arrival.
 *
 * Arrange - Act - Assert throughout.
 */
class PurchaseOrderTest extends TestCase
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
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function viewer(): array
    {
        return $this->auth(PermissionName::ViewPurchaseOrders);
    }

    /** @return array<string, string> */
    private function manager(): array
    {
        return $this->auth(PermissionName::ViewPurchaseOrders, PermissionName::ManagePurchaseOrders);
    }

    /** @return array<string, string> */
    private function inventoryManager(): array
    {
        return $this->auth(PermissionName::ViewInventory, PermissionName::ManageInventory);
    }

    /** Authenticated, but granted nothing at all. @return array<string, string> */
    private function outsider(): array
    {
        return $this->auth();
    }

    /**
     * Drop the resolved user from the auth guards.
     *
     * The container is reused across requests inside one test, so once a guard has
     * authenticated somebody it keeps returning them — a later request carrying a different
     * user's token would still be treated as the first. Real requests each boot a fresh
     * container; clearing the guards is what makes a test that switches users honest. Needed
     * throughout this file because most tests here genuinely need two different callers — one
     * to draft/send the order, another to receive against it.
     *
     * **Call this last, immediately before the request that needs the new identity — never
     * before building that identity's headers.** Every helper above creates a `User`, and
     * `User` (like every audited model) writes an activity-log entry on save; resolving *that*
     * entry's causer touches the guard too. Doing that after this call re-primes the guard from
     * whatever request is still bound in the container at that moment — which, outside a fresh
     * HTTP cycle, is the *previous* request — silently undoing the reset before the real request
     * ever goes out.
     */
    private function forgetAuth(): void
    {
        $this->app->get('auth')->forgetGuards();
    }

    private function variant(): ProductVariant
    {
        return ProductVariant::factory()->create();
    }

    private function stockOf(Warehouse $warehouse, ProductVariant $variant): ?WarehouseStock
    {
        return WarehouseStock::query()
            ->where('warehouse_id', $warehouse->id)
            ->where('product_variant_id', $variant->id)
            ->first();
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(Vendor $vendor, Warehouse $warehouse, ProductVariant $variant, array $overrides = []): array
    {
        return array_merge([
            'vendor_id' => $vendor->id,
            'warehouse_id' => $warehouse->id,
            'order_date' => now()->toDateString(),
            'expected_date' => now()->addWeek()->toDateString(),
            'notes' => 'دفعة أولى',
            'items' => [
                ['product_variant_id' => $variant->id, 'quantity_ordered' => 10, 'unit_cost' => 5],
            ],
        ], $overrides);
    }

    // ──────────────────────────────── listing ────────────────────────────────

    public function test_a_user_with_view_permission_can_list_purchase_orders(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        PurchaseOrder::factory()->from($vendor)->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders');

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure([
                'status', 'message',
                'data' => [['id', 'vendor_id', 'warehouse_id', 'status', 'status_label', 'order_date', 'items']],
                'meta' => ['current_page', 'per_page', 'last_page', 'total'],
            ]);
    }

    public function test_listing_purchase_orders_needs_authentication(): void
    {
        // Act
        $response = $this->getJson('/api/v1/purchase-orders');

        // Assert
        $response->assertUnauthorized()->assertJsonPath('status', false);
    }

    public function test_a_user_granted_nothing_may_not_list_purchase_orders(): void
    {
        // Arrange
        PurchaseOrder::factory()->create();
        $headers = $this->outsider();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders');

        // Assert
        $response->assertForbidden()->assertJsonPath('status', false);
    }

    public function test_the_purchase_order_list_is_paginated(): void
    {
        // Arrange
        PurchaseOrder::factory()->count(20)->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders?per_page=5&page=2');

        // Assert
        $response->assertOk()
            ->assertJsonCount(5, 'data')
            ->assertJsonPath('meta.current_page', 2)
            ->assertJsonPath('meta.total', 20);
    }

    public function test_the_list_can_be_filtered_by_vendor(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        PurchaseOrder::factory()->from($vendor)->create();
        PurchaseOrder::factory()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/purchase-orders?vendor_id={$vendor->id}");

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.vendor_id', $vendor->id);
    }

    public function test_the_list_can_be_filtered_by_warehouse(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        PurchaseOrder::factory()->into($warehouse)->create();
        PurchaseOrder::factory()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/purchase-orders?warehouse_id={$warehouse->id}");

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.warehouse_id', $warehouse->id);
    }

    public function test_the_list_can_be_filtered_by_status(): void
    {
        // Arrange
        PurchaseOrder::factory()->create();
        PurchaseOrder::factory()->cancelled()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders?status=cancelled');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.status', 'cancelled');
    }

    public function test_a_soft_deleted_purchase_order_is_absent_from_the_list(): void
    {
        // Arrange
        PurchaseOrder::factory()->create();
        PurchaseOrder::factory()->create()->delete();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
    }

    // ──────────────────────────────── reading one ────────────────────────────────

    public function test_a_viewer_can_read_one_purchase_order_with_its_items(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $created = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $viewerHeaders = $this->viewer();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($viewerHeaders)->getJson("/api/v1/purchase-orders/{$created['id']}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.id', $created['id'])
            ->assertJsonPath('data.status', 'new')
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.quantity_ordered', '10.000')
            ->assertJsonPath('data.items.0.quantity_received', '0.000')
            ->assertJsonPath('data.items.0.quantity_remaining', '10.000');
    }

    public function test_reading_a_purchase_order_that_does_not_exist_is_a_404(): void
    {
        // Arrange
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/purchase-orders/999999');

        // Assert
        $response->assertNotFound()->assertJsonPath('status', false);
    }

    // ──────────────────────────────── creating ────────────────────────────────

    public function test_a_manager_can_create_a_purchase_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        );

        // Assert
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.vendor_id', $vendor->id)
            ->assertJsonPath('data.warehouse_id', $warehouse->id)
            ->assertJsonPath('data.status', 'new')
            ->assertJsonPath('data.items.0.product_variant_id', $variant->id)
            ->assertJsonPath('data.items.0.quantity_ordered', '10.000');

        $this->assertDatabaseHas('purchase_orders', ['vendor_id' => $vendor->id, 'status' => 'new']);
        $this->assertDatabaseHas('purchase_order_items', [
            'product_variant_id' => $variant->id,
            'quantity_ordered' => '10.000',
            'quantity_received' => '0.000',
        ]);
    }

    public function test_a_viewer_may_not_create_a_purchase_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        );

        // Assert
        $response->assertForbidden();
        $this->assertDatabaseCount('purchase_orders', 0);
    }

    public function test_creating_a_purchase_order_requires_vendor_warehouse_order_date_and_items(): void
    {
        // Arrange
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', []);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('status', false)
            ->assertJsonStructure(['errors' => ['vendor_id', 'warehouse_id', 'order_date', 'items']]);
    }

    public function test_a_vendor_that_does_not_exist_is_refused(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', [
            'vendor_id' => 999999,
            'warehouse_id' => $warehouse->id,
            'order_date' => now()->toDateString(),
            'items' => [['product_variant_id' => $variant->id, 'quantity_ordered' => 10, 'unit_cost' => 5]],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['vendor_id']]);
    }

    public function test_duplicate_product_variants_in_the_items_are_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $variant,
            ['items' => [
                ['product_variant_id' => $variant->id, 'quantity_ordered' => 5, 'unit_cost' => 5],
                ['product_variant_id' => $variant->id, 'quantity_ordered' => 3, 'unit_cost' => 5],
            ]],
        ));

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['items.0.product_variant_id']]);
    }

    // ──────────────────────────────── updating ────────────────────────────────

    public function test_a_manager_can_update_a_purchase_order_while_new(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $order = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/purchase-orders/{$order['id']}",
            $this->payload($vendor, $warehouse, $variant, ['notes' => 'ملاحظة محدثة']),
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.notes', 'ملاحظة محدثة');
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'notes' => 'ملاحظة محدثة']);
    }

    public function test_updating_syncs_items_by_id_updating_creating_and_removing(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $kept = $this->variant();
        $removed = $this->variant();
        $added = $this->variant();
        $headers = $this->manager();

        $order = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $kept,
            ['items' => [
                ['product_variant_id' => $kept->id, 'quantity_ordered' => 10, 'unit_cost' => 5],
                ['product_variant_id' => $removed->id, 'quantity_ordered' => 4, 'unit_cost' => 5],
            ]],
        ))->json('data');

        $keptItemId = collect($order['items'])->firstWhere('product_variant_id', $kept->id)['id'];

        // Act — kept item's quantity changes, removed item is dropped, added item is new
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/purchase-orders/{$order['id']}",
            $this->payload($vendor, $warehouse, $kept, ['items' => [
                ['id' => $keptItemId, 'product_variant_id' => $kept->id, 'quantity_ordered' => 20, 'unit_cost' => 5],
                ['product_variant_id' => $added->id, 'quantity_ordered' => 7, 'unit_cost' => 5],
            ]]),
        );

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data.items');
        $this->assertDatabaseHas('purchase_order_items', ['id' => $keptItemId, 'quantity_ordered' => '20.000']);
        $this->assertDatabaseHas('purchase_order_items', [
            'purchase_order_id' => $order['id'], 'product_variant_id' => $added->id, 'quantity_ordered' => '7.000',
        ]);
        $this->assertSoftDeleted('purchase_order_items', ['purchase_order_id' => $order['id'], 'product_variant_id' => $removed->id]);
    }

    public function test_updating_a_purchase_order_is_refused_once_it_has_arrived(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $order = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $this->withHeaders($headers)->patchJson("/api/v1/purchase-orders/{$order['id']}/status", ['status' => 'arrived']);

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/purchase-orders/{$order['id']}",
            $this->payload($vendor, $warehouse, $variant, ['notes' => 'محاولة تعديل']),
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('status', false);
        $this->assertDatabaseMissing('purchase_orders', ['id' => $order['id'], 'notes' => 'محاولة تعديل']);
    }

    public function test_a_viewer_may_not_update_a_purchase_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = PurchaseOrder::factory()->from($vendor)->into($warehouse)->create();

        // Act
        $response = $this->withHeaders($this->viewer())->putJson(
            "/api/v1/purchase-orders/{$order->id}",
            $this->payload($vendor, $warehouse, $variant),
        );

        // Assert
        $response->assertForbidden();
    }

    // ──────────────────────────────── status changes ────────────────────────────────

    public function test_a_manager_can_send_a_purchase_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $order = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order['id']}/status",
            ['status' => 'arrived'],
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'arrived');
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'status' => 'arrived']);
    }

    public function test_sending_a_purchase_order_twice_is_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $order = $this->withHeaders($headers)->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $this->withHeaders($headers)->patchJson("/api/v1/purchase-orders/{$order['id']}/status", ['status' => 'arrived']);

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order['id']}/status",
            ['status' => 'arrived'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('status', false);
    }

    public function test_sending_a_purchase_order_with_no_items_is_refused(): void
    {
        // Arrange — unreachable through the HTTP API (creating and updating both require at
        // least one item), so this exercises the domain guard directly, the same way
        // ErrorHandlingTest calls SyncCustomerShops directly to reach a state the API cannot
        // produce.
        $order = PurchaseOrder::factory()->create();
        $send = app(SendPurchaseOrder::class);

        // Assert
        $this->expectException(PurchaseOrderNeedsAtLeastOneItem::class);

        // Act
        $send($order);
    }

    public function test_the_status_endpoint_rejects_completed_as_a_manual_target(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order->id}/status",
            ['status' => 'completed'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['status']]);
    }

    public function test_a_manager_can_cancel_a_new_purchase_order(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order->id}/status",
            ['status' => 'cancelled'],
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'cancelled');
    }

    public function test_a_manager_can_cancel_an_arrived_purchase_order(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->arrived()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order->id}/status",
            ['status' => 'cancelled'],
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'cancelled');
    }

    public function test_cancelling_a_completed_purchase_order_is_refused(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->completed()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order->id}/status",
            ['status' => 'cancelled'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('status', false);
    }

    public function test_a_viewer_may_not_change_a_purchase_orders_status(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/purchase-orders/{$order->id}/status",
            ['status' => 'arrived'],
        );

        // Assert
        $response->assertForbidden();
    }

    // ──────────────────────────────── receiving ────────────────────────────────

    public function test_an_inventory_manager_can_fully_receive_a_new_purchase_order_in_one_shipment(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $inventoryHeaders = $this->inventoryManager();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($inventoryHeaders)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['invoice_number' => 'INV-2001', 'items' => [
                ['product_variant_id' => $variant->id, 'quantity' => 10],
            ]],
        );

        // Assert — the document …
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.vendor_id', $vendor->id)
            ->assertJsonPath('data.warehouse_id', $warehouse->id)
            ->assertJsonPath('data.purchase_order_id', $order['id'])
            ->assertJsonPath('data.invoice_number', 'INV-2001');

        // … the order itself, now fully received and completed …
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'status' => 'completed']);
        $this->assertDatabaseHas('purchase_order_items', [
            'purchase_order_id' => $order['id'],
            'product_variant_id' => $variant->id,
            'quantity_received' => '10.000',
        ]);

        // … the ledger row it produced …
        $arrivalId = $response->json('data.id');
        $this->assertDatabaseHas('stock_movements', [
            'product_variant_id' => $variant->id,
            'to_warehouse_id' => $warehouse->id,
            'quantity' => '10.000',
            'movement_type' => 'purchase_arrival',
            'reference_id' => $arrivalId,
        ]);

        // … and the balance it left behind
        $this->assertSame('10.000', (string) $this->stockOf($warehouse, $variant)?->quantity);
    }

    public function test_receiving_less_than_ordered_moves_the_order_to_arrived(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $inventoryHeaders = $this->inventoryManager();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($inventoryHeaders)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 4]]],
        );

        // Assert
        $response->assertCreated();
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'status' => 'arrived']);
        $this->assertDatabaseHas('purchase_order_items', [
            'purchase_order_id' => $order['id'], 'product_variant_id' => $variant->id, 'quantity_received' => '4.000',
        ]);
    }

    public function test_receiving_the_remainder_completes_the_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->inventoryManager();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $this->forgetAuth();
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 4]]],
        );

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 6]]],
        );

        // Assert
        $response->assertCreated();
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'status' => 'completed']);
        $this->assertDatabaseHas('purchase_order_items', [
            'purchase_order_id' => $order['id'], 'product_variant_id' => $variant->id, 'quantity_received' => '10.000',
        ]);
        $this->assertDatabaseCount('stock_arrivals', 2);
        $this->assertDatabaseCount('stock_movements', 2);
        $this->assertSame('10.000', (string) $this->stockOf($warehouse, $variant)?->quantity);
    }

    public function test_receiving_needs_authentication(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->create();

        // Act
        $response = $this->postJson("/api/v1/purchase-orders/{$order->id}/arrivals", []);

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_purchase_orders_manager_without_inventory_permission_may_not_receive_a_shipment(): void
    {
        // Arrange — purchase_orders.manage alone is deliberately not enough; see the class docblock.
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $secondManagerHeaders = $this->manager();
        $this->forgetAuth();

        // Act — purchase_orders.manage alone, no inventory.manage
        $response = $this->withHeaders($secondManagerHeaders)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 10]]],
        );

        // Assert
        $response->assertForbidden();
        $this->assertDatabaseCount('stock_arrivals', 0);
    }

    public function test_over_receiving_is_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $inventoryHeaders = $this->inventoryManager();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($inventoryHeaders)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 15]]],
        );

        // Assert — refused, and nothing partially lands
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['items']]);
        $this->assertDatabaseCount('stock_arrivals', 0);
        $this->assertDatabaseCount('stock_movements', 0);
        $this->assertDatabaseHas('purchase_order_items', [
            'purchase_order_id' => $order['id'], 'product_variant_id' => $variant->id, 'quantity_received' => '0.000',
        ]);
    }

    public function test_receiving_an_unordered_variant_is_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $ordered = $this->variant();
        $notOrdered = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $ordered),
        )->json('data');
        $inventoryHeaders = $this->inventoryManager();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($inventoryHeaders)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $notOrdered->id, 'quantity' => 1]]],
        );

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['items']]);
        $this->assertDatabaseCount('stock_arrivals', 0);
    }

    public function test_receiving_against_a_completed_purchase_order_is_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->inventoryManager();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');
        $this->forgetAuth();
        $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 10]]],
        );

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 1]]],
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('status', false);
        $this->assertDatabaseCount('stock_arrivals', 1);
    }

    public function test_receiving_against_a_cancelled_purchase_order_is_refused(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->cancelled()->create();
        $variant = $this->variant();

        // Act
        $response = $this->withHeaders($this->inventoryManager())->postJson(
            "/api/v1/purchase-orders/{$order->id}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 1]]],
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('status', false);
        $this->assertDatabaseCount('stock_arrivals', 0);
    }

    public function test_received_by_is_stamped_from_the_authenticated_user(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson(
            '/api/v1/purchase-orders',
            $this->payload($vendor, $warehouse, $variant),
        )->json('data');

        $user = User::factory()->create();
        $user->givePermissionTo([PermissionName::ViewInventory->value, PermissionName::ManageInventory->value]);
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 10]]],
        );

        // Assert — never accepted from the body, always the caller
        $response->assertCreated()->assertJsonPath('data.received_by', $user->id);
    }

    // ──────────────────────────────── cost & unit tracking ────────────────────────────────

    public function test_creating_a_purchase_order_computes_line_and_order_totals(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variantA = $this->variant();
        $variantB = $this->variant();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $variantA,
            ['items' => [
                ['product_variant_id' => $variantA->id, 'quantity_ordered' => 10, 'unit_cost' => 2.5],
                ['product_variant_id' => $variantB->id, 'quantity_ordered' => 4, 'unit_cost' => 3],
            ]],
        ));

        // Assert — 10 * 2.5 = 25.00, 4 * 3 = 12.00, order total = 37.00
        $response->assertCreated()
            ->assertJsonPath('data.items.0.unit_cost', '2.500')
            ->assertJsonPath('data.items.0.total_cost', '25.00')
            ->assertJsonPath('data.items.0.unit', 'piece')
            ->assertJsonPath('data.items.1.total_cost', '12.00')
            ->assertJsonPath('data.total_amount', '37.00');

        $this->assertDatabaseHas('purchase_order_items', [
            'product_variant_id' => $variantA->id, 'unit_cost' => '2.500', 'total_cost' => '25.00', 'unit' => 'piece',
        ]);
    }

    public function test_updating_a_purchase_order_recomputes_totals_after_syncing_items(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();
        $order = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $variant,
            ['items' => [['product_variant_id' => $variant->id, 'quantity_ordered' => 10, 'unit_cost' => 2]]],
        ))->json('data');

        // Act — same line, different cost: 10 * 8 = 80.00
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/purchase-orders/{$order['id']}",
            $this->payload($vendor, $warehouse, $variant, ['items' => [
                ['id' => $order['items'][0]['id'], 'product_variant_id' => $variant->id, 'quantity_ordered' => 10, 'unit_cost' => 8],
            ]]),
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.total_amount', '80.00');
        $this->assertDatabaseHas('purchase_orders', ['id' => $order['id'], 'total_amount' => '80.00']);
    }

    public function test_unit_cost_is_required_to_create_a_purchase_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $headers = $this->manager();

        // Act — items entry deliberately omits unit_cost
        $response = $this->withHeaders($headers)->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $variant,
            ['items' => [['product_variant_id' => $variant->id, 'quantity_ordered' => 10]]],
        ));

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['items.0.unit_cost']]);
    }

    public function test_receiving_a_shipment_carries_cost_onto_the_stock_arrival_item(): void
    {
        // Arrange — order 10 at 4.00 each; only 6 arrive in this shipment
        $vendor = Vendor::factory()->create();
        $warehouse = Warehouse::factory()->create();
        $variant = $this->variant();
        $order = $this->withHeaders($this->manager())->postJson('/api/v1/purchase-orders', $this->payload(
            $vendor,
            $warehouse,
            $variant,
            ['items' => [['product_variant_id' => $variant->id, 'quantity_ordered' => 10, 'unit_cost' => 4]]],
        ))->json('data');
        $headers = $this->inventoryManager();
        $this->forgetAuth();

        // Act
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/purchase-orders/{$order['id']}/arrivals",
            ['items' => [['product_variant_id' => $variant->id, 'quantity' => 6]]],
        );

        // Assert — priced against what actually arrived (6 * 4.00 = 24.00), not the order line's
        // own total_cost (10 * 4.00 = 40.00)
        $response->assertCreated()
            ->assertJsonPath('data.items.0.unit_cost', '4.000')
            ->assertJsonPath('data.items.0.total_cost', '24.00');

        $this->assertDatabaseHas('stock_arrival_items', [
            'product_variant_id' => $variant->id, 'unit_cost' => '4.000', 'total_cost' => '24.00',
        ]);
    }

    public function test_a_plain_stock_arrival_never_carries_cost(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $vendor = Vendor::factory()->create();
        $variant = $this->variant();

        // Act — the generic endpoint, not raised against a purchase order
        $response = $this->withHeaders($this->inventoryManager())->postJson('/api/v1/stock-arrivals', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => $warehouse->id,
            'items' => [['product_variant_id' => $variant->id, 'quantity' => 10]],
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.items.0.unit_cost', null)
            ->assertJsonPath('data.items.0.total_cost', null);
    }
}
