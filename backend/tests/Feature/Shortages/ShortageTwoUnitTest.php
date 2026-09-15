<?php

declare(strict_types=1);

namespace Tests\Feature\Shortages;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\DTOs\LineShortage;
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
 * A shortage is chased in the warehouse's unit and billed in the customer's.
 *
 * **The two numbers are different facts about one gap, and neither can be computed from the
 * other.** The customer is short thirty bags and is billed for thirty fewer at the per-bag price;
 * the shop must buy the twelve and a half kilograms those bags are made of, put them on a shelf
 * counted in kilograms, and open a cost layer priced per kilogram. There is no قطعة→كجم factor in
 * the catalogue and deliberately none — bags weighed together have no per-bag weight — so the
 * pair is stated once, by the person declaring the shortage.
 *
 * Before this, «النواقص» showed the invoice's number to a buyer whose supplier sells by weight,
 * and the arrival posted that count straight into a balance of kilograms.
 *
 * Arrange - Act - Assert throughout.
 */
class ShortageTwoUnitTest extends TestCase
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
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewShortages->value,
            PermissionName::ManageShortages->value,
            PermissionName::RecordShortageSupplies->value,
            PermissionName::ReverseShortageSupplies->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * 300 bags sold by the piece, off a pile the warehouse weighs.
     *
     * @return array{0: Order, 1: OrderItem, 2: StockItem}
     */
    private function soldByThePieceStockedByTheKilo(): array
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

        return [$order, $item, $shelf];
    }

    /** «ناقص ٣٠ قطعة، وهي ١٢٫٥ كجم» — the pair, declared and mirrored. */
    private function declare(Order $order, OrderItem $item): Shortage
    {
        app(OrderService::class)->setShortages(
            $order->refresh(),
            [$item->getKey() => new LineShortage('30', '12.5')],
            null,
            ShortageRevision::Declared,
        );

        app(SyncShortagesFromOrder::class)((int) $order->getKey(), ShortageRevision::Declared);

        return Shortage::query()->where('order_item_id', $item->getKey())->firstOrFail();
    }

    // ── what each side is denominated in ────────────────────────────────────────────────

    public function test_the_section_chases_the_warehouses_unit_and_the_line_bills_the_customers(): void
    {
        // Arrange
        $headers = $this->clerk();
        [$order, $item] = $this->soldByThePieceStockedByTheKilo();

        // Act
        $shortage = $this->declare($order, $item);
        $response = $this->getJson("/api/v1/shortages/{$shortage->getKey()}", $headers);

        // Assert — the chase is in كجم, because that is what will be bought and shelved.
        $response->assertOk()
            ->assertJsonPath('data.unit', PricingUnit::Kilogram->value)
            ->assertJsonPath('data.unit_label', 'كجم')
            ->assertJsonPath('data.required_quantity', '12.500')
            ->assertJsonPath('data.remaining_quantity', '12.500');

        // And the invoice is untouched by any of it: 270 of 300 bags at 1.550.
        $item->refresh();

        $this->assertSame('30.000', (string) $item->shortage_quantity);
        $this->assertSame('12.500', (string) $item->shortage_warehouse_quantity);
        $this->assertSame('270.000', $item->billableQuantity());
        $this->assertSame('418.50', (string) $item->line_total);
    }

    public function test_a_size_stocked_in_its_own_unit_still_needs_only_one_number(): void
    {
        // Arrange — the ordinary case, and the shape every caller used before the pair existed.
        $headers = $this->clerk();
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

        // Assert — one gap, not two: the weight column stays null and reads as «the same number».
        $response->assertOk()->assertJsonPath('data.required_quantity', '30.000');
        $this->assertNull($item->refresh()->shortage_warehouse_quantity);
    }

    // ── the purchase ───────────────────────────────────────────────────────────────────

    public function test_the_whole_purchase_lands_on_the_shelf_in_kilos_and_clears_the_invoice(): void
    {
        // Arrange
        $headers = $this->clerk();
        [$order, $item, $shelf] = $this->soldByThePieceStockedByTheKilo();
        $shortage = $this->declare($order, $item);
        $warehouse = Warehouse::factory()->create();

        // Act — the buyer records what they bought, in the unit they bought it in. One number.
        $response = $this->postJson("/api/v1/shortages/{$shortage->getKey()}/supplies", [
            'quantity' => '12.5',
            'amount' => '760',
            'method' => PaymentMethod::Cash->value,
            'warehouse_id' => $warehouse->getKey(),
        ], $headers);

        // Assert
        $response->assertCreated()->assertJsonPath('data.quantity', '12.500');

        $balance = WarehouseStock::query()
            ->where('warehouse_id', $warehouse->getKey())
            ->where('stock_item_id', $shelf->getKey())
            ->value('quantity');

        // **The assertion the change is for.** This read 30.000 before — a tally of bags added to
        // a balance of kilograms.
        $this->assertSame('12.500', (string) $balance);

        // 760 ÷ 12.5 = 60.800 per kilogram, the unit the layer is actually held in.
        $batch = StockBatch::query()
            ->where('stock_item_id', $shelf->getKey())
            ->where('warehouse_id', $warehouse->getKey())
            ->firstOrFail();

        $this->assertSame('60.800', (string) $batch->unit_cost);

        // And the customer is billed for all 300 again — exact, because everything arrived.
        $item->refresh();

        $this->assertNull($item->shortage_quantity);
        $this->assertNull($item->shortage_warehouse_quantity);
        $this->assertSame('300.000', $item->billableQuantity());
        $this->assertSame('465.00', (string) $item->line_total);
    }

    public function test_a_partial_purchase_credits_the_invoice_pro_rata(): void
    {
        // Arrange
        $headers = $this->clerk();
        [$order, $item] = $this->soldByThePieceStockedByTheKilo();
        $shortage = $this->declare($order, $item);
        $warehouse = Warehouse::factory()->create();

        // Act — half the weight came back.
        $this->postJson("/api/v1/shortages/{$shortage->getKey()}/supplies", [
            'quantity' => '6.25',
            'amount' => '380',
            'method' => PaymentMethod::Cash->value,
            'warehouse_id' => $warehouse->getKey(),
        ], $headers)->assertCreated();

        // Assert — half the kilograms is half the bags, apportioned from the pair the shortage
        // was declared with. There is no other bridge between the two units.
        $item->refresh();

        $this->assertSame('15.000', (string) $item->shortage_quantity);
        $this->assertSame('6.250', (string) $item->shortage_warehouse_quantity);
        $this->assertSame('285.000', $item->billableQuantity());

        // The chase keeps its own unit and its own arithmetic.
        $shortage->refresh();

        $this->assertSame('12.500', (string) $shortage->required_quantity);
        $this->assertSame('6.250', (string) $shortage->supplied_quantity);
        $this->assertSame('6.250', $shortage->remainingQuantity());
    }

    public function test_the_ratio_survives_a_second_partial_and_lands_exactly_on_zero(): void
    {
        // Arrange — the property that makes apportionment safe to repeat: crediting half the
        // kilograms leaves half the bags *and* half the kilograms, so the rate never drifts.
        $headers = $this->clerk();
        [$order, $item] = $this->soldByThePieceStockedByTheKilo();
        $shortage = $this->declare($order, $item);
        $warehouse = Warehouse::factory()->create();

        $supply = fn (string $kg, string $paid) => $this->postJson(
            "/api/v1/shortages/{$shortage->getKey()}/supplies",
            [
                'quantity' => $kg,
                'amount' => $paid,
                'method' => PaymentMethod::Cash->value,
                'warehouse_id' => $warehouse->getKey(),
            ],
            $headers,
        )->assertCreated();

        // Act
        $supply('6.25', '380');
        $supply('6.25', '380');

        // Assert — nothing left of either, and no rounding crumb on the invoice.
        $item->refresh();

        $this->assertNull($item->shortage_quantity);
        $this->assertNull($item->shortage_warehouse_quantity);
        $this->assertSame('300.000', $item->billableQuantity());
        $this->assertSame('465.00', (string) $item->line_total);
    }

    // ── the order screen ───────────────────────────────────────────────────────────────

    public function test_a_weight_is_demanded_where_the_units_differ_and_refused_where_they_do_not(): void
    {
        // Arrange
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::MoveOrderToShortage->value);
        $orderHeaders = ['Authorization' => 'Bearer '.$user->createToken('t')->plainTextToken];

        [$order, $item] = $this->soldByThePieceStockedByTheKilo();

        // Act — the invoice's figure alone, on a line the warehouse counts differently.
        $refused = $this->patchJson("/api/v1/orders/{$order->getKey()}/shortages", [
            'shortages' => [$item->getKey() => ['quantity' => '30']],
        ], $orderHeaders);

        // Assert — named on the box the clerk has to fill, because defaulting it to the count is
        // exactly what put bags into a balance of kilograms.
        $refused->assertStatus(422)
            ->assertJsonValidationErrors("shortages.{$item->getKey()}");

        $this->assertNull($item->refresh()->shortage_quantity);
        $this->assertSame(0, StockMovement::query()->count());
    }
}
