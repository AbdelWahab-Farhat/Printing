<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderShortagesRecorded;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Testing\TestResponse;
use PHPUnit\Framework\Attributes\DataProvider;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «إدارة الطلبية»: a line's quantity and price, for `orders.edit_fully`, from the quantities being
 * set until delivery.
 *
 * See Docs/orders/ORDER-EDIT-ANY-STATUS.md §6.
 */
class ManageOrderLinesTest extends TestCase
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
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function manager(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders, PermissionName::EditOrdersFully);
    }

    /** @return array<string, string> */
    private function clerk(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders);
    }

    /**
     * An order of two lines, 300 × 1.100 and 100 × 2.000. No stock has left the shelf, so these
     * tests are about the figures; the stock path is SyncOrderItems' own and is tested there.
     *
     * @return array{0: Order, 1: OrderItem, 2: OrderItem}
     */
    private function orderIn(OrderStatus $status): array
    {
        $order = Order::factory()->status($status)->create([
            'items_total' => '530.00',
            'grand_total' => '530.00',
            'notes' => 'ملاحظة أصلية',
        ]);

        $first = OrderItem::factory()->create(['order_id' => $order->getKey()]);
        $second = OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'quantity' => '100.000',
            'unit_price' => '2.000',
            'line_total' => '200.00',
            'sort_order' => 1,
        ]);

        return [$order->refresh(), $first, $second];
    }

    /**
     * @param  array<string, string>  $headers
     * @param  list<array<string, mixed>>  $items
     * @param  array<string, mixed>  $extra
     */
    private function manage(array $headers, Order $order, array $items, array $extra = []): TestResponse
    {
        return $this->withHeaders($headers)->putJson(
            "/api/v1/orders/{$order->id}/manage",
            ['items' => $items, ...$extra],
        );
    }

    public function test_the_quantity_and_price_are_written_and_the_total_follows(): void
    {
        // Arrange
        [$order, $first] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act
        $response = $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '400', 'unit_price' => '1.500'],
        ]);

        // Assert — 400 × 1.5 = 600, beside the untouched 200.
        $response->assertOk();
        $first->refresh();
        $this->assertSame('400.000', (string) $first->quantity);
        $this->assertSame('1.500', (string) $first->unit_price);
        $this->assertSame('600.00', (string) $first->line_total);
        $this->assertSame('800.00', (string) $order->refresh()->items_total);
    }

    public function test_the_typed_price_wins_over_the_catalogue_when_the_quantity_moves(): void
    {
        // Arrange — a moved quantity makes the sync price the line from the catalogue first.
        [$order, $first] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act
        $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '350', 'unit_price' => '0.900'],
        ])->assertOk();

        // Assert
        $this->assertSame('0.900', (string) $first->refresh()->unit_price);
    }

    public function test_a_line_not_sent_and_the_rest_of_the_order_are_left_alone(): void
    {
        // Arrange
        [$order, $first, $second] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act — a field this screen does not own rides along and is ignored.
        $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '300', 'unit_price' => '1.200'],
        ], ['notes' => 'محاولة'])->assertOk();

        // Assert
        $second->refresh();
        $this->assertSame('100.000', (string) $second->quantity);
        $this->assertSame('2.000', (string) $second->unit_price);
        $this->assertSame('ملاحظة أصلية', $order->refresh()->notes);
        $this->assertSame(2, $order->items()->count());
    }

    /**
     * @return array<string, array{0: OrderStatus}>
     */
    public static function openStatuses(): array
    {
        return [
            'new' => [OrderStatus::New],
            'preparing' => [OrderStatus::Preparing],
            'printing' => [OrderStatus::Printing],
            'ready' => [OrderStatus::Ready],
            'out for delivery' => [OrderStatus::OutForDelivery],
            'returned to the office' => [OrderStatus::ReturnedOffice],
        ];
    }

    #[DataProvider('openStatuses')]
    public function test_it_is_open_from_the_quantities_being_set_until_delivery(OrderStatus $status): void
    {
        // Arrange
        [$order, $first] = $this->orderIn($status);

        // Act
        $response = $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '400', 'unit_price' => '1.500'],
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.lines_are_manageable', true);
        $this->assertSame('400.000', (string) $first->refresh()->quantity);
    }

    /**
     * @return array<string, array{0: OrderStatus}>
     */
    public static function shutStatuses(): array
    {
        return [
            'under review' => [OrderStatus::Requested],
            'delivered' => [OrderStatus::Delivered],
            'settled' => [OrderStatus::Settled],
            'cancelled' => [OrderStatus::Cancelled],
            'rejected' => [OrderStatus::RequestRejected],
        ];
    }

    #[DataProvider('shutStatuses')]
    public function test_it_is_refused_under_review_and_once_the_money_is_final(OrderStatus $status): void
    {
        // Arrange
        [$order, $first] = $this->orderIn($status);

        // Act
        $response = $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '400', 'unit_price' => '1.500'],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame('300.000', (string) $first->refresh()->quantity);
        $this->assertFalse($order->refresh()->linesAreManageable());
    }

    public function test_a_shortage_is_told_its_line_changed(): void
    {
        // Arrange — the shortage rows mirror the lines, through the listener.
        Event::fake([OrderShortagesRecorded::class]);
        [$order, $first] = $this->orderIn(OrderStatus::Shortage);

        // Act
        $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '400', 'unit_price' => '1.100'],
        ])->assertOk();

        // Assert
        Event::assertDispatched(OrderShortagesRecorded::class);
    }

    public function test_it_is_refused_without_the_grant(): void
    {
        // Arrange
        [$order, $first] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act
        $response = $this->manage($this->clerk(), $order, [
            ['id' => $first->id, 'quantity' => '400', 'unit_price' => '1.500'],
        ]);

        // Assert
        $response->assertForbidden();
        $this->assertSame('1.100', (string) $first->refresh()->unit_price);
    }

    public function test_a_line_of_another_order_is_refused(): void
    {
        // Arrange
        [$order] = $this->orderIn(OrderStatus::ReadyToPrint);
        [, $foreign] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act
        $response = $this->manage($this->manager(), $order, [
            ['id' => $foreign->id, 'quantity' => '400', 'unit_price' => '1.500'],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items');
        $this->assertSame('300.000', (string) $foreign->refresh()->quantity);
    }

    public function test_the_price_is_required(): void
    {
        // Arrange
        [$order, $first] = $this->orderIn(OrderStatus::ReadyToPrint);

        // Act
        $response = $this->manage($this->manager(), $order, [
            ['id' => $first->id, 'quantity' => '400'],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('items.0.unit_price');
    }
}
