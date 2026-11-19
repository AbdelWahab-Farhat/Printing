<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «بدون عربون» and «بانتظار التجهيز» — the artwork before the warehouse (owner's status document,
 * 2026-11-15; ORDERS-STATUS-FLOW.md §٢١).
 *
 * `OrderStatusTest` pins the map. This covers what the new road *does*: the approved-design gate
 * and its one-tap approval, the shortage asked about on the way into the warehouse rather than on
 * the way out of «نواقص», no shortage once the stock has left, and the stock drawn once however
 * many times an order walks back through the warehouse.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderPreparingTest extends TestCase
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
     * Someone who may walk an order the whole way before the press.
     *
     * @return array<string, string>
     */
    private function foreman(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            PermissionName::MoveOrderToNoDeposit,
            PermissionName::MoveOrderToDesigning,
            PermissionName::MoveOrderToPreparing,
            PermissionName::MoveOrderToReadyToPrint,
            PermissionName::MoveOrderToShortage,
            PermissionName::CancelOrders,
            PermissionName::ViewInventory,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * A new order of one line, and a warehouse holding [$onShelf] of what it will draw.
     *
     * @return array{0: Order, 1: OrderItem, 2: Warehouse}
     */
    private function order(string $quantity = '300', string $onShelf = '1000'): array
    {
        $product = Product::factory()->create(['pricing_unit' => PricingUnit::Piece]);
        $size = ProductVariant::factory()->for($product)->create(['label' => '25*35']);

        $order = Order::factory()->create();

        $item = OrderItem::factory()->for($order)->create([
            'product_id' => $product->getKey(),
            'product_variant_id' => $size->getKey(),
            'variant_label' => $size->label,
            'quantity' => $quantity,
            'pricing_unit' => PricingUnit::Piece,
        ]);

        $warehouse = Warehouse::factory()->create();
        $shelf = StockItem::query()->findOrFail($size->stock_item_id);

        WarehouseStock::factory()->quantity($onShelf)->unit($shelf->unit)->create([
            'warehouse_id' => $warehouse->getKey(),
            'stock_item_id' => $shelf->getKey(),
        ]);

        return [$order->refresh(), $item, $warehouse];
    }

    /**
     * @param  array<string, mixed>  $fields
     */
    private function move(array $headers, Order $order, OrderStatus $to, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            array_filter(['status' => $to->value, 'fields' => $fields ?: null]),
        );
    }

    /**
     * The fields the server describes for the move into [$target].
     *
     * @return list<array<string, mixed>>
     */
    private function fieldsFor(array $headers, Order $order, OrderStatus $target): array
    {
        $transitions = $this->withHeaders($headers)
            ->getJson("/api/v1/orders/{$order->id}")
            ->json('data.available_transitions');

        foreach ($transitions as $transition) {
            if ($transition['status'] === $target->value) {
                return $transition['fields'];
            }
        }

        $this->fail("«{$target->label()}» is not offered.");
    }

    private function proposedDesign(Order $order): OrderDesign
    {
        return OrderDesign::factory()->create(['order_id' => $order->getKey(), 'version' => 1]);
    }

    // ─────────────────────────── the deposit question ───────────────────────────

    public function test_no_deposit_starts_the_work_without_writing_anything_to_the_ledger(): void
    {
        // Arrange
        [$order] = $this->order();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::NoDeposit);

        // Assert — a statement about the deal: nothing paid, nothing asked for.
        $response->assertOk()->assertJsonPath('data.status', 'no_deposit');
        $this->assertNull($order->refresh()->deposit_expected_amount);
        $this->assertSame('0.00', (string) $order->paid_amount);
    }

    // ─────────────────────────── the approved-design gate ───────────────────────────

    public function test_an_order_with_artwork_is_not_prepared_until_a_version_is_approved(): void
    {
        // Arrange
        [$order, , $warehouse] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $this->proposedDesign($order);

        // Act — the tick left alone.
        $response = $this->move($headers, $order->refresh(), OrderStatus::Preparing);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::NoDeposit, $order->fresh()->status);
    }

    public function test_the_tick_approves_the_latest_version_on_the_same_move(): void
    {
        // Arrange
        [$order] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $design = $this->proposedDesign($order);

        // Act — the form offers the tick, required, naming the version.
        $fields = $this->fieldsFor($headers, $order->refresh(), OrderStatus::Preparing);
        $tick = collect($fields)->firstWhere('key', TransitionFields::APPROVE_DESIGN);

        $response = $this->move($headers, $order, OrderStatus::Preparing, [
            TransitionFields::APPROVE_DESIGN => true,
        ]);

        // Assert — approving and moving are one step.
        $this->assertNotNull($tick);
        $this->assertSame('checkbox', $tick['type']);
        $this->assertTrue($tick['required']);
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
        $this->assertSame(OrderDesignStatus::Approved, $design->refresh()->status);
        $this->assertNotNull($order->refresh()->preparing_started_at);
    }

    public function test_an_approved_version_is_asked_nothing(): void
    {
        // Arrange
        [$order] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        OrderDesign::factory()->approved()->create(['order_id' => $order->getKey(), 'version' => 1]);

        // Act
        $keys = array_column($this->fieldsFor($headers, $order->refresh(), OrderStatus::Preparing), 'key');
        $response = $this->move($headers, $order, OrderStatus::Preparing);

        // Assert
        $this->assertNotContains(TransitionFields::APPROVE_DESIGN, $keys);
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
    }

    public function test_an_in_house_design_nobody_has_drawn_goes_to_the_designer_first(): void
    {
        // Arrange — «تصميم من عندنا» and no version yet.
        [$order] = $this->order();
        $order->forceFill(['design_source' => DesignSource::InHouse])->save();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();

        // Act
        $response = $this->move($headers, $order->refresh(), OrderStatus::Preparing, [
            TransitionFields::APPROVE_DESIGN => true,
        ]);

        // Assert — nothing to approve, so the tick cannot help.
        $response->assertStatus(422);
        $this->assertStringContainsString('قيد التصميم', $response->json('message'));
    }

    public function test_an_order_with_no_artwork_goes_straight_to_the_warehouse(): void
    {
        // Arrange — «بدون تصميم» and no version.
        [$order] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();

        // Act
        $response = $this->move($headers, $order->refresh(), OrderStatus::Preparing);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
    }

    public function test_an_open_design_ticket_keeps_the_order_out_of_the_warehouse(): void
    {
        // Arrange
        [$order] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        DesignTicket::factory()->create([
            'customer_id' => $order->customer_id,
            'order_id' => $order->getKey(),
        ]);

        // Act
        $response = $this->move($headers, $order->refresh(), OrderStatus::Preparing);

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('قبل التجهيز', $response->json('message'));
    }

    // ─────────────────────────── shortages ───────────────────────────

    public function test_the_design_goes_on_while_the_stock_is_awaited(): void
    {
        // Arrange — short by a hundred.
        [$order, $item] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Shortage, ["shortage_{$item->id}" => '100'])
            ->assertOk();

        // Act — to the designer, and nothing is asked about what arrived.
        $keys = array_column($this->fieldsFor($headers, $order->refresh(), OrderStatus::Designing), 'key');
        $response = $this->move($headers, $order, OrderStatus::Designing);

        // Assert — the shortage stays on the line.
        $this->assertNotContains("received_{$item->id}", $keys);
        $response->assertOk()->assertJsonPath('data.status', 'designing');
        $this->assertSame('100.000', (string) $item->refresh()->shortage_quantity);
    }

    public function test_the_warehouse_is_refused_an_order_still_short(): void
    {
        // Arrange — short, then on to the designer.
        [$order, $item] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Shortage, ["shortage_{$item->id}" => '100'])
            ->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Designing)->assertOk();

        // Act — nothing arrived.
        $response = $this->move($headers, $order->refresh(), OrderStatus::Preparing, [
            "received_{$item->id}" => '0',
        ]);

        // Assert — the message names the size.
        $response->assertStatus(422);
        $this->assertStringContainsString('25*35', $response->json('message'));
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
    }

    public function test_the_arrival_is_counted_on_the_way_into_the_warehouse(): void
    {
        // Arrange
        [$order, $item] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Shortage, ["shortage_{$item->id}" => '100'])
            ->assertOk();

        // Act — the form asks what arrived, and the whole hundred did.
        $keys = array_column($this->fieldsFor($headers, $order->refresh(), OrderStatus::Preparing), 'key');
        $response = $this->move($headers, $order, OrderStatus::Preparing, [
            "received_{$item->id}" => '100',
        ]);

        // Assert
        $this->assertContains("received_{$item->id}", $keys);
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
        $this->assertNull($item->refresh()->shortage_quantity);
    }

    public function test_no_shortage_is_declared_once_the_stock_has_left(): void
    {
        // Arrange — through the warehouse, the stock drawn, then back to the designer.
        [$order, $item, $warehouse] = $this->order();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Preparing)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::ReadyToPrint, ['warehouse_id' => $warehouse->getKey()])
            ->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Designing)->assertOk();

        // Act
        $response = $this->move($headers, $order->refresh(), OrderStatus::Shortage, [
            "shortage_{$item->id}" => '100',
        ]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
    }

    // ─────────────────────────── the stock ───────────────────────────

    public function test_the_stock_leaves_at_the_handover_and_only_once(): void
    {
        // Arrange
        [$order, , $warehouse] = $this->order(quantity: '300', onShelf: '1000');
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::NoDeposit)->assertOk();

        // Act — gathering takes nothing off the shelf; the handover does.
        $this->move($headers, $order->refresh(), OrderStatus::Preparing)->assertOk();
        $afterPreparing = $this->balance($warehouse, $order);

        $this->move($headers, $order->refresh(), OrderStatus::ReadyToPrint, ['warehouse_id' => $warehouse->getKey()])
            ->assertOk();
        $afterHandover = $this->balance($warehouse, $order);

        // A design correction walks the order back through the warehouse.
        $this->move($headers, $order->refresh(), OrderStatus::Designing)->assertOk();
        $this->move($headers, $order->refresh(), OrderStatus::Preparing)->assertOk();
        $keys = array_column($this->fieldsFor($headers, $order->refresh(), OrderStatus::ReadyToPrint), 'key');
        $this->move($headers, $order, OrderStatus::ReadyToPrint)->assertOk();

        // Assert — drawn once, and the warehouse is not asked again.
        $this->assertSame('1000.000', $afterPreparing);
        $this->assertSame('700.000', $afterHandover);
        $this->assertSame('700.000', $this->balance($warehouse, $order));
        $this->assertNotContains('warehouse_id', $keys);
    }

    private function balance(Warehouse $warehouse, Order $order): string
    {
        $shelf = ProductVariant::query()->findOrFail($order->items()->value('product_variant_id'))->stock_item_id;

        return (string) WarehouseStock::query()
            ->where('warehouse_id', $warehouse->getKey())
            ->where('stock_item_id', $shelf)
            ->value('quantity');
    }
}
