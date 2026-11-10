<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «هل أُبلِغ الزبون أنّ طلبه جاهز؟» — علامةٌ يضعها موظف، وطابورٌ يُظهر ما لم يُعلَّم بعد.
 *
 * The message itself is sent outside this system — on WhatsApp, or by ringing — so nothing here
 * can observe it. What is recorded is the employee saying they sent it, which is why the whole
 * feature is one stamp, one grant and one queue. See Docs/orders/ORDER-READY-MESSAGE.md.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderReadyMessageTest extends TestCase
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

    /** Somebody who may read orders and confirm the message on them. */
    private function messenger(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ConfirmReadyMessage);
    }

    private function viewer(): array
    {
        return $this->auth(PermissionName::ViewOrders);
    }

    /**
     * An order standing where the message is due: waiting at the office for its customer.
     *
     * Not «جاهزة»: the message goes out on dispatch, so an order still on the shelf has none.
     */
    private function readyOrder(): Order
    {
        return Order::factory()->create([
            'status' => OrderStatus::OfficePickup,
            'ready_at' => now()->subDay(),
            'dispatched_at' => now()->subHour(),
        ]);
    }

    // ── marking it ───────────────────────────────────────────────────────────────────────────

    public function test_it_records_who_confirmed_the_message_and_when(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.is_ready_message_sent', true)
            ->assertJsonPath('data.ready_message_applies', true);

        $order->refresh();
        $this->assertNotNull($order->ready_message_sent_at);
        $this->assertNotNull($order->ready_message_sent_by);
        $this->assertSame(
            $order->ready_message_sent_by,
            $response->json('data.ready_message_sent_by.id'),
        );
    }

    public function test_it_takes_the_mark_back(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $headers = $this->messenger();
        $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => false]);

        // Assert
        $response->assertOk()->assertJsonPath('data.is_ready_message_sent', false);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'ready_message_sent_at' => null,
            'ready_message_sent_by' => null,
        ]);
    }

    public function test_it_refuses_an_order_that_has_not_been_dispatched(): void
    {
        // Arrange — made and on the shelf, but not yet handed to the office or the courier.
        $order = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'ready_at' => now()->subHour(),
            'dispatched_at' => null,
        ]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('status', false);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'ready_message_sent_at' => null,
        ]);
    }

    public function test_it_does_not_apply_while_the_order_waits_on_the_shelf(): void
    {
        // Arrange
        $order = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'ready_at' => now()->subHour(),
            'dispatched_at' => null,
        ]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.ready_message_applies', false);
    }

    /**
     * Moved by the real status action rather than seeded, so the test proves the move itself
     * stamps what the rule reads — for both of the ways an order leaves the shelf. The action
     * picks the dispatch status from the order's fulfilment type, as it does for the app.
     */
    public function test_it_applies_once_a_pickup_order_enters_office_pickup(): void
    {
        // Arrange
        $order = Order::factory()->officePickup()->create([
            'status' => OrderStatus::Ready,
            'ready_at' => now()->subHour(),
        ]);

        // Act
        // Refreshed so the column defaults (the production road) are on the model.
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::OfficePickup);

        // Assert
        $this->assertSame(OrderStatus::OfficePickup, $moved->status);
        $this->assertTrue($moved->refresh()->readyMessageApplies());
    }

    public function test_it_applies_once_a_delivery_order_goes_out_for_delivery(): void
    {
        // Arrange
        $order = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'ready_at' => now()->subHour(),
        ]);

        // Act
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::OutForDelivery);

        // Assert
        $this->assertSame(OrderStatus::OutForDelivery, $moved->status);
        $this->assertTrue($moved->refresh()->readyMessageApplies());
    }

    /**
     * The stamp survives the order moving on, which is the whole reason it is read from
     * `dispatched_at` rather than from the status: a parcel that came back, or one the customer
     * already has, still answers «هل أُبلِغ أصلاً؟».
     */
    public function test_it_still_applies_after_the_order_has_come_back(): void
    {
        // Arrange
        $order = Order::factory()->create([
            'status' => OrderStatus::ReturnedOffice,
            'ready_at' => now()->subDays(3),
            'dispatched_at' => now()->subDays(2),
        ]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.ready_message_applies', true);
    }

    public function test_it_does_not_apply_before_the_order_is_ready(): void
    {
        // Arrange
        $order = Order::factory()->create(['status' => OrderStatus::New, 'ready_at' => null]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.ready_message_applies', false)
            ->assertJsonPath('data.is_ready_message_sent', false);
    }

    // ── who may ──────────────────────────────────────────────────────────────────────────────

    public function test_it_refuses_a_reader_without_the_grant(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $response->assertForbidden();
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'ready_message_sent_at' => null,
        ]);
    }

    public function test_it_needs_a_signed_in_user(): void
    {
        // Arrange
        $order = $this->readyOrder();

        // Act
        $response = $this->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $response->assertUnauthorized();
    }

    public function test_it_rejects_a_missing_flag(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", []);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('sent');
    }

    public function test_a_deleted_order_is_not_found(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $order->delete();
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $response->assertNotFound();
    }

    // ── the queue ────────────────────────────────────────────────────────────────────────────

    /**
     * `is_ready_message_sent=0` is the queue, not a bare test on the column: an order that has
     * not been dispatched has no message due yet, and one the customer already has is past
     * being told. See §٥ of the design.
     */
    public function test_the_queue_holds_only_orders_that_are_dispatched_and_unannounced(): void
    {
        // Arrange
        $waiting = $this->readyOrder();
        $outForDelivery = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'ready_at' => now()->subDay(),
            'dispatched_at' => now()->subHour(),
        ]);
        $announced = Order::factory()->create([
            'status' => OrderStatus::OfficePickup,
            'ready_at' => now()->subDay(),
            'dispatched_at' => now()->subHour(),
            'ready_message_sent_at' => now(),
        ]);
        $onTheShelf = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'ready_at' => now()->subHour(),
        ]);
        $notYetReady = Order::factory()->create(['status' => OrderStatus::New, 'ready_at' => null]);
        $delivered = Order::factory()->create([
            'status' => OrderStatus::Delivered,
            'ready_at' => now()->subDay(),
            'dispatched_at' => now()->subDay(),
        ]);
        $cancelled = Order::factory()->create([
            'status' => OrderStatus::Cancelled,
            'ready_at' => now()->subDay(),
            'dispatched_at' => now()->subDay(),
        ]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson('/api/v1/orders?is_ready_message_sent=0');

        // Assert
        $ids = array_column((array) $response->json('data'), 'id');
        $response->assertOk();
        $this->assertEqualsCanonicalizing([$waiting->id, $outForDelivery->id], $ids);
        $this->assertNotContains($announced->id, $ids);
        $this->assertNotContains($onTheShelf->id, $ids);
        $this->assertNotContains($notYetReady->id, $ids);
        $this->assertNotContains($delivered->id, $ids);
        $this->assertNotContains($cancelled->id, $ids);
    }

    public function test_the_other_half_of_the_filter_lists_what_was_announced(): void
    {
        // Arrange
        $announced = Order::factory()->create([
            'status' => OrderStatus::Delivered,
            'ready_at' => now()->subDay(),
            'ready_message_sent_at' => now()->subHour(),
        ]);
        Order::factory()->create(['status' => OrderStatus::Ready, 'ready_at' => now()]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson('/api/v1/orders?is_ready_message_sent=1');

        // Assert
        $response->assertOk();
        $this->assertSame([$announced->id], array_column((array) $response->json('data'), 'id'));
    }

    public function test_an_unanswered_filter_leaves_the_list_alone(): void
    {
        // Arrange
        Order::factory()->count(3)->create();
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/orders');

        // Assert
        $response->assertOk();
        $this->assertCount(3, (array) $response->json('data'));
    }

    // ── the home board ───────────────────────────────────────────────────────────────────────

    public function test_the_home_summary_counts_the_queue_for_a_holder_of_the_grant(): void
    {
        // Arrange
        $this->readyOrder();
        $this->readyOrder();
        Order::factory()->create(['status' => OrderStatus::New, 'ready_at' => null]);
        Order::factory()->create(['status' => OrderStatus::Ready, 'ready_at' => now()]);
        $headers = $this->messenger();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/home/summary');

        // Assert
        $response->assertOk()->assertJsonPath('data.ready_message.count', 2);
        $this->assertIsString($response->json('data.ready_message.label'));
    }

    public function test_the_home_summary_omits_the_box_without_the_grant(): void
    {
        // Arrange
        $this->readyOrder();
        $headers = $this->viewer();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/home/summary');

        // Assert
        $response->assertOk();
        $this->assertArrayNotHasKey('ready_message', (array) $response->json('data'));
    }

    // ── the trail ────────────────────────────────────────────────────────────────────────────

    public function test_it_writes_the_change_to_the_audit_trail(): void
    {
        // Arrange
        $order = $this->readyOrder();
        $headers = $this->messenger();

        // Act
        $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/ready-message", ['sent' => true]);

        // Assert
        $this->assertDatabaseHas('activity_log', [
            'subject_type' => 'order',
            'subject_id' => $order->id,
            'event' => 'updated',
        ]);
    }
}
