<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «بانتظار التجهيز» on the plain (سادة) road (owner, 2026-11-18): the deposit answer leads to the
 * warehouse, the warehouse to the shelf, and nothing on the way asks for artwork.
 *
 * Arrange - Act - Assert throughout.
 */
class PlainOrderPreparingTest extends TestCase
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
    private function foreman(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, PermissionName::cases()));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * A plain order of one line in «بدون عربون», and a warehouse holding [$onShelf] of it.
     *
     * @return array{0: Order, 1: OrderItem, 2: Warehouse}
     */
    private function plainOrder(string $quantity = '300', string $onShelf = '1000'): array
    {
        $product = Product::factory()->create(['pricing_unit' => PricingUnit::Piece]);
        $size = ProductVariant::factory()->for($product)->create(['label' => '25*35']);

        $order = Order::factory()->status(OrderStatus::NoDeposit)->create([
            'production_flow' => OrderFlow::NoProduction,
        ]);

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
     * @param  array<string, string>  $headers
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
     * @param  array<string, string>  $headers
     * @return list<string>
     */
    private function offered(array $headers, Order $order): array
    {
        return array_column(
            $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}")->json('data.available_transitions'),
            'status',
        );
    }

    /**
     * @param  array<string, string>  $headers
     * @return list<string>
     */
    private function fieldKeys(array $headers, Order $order, OrderStatus $target): array
    {
        foreach ($this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}")->json('data.available_transitions') as $transition) {
            if ($transition['status'] === $target->value) {
                return array_column($transition['fields'], 'key');
            }
        }

        $this->fail("«{$target->label()}» is not offered.");
    }

    public function test_the_deposit_answer_leads_to_the_warehouse_not_the_shelf(): void
    {
        // Arrange
        [$order] = $this->plainOrder();
        $headers = $this->foreman();

        // Act
        $offered = $this->offered($headers, $order);

        // Assert
        $this->assertContains(OrderStatus::Preparing->value, $offered);
        $this->assertNotContains(OrderStatus::Ready->value, $offered);
        $this->assertNotContains(OrderStatus::Designing->value, $offered);
    }

    public function test_preparing_asks_for_no_artwork_and_opens_no_ticket(): void
    {
        // Arrange
        [$order] = $this->plainOrder();
        $headers = $this->foreman();

        // Act
        $keys = $this->fieldKeys($headers, $order, OrderStatus::Preparing);
        $response = $this->move($headers, $order, OrderStatus::Preparing);

        // Assert
        $this->assertNotContains('design_ids', $keys);
        $this->assertNotContains(TransitionFields::APPROVE_DESIGN, $keys);
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
        $this->assertNotNull($order->refresh()->preparing_started_at);
        $this->assertSame(0, DesignTicket::query()->where('order_id', $order->id)->count());
    }

    public function test_from_the_warehouse_to_the_shelf_the_stock_leaves_once(): void
    {
        // Arrange
        [$order, , $warehouse] = $this->plainOrder(quantity: '300', onShelf: '1000');
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::Preparing)->assertOk();

        // Act
        $keys = $this->fieldKeys($headers, $order->refresh(), OrderStatus::Ready);
        $response = $this->move($headers, $order, OrderStatus::Ready, ['warehouse_id' => $warehouse->getKey()]);

        // Assert
        $this->assertContains('warehouse_id', $keys);
        $response->assertOk()->assertJsonPath('data.status', 'ready');
        $this->assertSame('700.000', $this->balance($warehouse, $order));
    }

    public function test_a_shortage_comes_back_through_the_warehouse(): void
    {
        // Arrange — short by a hundred.
        [$order, $item] = $this->plainOrder();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::Shortage, ["shortage_{$item->id}" => '100'])->assertOk();

        // Act — the way back is the warehouse, where the arrival is counted.
        $offered = $this->offered($headers, $order->refresh());
        $response = $this->move($headers, $order, OrderStatus::Preparing, ["received_{$item->id}" => '100']);

        // Assert
        $this->assertSame([OrderStatus::Preparing->value, OrderStatus::Cancelled->value], $offered);
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
        $this->assertNull($item->refresh()->shortage_quantity);
    }

    public function test_the_shelf_is_refused_an_order_still_short(): void
    {
        // Arrange — a shortage written on the line while the order is being gathered.
        [$order, $item, $warehouse] = $this->plainOrder();
        $headers = $this->foreman();
        $this->move($headers, $order, OrderStatus::Preparing)->assertOk();
        $item->forceFill(['shortage_quantity' => '100'])->save();

        // Act
        $response = $this->move($headers, $order->refresh(), OrderStatus::Ready, ['warehouse_id' => $warehouse->getKey()]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::Preparing, $order->fresh()->status);
    }

    public function test_the_progress_line_shows_the_warehouse_step(): void
    {
        // Act
        $line = OrderStatus::mainLine(FulfilmentType::Delivery, OrderFlow::NoProduction);

        // Assert
        $this->assertSame(
            [OrderStatus::New, OrderStatus::Preparing, OrderStatus::Ready],
            array_slice($line, 0, 3),
        );
        $this->assertSame('بانتظار التجهيز', OrderStatus::Preparing->label());
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
