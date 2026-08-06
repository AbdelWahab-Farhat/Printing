<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Warehouse stock — what is on the shelves.
 *
 * The most important tests here are the ones that assert something *cannot* be done: no request
 * of any shape sets a quantity. A balance moves because a movement explained it, and if that
 * ever stops being true the whole ledger stops meaning anything.
 *
 * Nested and scoped, so a line belonging to another warehouse is a 404 rather than someone
 * else's number.
 *
 * Arrange - Act - Assert throughout.
 */
class WarehouseStockTest extends TestCase
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
        return $this->auth(PermissionName::ViewInventory);
    }

    /** @return array<string, string> */
    private function manager(): array
    {
        return $this->auth(PermissionName::ViewInventory, PermissionName::ManageInventory);
    }

    /** @return array<string, string> */
    private function outsider(): array
    {
        return $this->auth();
    }

    // ──────────────────────────────── listing ────────────────────────────────

    public function test_a_viewer_can_list_a_warehouses_stock(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $variant = ProductVariant::factory()->size(25, 35)->create();
        WarehouseStock::factory()->quantity('1250.000')->create([
            'warehouse_id' => $warehouse->id,
            'product_variant_id' => $variant->id,
        ]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.0.quantity', '1250.000')
            ->assertJsonPath('data.0.warehouse_id', $warehouse->id)
            ->assertJsonPath('data.0.product_variant.label', '25*35')
            // The code travels with the balance, because it is what staff say out loud and
            // what the app puts on the row so a shelf can be read down a phone line.
            ->assertJsonPath('data.0.product_variant.product_code', $variant->product->code)
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [[
                    'id', 'warehouse_id', 'product_variant_id', 'quantity',
                    'low_stock_threshold', 'is_low_stock',
                    'product_variant' => ['id', 'label', 'product_id', 'product_code', 'product_name'],
                ]],
                'meta' => ['current_page', 'per_page', 'last_page', 'total'],
            ]);
    }

    public function test_the_quantity_is_rendered_as_a_string(): void
    {
        // Arrange — a shelf count is compared against a ledger, so it must survive a client's
        // JSON parser exactly as stored
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('12.500')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $quantity = $response->json('data.0.quantity');
        $this->assertIsString($quantity);
        $this->assertSame('12.500', $quantity);
    }

    public function test_listing_stock_needs_authentication(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();

        // Act
        $response = $this->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_user_granted_nothing_may_not_list_stock(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $headers = $this->outsider();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertForbidden()->assertJsonPath('status', false);
    }

    public function test_listing_the_stock_of_a_warehouse_that_does_not_exist_is_a_404(): void
    {
        // Arrange
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/warehouses/999999/stocks');

        // Assert
        $response->assertNotFound();
    }

    public function test_the_listing_shows_only_this_warehouses_lines(): void
    {
        // Arrange
        $mine = Warehouse::factory()->create();
        $theirs = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('10.000')->create(['warehouse_id' => $mine->id]);
        WarehouseStock::factory()->quantity('99.000')->create(['warehouse_id' => $theirs->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$mine->id}/stocks");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '10.000');
    }

    public function test_a_size_that_is_all_used_up_stays_as_a_line_at_zero(): void
    {
        // Arrange — its history is worth more than the tidiness of removing it
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->empty()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '0.000');
    }

    public function test_the_listing_is_paginated_and_clamps_an_absurd_per_page(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->count(20)->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?per_page=100000");

        // Assert
        $response->assertOk()
            ->assertJsonPath('meta.per_page', 100)
            ->assertJsonPath('meta.total', 20);
    }

    public function test_an_empty_warehouse_lists_nothing_rather_than_erroring(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data')->assertJsonPath('meta.total', 0);
    }

    public function test_the_listing_can_be_filtered_to_one_size(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $wanted = ProductVariant::factory()->create();
        WarehouseStock::factory()->quantity('7.000')->create([
            'warehouse_id' => $warehouse->id,
            'product_variant_id' => $wanted->id,
        ]);
        WarehouseStock::factory()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?product_variant_id={$wanted->id}");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '7.000');
    }

    public function test_the_listing_can_be_filtered_to_what_is_actually_in_stock(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('5.000')->create(['warehouse_id' => $warehouse->id]);
        WarehouseStock::factory()->empty()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?in_stock=1");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '5.000');
    }

    // ──────────────────────────────── low stock ────────────────────────────────

    public function test_a_line_at_or_below_its_threshold_is_flagged(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('500.000')->warnAt('500.000')
            ->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert — "at" counts: the threshold is the level to be warned at, not one below it
        $response->assertOk()->assertJsonPath('data.0.is_low_stock', true);
    }

    public function test_a_line_above_its_threshold_is_not_flagged(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('501.000')->warnAt('500.000')
            ->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertOk()->assertJsonPath('data.0.is_low_stock', false);
    }

    public function test_a_line_with_no_threshold_is_never_low_however_empty_it_is(): void
    {
        // Arrange — null means nobody asked to be warned, which is not the same as zero
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->empty()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.is_low_stock', false)
            ->assertJsonPath('data.0.low_stock_threshold', null);
    }

    public function test_the_low_stock_filter_returns_only_the_flagged_lines(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->quantity('10.000')->warnAt('50.000')
            ->create(['warehouse_id' => $warehouse->id]);
        WarehouseStock::factory()->quantity('900.000')->warnAt('50.000')
            ->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?low_stock=1");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.quantity', '10.000');
    }

    public function test_a_line_with_no_threshold_is_outside_the_low_stock_question_entirely(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        WarehouseStock::factory()->empty()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act — it must appear in neither answer, rather than being swept into "not low"
        $low = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?low_stock=1");
        $notLow = $this->withHeaders($headers)->getJson("/api/v1/warehouses/{$warehouse->id}/stocks?low_stock=0");

        // Assert
        $low->assertOk()->assertJsonCount(0, 'data');
        $notLow->assertOk()->assertJsonCount(0, 'data');
    }

    // ──────────────────────────────── the threshold ────────────────────────────────

    public function test_a_manager_can_set_a_low_stock_threshold(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->quantity('1000.000')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => 250],
        );

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('message', 'تم تحديث حد التنبيه بنجاح')
            ->assertJsonPath('data.low_stock_threshold', '250.000')
            ->assertJsonPath('data.is_low_stock', false);

        $this->assertDatabaseHas('warehouse_stocks', [
            'id' => $stock->id,
            'low_stock_threshold' => '250.000',
        ]);
    }

    public function test_sending_null_clears_the_threshold(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->warnAt('250.000')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => null],
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.low_stock_threshold', null);
        $this->assertDatabaseHas('warehouse_stocks', [
            'id' => $stock->id,
            'low_stock_threshold' => null,
        ]);
    }

    public function test_a_threshold_of_zero_is_kept_rather_than_treated_as_cleared(): void
    {
        // Arrange — "warn me when this reaches nothing" is a real thing to ask for
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->quantity('5.000')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => 0],
        );

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.low_stock_threshold', '0.000')
            ->assertJsonPath('data.is_low_stock', false);
    }

    public function test_the_threshold_field_must_be_present(): void
    {
        // Arrange — clearing the warning is an explicit act, not an omission
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold", []);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('status', false)
            ->assertJsonStructure(['status', 'message', 'errors' => ['low_stock_threshold']]);
    }

    public function test_a_negative_threshold_is_refused(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => -1],
        );

        // Assert
        $response->assertStatus(422)
            ->assertJsonStructure(['errors' => ['low_stock_threshold']]);
    }

    public function test_a_viewer_may_not_set_a_threshold(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => 250],
        );

        // Assert
        $response->assertForbidden();
        $this->assertDatabaseHas('warehouse_stocks', [
            'id' => $stock->id,
            'low_stock_threshold' => null,
        ]);
    }

    public function test_another_warehouses_stock_line_is_a_404_not_someone_elses_number(): void
    {
        // Arrange — `scoped()` is what makes this a 404 by construction rather than by a check
        // somebody has to remember
        $mine = Warehouse::factory()->create();
        $theirs = Warehouse::factory()->create();
        $theirStock = WarehouseStock::factory()->create(['warehouse_id' => $theirs->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$mine->id}/stocks/{$theirStock->id}/threshold",
            ['low_stock_threshold' => 999],
        );

        // Assert — refused, and their record verified untouched
        $response->assertNotFound();
        $this->assertDatabaseHas('warehouse_stocks', [
            'id' => $theirStock->id,
            'low_stock_threshold' => null,
        ]);
    }

    // ──────────────────── the quantity is not writable ────────────────────

    public function test_there_is_no_endpoint_that_replaces_a_stock_line(): void
    {
        // Arrange — a balance moves only because a movement explained it
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->quantity('100.000')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->putJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}",
            ['quantity' => '999999.000'],
        );

        // Assert — no such route exists at all
        $response->assertNotFound();
        $this->assertDatabaseHas('warehouse_stocks', ['id' => $stock->id, 'quantity' => '100.000']);
    }

    public function test_the_threshold_endpoint_ignores_a_quantity_smuggled_into_the_body(): void
    {
        // Arrange
        $warehouse = Warehouse::factory()->create();
        $stock = WarehouseStock::factory()->quantity('100.000')->create(['warehouse_id' => $warehouse->id]);
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->patchJson(
            "/api/v1/warehouses/{$warehouse->id}/stocks/{$stock->id}/threshold",
            ['low_stock_threshold' => 10, 'quantity' => '999999.000'],
        );

        // Assert — the threshold moves, the shelf does not
        $response->assertOk()->assertJsonPath('data.quantity', '100.000');
        $this->assertDatabaseHas('warehouse_stocks', ['id' => $stock->id, 'quantity' => '100.000']);
    }

    public function test_there_is_no_endpoint_that_creates_a_stock_line_directly(): void
    {
        // Arrange — a line appears the first time a movement puts something on that shelf
        $warehouse = Warehouse::factory()->create();
        $variant = ProductVariant::factory()->create();
        $headers = $this->manager();

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/warehouses/{$warehouse->id}/stocks", [
            'product_variant_id' => $variant->id,
            'quantity' => '500.000',
        ]);

        // Assert
        $response->assertNotFound();
        $this->assertDatabaseCount('warehouse_stocks', 0);
    }
}
