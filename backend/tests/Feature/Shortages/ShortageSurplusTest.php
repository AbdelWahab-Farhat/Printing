<?php

declare(strict_types=1);

namespace Tests\Feature\Shortages;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Shortage\Actions\SyncShortagesFromOrder;
use App\Domain\Shortage\Enums\ShortageStatus;
use App\Domain\Shortage\Models\Shortage;
use App\Domain\Shortage\Models\ShortageSupply;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * A supply bigger than what was missing: the whole sack on the shelf, only the shortage's share
 * counted toward it, and the rest company stock.
 *
 * **The test that guards the arithmetic is {@see test_the_next_sync_does_not_grow_the_requirement()}.**
 * The sync restates `required = missing + Σ supplied`, so a surplus that leaked into "supplied"
 * would raise the requirement by exactly the extra and reopen a shortage that was met.
 *
 * Arrange - Act - Assert throughout.
 */
class ShortageSurplusTest extends TestCase
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
     * @return array{0: array<string, string>, 1: User}
     */
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewShortages->value,
            PermissionName::ManageShortages->value,
            PermissionName::RecordShortageSupplies->value,
            PermissionName::ReverseShortageSupplies->value,
        ]);

        return [['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken], $user];
    }

    /**
     * An order short of 30 of the 300 it ordered, with its shortage already mirrored.
     *
     * @return array{0: Order, 1: OrderItem, 2: Shortage}
     */
    private function shortOrder(): array
    {
        $order = Order::factory()->status(OrderStatus::Shortage)->create();

        $item = OrderItem::factory()->for($order)->create([
            'quantity' => '300.000',
            'unit_price' => '1.550',
            'line_total' => '465.00',
        ]);

        app(OrderService::class)->setShortages(
            $order->refresh(),
            [$item->getKey() => '30'],
            null,
            ShortageRevision::Declared,
        );

        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Declared);

        $shortage = Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail();

        return [$order->refresh(), $item, $shortage];
    }

    private function shelfFor(OrderItem $item): int
    {
        return (int) ProductVariant::query()
            ->whereKey($item->product_variant_id)
            ->value('stock_item_id');
    }

    private function balance(Warehouse $warehouse, OrderItem $item): string
    {
        return (string) WarehouseStock::query()
            ->where('warehouse_id', $warehouse->getKey())
            ->where('stock_item_id', $this->shelfFor($item))
            ->value('quantity');
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function supply(Shortage $shortage, array $headers, string $quantity, string $amount, array $extra = []): TestResponse
    {
        return $this->postJson("/api/v1/shortages/{$shortage->getKey()}/supplies", [
            'quantity' => $quantity,
            'amount' => $amount,
            'method' => PaymentMethod::Cash->value,
            ...$extra,
        ], $headers);
    }

    // ── the refusals ────────────────────────────────────────────────────────────────────

    public function test_more_than_is_missing_is_refused_without_the_confirmation(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        // Act
        $response = $this->supply($shortage, $headers, '40', '1000', ['warehouse_id' => $warehouse->getKey()]);

        // Assert — the keystroke the cap has always caught, and nothing moved.
        $response->assertStatus(422)->assertJsonValidationErrors('quantity');
        $this->assertStringContainsString('10.000', (string) $response->json('errors.quantity.0'));
        $this->assertSame('0.000', (string) $shortage->refresh()->supplied_quantity);
        $this->assertSame(0, StockMovement::query()->count());
        $this->assertSame('', $this->balance($warehouse, $item));
    }

    public function test_a_shortage_with_no_shelf_refuses_the_extra_even_when_confirmed(): void
    {
        // Arrange — «شريط لاصق عريض»: no product, so nowhere for the extra to go.
        [$headers] = $this->clerk();
        $shortage = Shortage::factory()->create(['required_quantity' => '12.000']);

        // Act
        $response = $this->supply($shortage, $headers, '15', '60', ['accept_surplus' => true]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('quantity');
        $this->assertSame(0, ShortageSupply::query()->count());
    }

    public function test_an_exact_supply_carries_no_surplus(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, , $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        // Act — the confirmation is harmless when nothing is extra.
        $response = $this->supply($shortage, $headers, '30', '760', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.surplus_quantity', '0.000');
        $shortage->refresh();
        $this->assertSame('30.000', (string) $shortage->supplied_quantity);
        $this->assertSame('0.000', (string) $shortage->surplus_quantity);
        $this->assertSame('0.00', (string) $shortage->surplus_value);
    }

    // ── the surplus ─────────────────────────────────────────────────────────────────────

    public function test_the_whole_sack_reaches_the_shelf_and_the_shortage_counts_its_share(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        // Act — forty bought against thirty missing.
        $response = $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ]);

        // Assert — the supply row keeps what arrived and names the extra.
        $response->assertCreated()
            ->assertJsonPath('data.quantity', '40.000')
            ->assertJsonPath('data.surplus_quantity', '10.000')
            ->assertJsonPath('data.moved_stock', true);

        // All forty on the shelf, as one arrival at one price.
        $this->assertSame('40.000', $this->balance($warehouse, $item));
        $movement = StockMovement::query()->whereKey($response->json('data.stock_movement_id'))->firstOrFail();
        $this->assertSame('40.000', (string) $movement->quantity);
        $this->assertStringContainsString('10.000', (string) $movement->notes);

        // The shortage counts thirty, closes, and says what went to the shelf and for how much.
        $shortage->refresh();
        $this->assertSame('30.000', (string) $shortage->required_quantity);
        $this->assertSame('30.000', (string) $shortage->supplied_quantity);
        $this->assertSame('0.000', $shortage->remainingQuantity());
        $this->assertSame(ShortageStatus::Completed, $shortage->status);
        $this->assertSame('10.000', (string) $shortage->surplus_quantity);
        $this->assertSame('1000.00', (string) $shortage->total_paid, 'the whole payment, not its share');
        $this->assertSame('250.00', (string) $shortage->surplus_value, '1000 × 10 ÷ 40');
    }

    public function test_the_order_line_is_credited_for_what_was_missing_only(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        // Act
        $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ])->assertCreated();

        // Assert — billed for the 300 ordered, never for the extra ten.
        $item->refresh();
        $this->assertNull($item->shortage_quantity);
        $this->assertSame('300.000', $item->billableQuantity());
    }

    public function test_the_next_sync_does_not_grow_the_requirement(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [$order, , $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ])->assertCreated();

        // Act — the order screen saves again, which restates the shortage from the line.
        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Corrected);

        // Assert
        $shortage->refresh();
        $this->assertSame('30.000', (string) $shortage->required_quantity);
        $this->assertSame('30.000', (string) $shortage->supplied_quantity);
        $this->assertSame(ShortageStatus::Completed, $shortage->status);
    }

    public function test_the_surplus_is_measured_against_what_is_left_not_what_was_missing(): void
    {
        // Arrange — twenty of the thirty already bought.
        [$headers] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        $this->supply($shortage, $headers, '20', '500', ['warehouse_id' => $warehouse->getKey()])->assertCreated();

        // Act — another twenty against the ten still missing.
        $response = $this->supply($shortage, $headers, '20', '500', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.surplus_quantity', '10.000');
        $shortage->refresh();
        $this->assertSame('30.000', (string) $shortage->supplied_quantity);
        $this->assertSame('10.000', (string) $shortage->surplus_quantity);
        $this->assertSame('1000.00', (string) $shortage->total_paid);
        $this->assertSame('250.00', (string) $shortage->surplus_value);
        $this->assertSame('40.000', $this->balance($warehouse, $item));
    }

    public function test_the_confirmation_arrives_as_a_string_from_a_multipart_form(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, , $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        // Act — what `FormData` sends whenever a receipt rides along.
        $response = $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => 'true',
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.surplus_quantity', '10.000');
    }

    public function test_a_locked_order_takes_the_surplus_and_keeps_its_invoice(): void
    {
        // Arrange — the order has moved past the point its lines can change.
        [$headers] = $this->clerk();
        [$order, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        DB::table('orders')->where('id', $order->getKey())->update(['status' => OrderStatus::Ready->value]);

        // Act
        $response = $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ]);

        // Assert — the stock and the shortage move; the invoice does not.
        $response->assertCreated()->assertJsonPath('data.surplus_quantity', '10.000');
        $this->assertSame('40.000', $this->balance($warehouse, $item));
        $this->assertSame(ShortageStatus::Completed, $shortage->refresh()->status);
        $this->assertSame('30.000', (string) $item->refresh()->shortage_quantity);
    }

    // ── the reversal ────────────────────────────────────────────────────────────────────

    public function test_reversing_a_surplus_supply_takes_the_whole_sack_back(): void
    {
        // Arrange
        [$headers] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        $supplyId = $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ])->assertCreated()->json('data.id');

        // Act
        $this->postJson(
            "/api/v1/shortages/{$shortage->getKey()}/supplies/{$supplyId}/reversal",
            ['reason' => 'أُدخلت خطأ'],
            $headers,
        )->assertCreated();

        // Assert — all forty off the shelf, and the shortage back where it started.
        $this->assertSame('0.000', $this->balance($warehouse, $item));

        $shortage->refresh();
        $this->assertSame('0.000', (string) $shortage->supplied_quantity);
        $this->assertSame('0.000', (string) $shortage->surplus_quantity);
        $this->assertSame('0.00', (string) $shortage->total_paid);
        $this->assertSame('0.00', (string) $shortage->surplus_value);
        $this->assertSame('30.000', $shortage->remainingQuantity());
        $this->assertNotSame(ShortageStatus::Completed, $shortage->status);
    }

    public function test_a_surplus_already_drawn_by_another_order_cannot_be_reversed(): void
    {
        // Arrange — the forty arrive, and twenty-five of them leave for somebody else's order.
        [$headers, $user] = $this->clerk();
        [, $item, $shortage] = $this->shortOrder();
        $warehouse = Warehouse::factory()->create();

        $supplyId = $this->supply($shortage, $headers, '40', '1000', [
            'warehouse_id' => $warehouse->getKey(),
            'accept_surplus' => true,
        ])->assertCreated()->json('data.id');

        app(InventoryService::class)->recordMovement(StockMovementData::fulfillment([
            'stock_item_id' => $this->shelfFor($item),
            'quantity' => '25',
            'from_warehouse_id' => $warehouse->getKey(),
        ], (int) $user->getKey()));

        // Act
        $response = $this->postJson(
            "/api/v1/shortages/{$shortage->getKey()}/supplies/{$supplyId}/reversal",
            ['reason' => 'أُدخلت خطأ'],
            $headers,
        );

        // Assert — refused, and the ledger stands as it was.
        $response->assertStatus(422);
        $this->assertSame('15.000', $this->balance($warehouse, $item));
        $this->assertSame('30.000', (string) $shortage->refresh()->supplied_quantity);
        $this->assertSame(1, ShortageSupply::query()->count());
    }
}
