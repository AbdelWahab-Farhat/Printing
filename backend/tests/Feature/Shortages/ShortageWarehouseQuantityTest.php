<?php

declare(strict_types=1);

namespace Tests\Feature\Shortages;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Shortage\Actions\SyncShortagesFromOrder;
use App\Domain\Shortage\Models\Shortage;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Stating the weight from the shortage's own screen.
 *
 * **The person who first knows it is standing here.** A shortage cannot be declared with a weight
 * — the bags are missing, so there is nothing to put on a scale and no factor in the catalogue to
 * derive one from — and until somebody states it no arrival may be recorded, because kilograms
 * cannot be subtracted from a count of bags. That somebody is usually the buyer about to record a
 * purchase, and sending them to the order screen to unblock their own form was a detour through a
 * screen they had no other reason to open.
 *
 * **The figure still lands on the order line.** `SyncShortagesFromOrder` recomputes an order-born
 * shortage's requirement from its line on every pass, so anything written onto this row would be
 * overwritten by the next one. This is a second door onto one writer, not a second place to store
 * the answer.
 *
 * Arrange - Act - Assert throughout.
 */
class ShortageWarehouseQuantityTest extends TestCase
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
     * @param  array<int, PermissionName>  $extra
     * @return array<string, string>
     */
    private function chaser(array $extra = []): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(
            fn (PermissionName $p): string => $p->value,
            array_merge([
                PermissionName::ViewShortages,
                PermissionName::ManageShortages,
                PermissionName::RecordShortageSupplies,
            ], $extra),
        ));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * 300 bags sold by the piece off a pile the warehouse weighs, short by thirty, unweighed.
     *
     * @return array{0: Shortage, 1: OrderItem}
     */
    private function unweighed(): array
    {
        $shelf = StockItem::factory()->unit(PricingUnit::Kilogram)->create();
        $product = Product::factory()->create(['pricing_unit' => PricingUnit::Piece]);
        $variant = ProductVariant::factory()->for($product)->create(['stock_item_id' => $shelf->getKey()]);

        $order = Order::factory()->status(OrderStatus::Shortage)->create();

        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->getKey(),
            'product_variant_id' => $variant->getKey(),
            'pricing_unit' => PricingUnit::Piece,
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

        return [
            Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail(),
            $item,
        ];
    }

    // ── what the screen is told ─────────────────────────────────────────────────────────

    public function test_the_shortage_says_it_is_waiting_and_names_the_unit_it_will_use(): void
    {
        // Arrange
        $headers = $this->chaser();
        [$shortage] = $this->unweighed();

        // Act
        $response = $this->getJson("/api/v1/shortages/{$shortage->getKey()}", $headers);

        // Assert — counted in the unit it was sold in today, and «كجم» is what it will become.
        // The app draws or hides the box from this rather than deriving a fact it cannot see.
        $response->assertOk()
            ->assertJsonPath('data.unit', PricingUnit::Piece->value)
            ->assertJsonPath('data.required_quantity', '30.000')
            ->assertJsonPath('data.stock_unit', PricingUnit::Kilogram->value)
            ->assertJsonPath('data.stock_unit_label', 'كجم')
            ->assertJsonPath('data.weight_is_unknown', true);
    }

    public function test_an_ordinary_shortage_is_not_waiting_for_anything(): void
    {
        // Arrange — one unit, so there is no second figure and nothing to ask for.
        $headers = $this->chaser();
        $order = Order::factory()->status(OrderStatus::Shortage)->create();
        $item = OrderItem::factory()->for($order)->create(['quantity' => '300.000']);

        app(OrderService::class)->setShortages(
            $order->refresh(),
            [$item->getKey() => '30'],
            null,
            ShortageRevision::Declared,
        );
        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Declared);

        $shortage = Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail();

        // Act
        $response = $this->getJson("/api/v1/shortages/{$shortage->getKey()}", $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.weight_is_unknown', false);
    }

    // ── stating it ──────────────────────────────────────────────────────────────────────

    public function test_stating_the_weight_converts_the_row_and_leaves_the_invoice_alone(): void
    {
        // Arrange
        $headers = $this->chaser();
        [$shortage, $item] = $this->unweighed();

        // Act
        $response = $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        );

        // Assert — the chase is now in the unit it will be bought in.
        $response->assertOk()
            ->assertJsonPath('data.unit', PricingUnit::Kilogram->value)
            ->assertJsonPath('data.required_quantity', '12.500')
            ->assertJsonPath('data.weight_is_unknown', false);

        // **And the customer's figure is carried through untouched.** That is what makes this the
        // chaser's job rather than the order clerk's: nothing the invoice reads has moved.
        $item->refresh();

        $this->assertSame('30.000', (string) $item->shortage_quantity);
        $this->assertSame('12.500', (string) $item->shortage_warehouse_quantity);
        $this->assertSame('270.000', $item->billableQuantity());
        $this->assertSame('418.50', (string) $item->line_total);
    }

    public function test_the_purchase_that_was_refused_a_moment_ago_now_goes_through(): void
    {
        // Arrange — the whole reason the door exists.
        $headers = $this->chaser();
        [$shortage] = $this->unweighed();
        $warehouse = Warehouse::factory()->create();

        $supply = fn () => $this->postJson("/api/v1/shortages/{$shortage->getKey()}/supplies", [
            'quantity' => '12.5',
            'amount' => '760',
            'method' => PaymentMethod::Cash->value,
            'warehouse_id' => $warehouse->getKey(),
        ], $headers);

        $supply()->assertStatus(422)->assertJsonValidationErrors('quantity');

        // Act
        $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        )->assertOk();

        // Assert
        $supply()->assertCreated();
    }

    public function test_other_lines_of_the_same_order_keep_their_own_shortages(): void
    {
        // Arrange — the set is replaced wholesale, so a map naming only this line would clear
        // every other one and re-price the invoice very quietly.
        $headers = $this->chaser();
        [$shortage, $item] = $this->unweighed();

        $other = OrderItem::factory()->for($item->order)->create(['quantity' => '200.000']);

        app(OrderService::class)->setShortages($item->order->refresh(), [
            $item->getKey() => '30',
            $other->getKey() => '15',
        ]);

        // Act
        $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        )->assertOk();

        // Assert
        $this->assertSame('15.000', (string) $other->refresh()->shortage_quantity);
    }

    // ── what it refuses ─────────────────────────────────────────────────────────────────

    public function test_a_hand_written_shortage_has_no_second_unit_to_state(): void
    {
        // Arrange
        $headers = $this->chaser();
        $shortage = Shortage::factory()->create();

        // Act
        $response = $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('quantity');
    }

    public function test_a_size_counted_the_way_it_was_sold_has_one_gap_not_two(): void
    {
        // Arrange
        $headers = $this->chaser();
        $order = Order::factory()->status(OrderStatus::Shortage)->create();
        $item = OrderItem::factory()->for($order)->create(['quantity' => '300.000']);

        app(OrderService::class)->setShortages(
            $order->refresh(),
            [$item->getKey() => '30'],
            null,
            ShortageRevision::Declared,
        );
        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Declared);

        $shortage = Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail();

        // Act
        $response = $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        );

        // Assert — the caller believes a conversion is about to happen that is not.
        $response->assertStatus(422)->assertJsonValidationErrors('quantity');
    }

    public function test_a_weight_already_stated_is_corrected_on_the_order_not_here(): void
    {
        // Arrange — the conversion is only safe while the ledger is empty, which the supply gate
        // guarantees. Restating afterwards could contradict purchases already measured against it.
        $headers = $this->chaser();
        [$shortage] = $this->unweighed();

        $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        )->assertOk();

        // Act
        $response = $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '14'],
            $headers,
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('quantity');
    }

    public function test_a_reader_without_the_grant_is_refused(): void
    {
        // Arrange — `shortages.manage`, the chaser's grant. Viewing is not enough.
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewShortages->value);
        $headers = ['Authorization' => 'Bearer '.$user->createToken('t')->plainTextToken];

        [$shortage] = $this->unweighed();

        // Act
        $response = $this->patchJson(
            "/api/v1/shortages/{$shortage->getKey()}/warehouse-quantity",
            ['quantity' => '12.5'],
            $headers,
        );

        // Assert
        $response->assertForbidden();
    }
}
