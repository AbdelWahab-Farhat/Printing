<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Enums\CustomerMessage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Settings\Models\CompanySetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «هل تواصلنا مع الزبون بعد أن رجعت طلبيته؟» — the return-side twin of the ready message, and
 * the admin's wording of all four customer messages.
 *
 * See Docs/orders/ORDER-RETURN-MESSAGE.md.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderReturnMessageTest extends TestCase
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
    private function messenger(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ConfirmReadyMessage);
    }

    private function returnedOrder(OrderStatus $status = OrderStatus::ReturnedCourier): Order
    {
        return Order::factory()->create([
            'status' => $status,
            'ready_at' => now()->subDays(2),
            'dispatched_at' => now()->subDay(),
            'returned_at' => now()->subHour(),
        ]);
    }

    // ── marking it ───────────────────────────────────────────────────────────────────────────

    public function test_it_records_who_contacted_the_customer_and_when(): void
    {
        // Arrange
        $order = $this->returnedOrder();

        // Act
        $response = $this->withHeaders($this->messenger())
            ->patchJson("/api/v1/orders/{$order->id}/return-message", ['sent' => true]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.return_message_applies', true)
            ->assertJsonPath('data.is_return_message_sent', true);

        $order->refresh();
        $this->assertNotNull($order->return_message_sent_at);
        $this->assertSame($order->return_message_sent_by, $response->json('data.return_message_sent_by.id'));
    }

    public function test_it_takes_the_mark_back(): void
    {
        // Arrange
        $order = $this->returnedOrder(OrderStatus::ReturnedCarrier);
        $headers = $this->messenger();
        $this->withHeaders($headers)->patchJson("/api/v1/orders/{$order->id}/return-message", ['sent' => true]);

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/return-message", ['sent' => false]);

        // Assert
        $response->assertOk()->assertJsonPath('data.is_return_message_sent', false);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'return_message_sent_at' => null,
            'return_message_sent_by' => null,
        ]);
    }

    public function test_it_refuses_an_order_that_is_not_in_a_return(): void
    {
        // Arrange — back on our shelf: the next step is ours, not the customer's.
        $order = $this->returnedOrder(OrderStatus::ReturnedOffice);

        // Act
        $response = $this->withHeaders($this->messenger())
            ->patchJson("/api/v1/orders/{$order->id}/return-message", ['sent' => true]);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('status', false);
        $this->assertDatabaseHas('orders', ['id' => $order->id, 'return_message_sent_at' => null]);
    }

    public function test_it_requires_the_messages_grant(): void
    {
        // Arrange
        $order = $this->returnedOrder();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewOrders))
            ->patchJson("/api/v1/orders/{$order->id}/return-message", ['sent' => true]);

        // Assert
        $response->assertForbidden();
    }

    public function test_it_requires_the_sent_field(): void
    {
        // Arrange
        $order = $this->returnedOrder();

        // Act
        $response = $this->withHeaders($this->messenger())
            ->patchJson("/api/v1/orders/{$order->id}/return-message", []);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('sent');
    }

    // ── each return asks again ───────────────────────────────────────────────────────────────

    /** Moved by the real status action, so the clearing is proven where Nawris moves it too. */
    public function test_moving_from_the_courier_to_the_carrier_asks_for_a_new_message(): void
    {
        // Arrange
        $order = $this->returnedOrder(OrderStatus::ReturnedCourier);
        $order->forceFill(['return_message_sent_at' => now(), 'return_message_sent_by' => User::factory()->create()->id])->save();

        // Act
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::ReturnedCarrier);

        // Assert
        $moved->refresh();
        $this->assertSame(OrderStatus::ReturnedCarrier, $moved->status);
        $this->assertNull($moved->return_message_sent_at);
        $this->assertNull($moved->return_message_sent_by);
    }

    /** A mark left from an earlier return does not answer for a new one after a resend. */
    public function test_a_second_return_clears_the_mark_from_the_first(): void
    {
        // Arrange
        $order = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'ready_at' => now()->subDays(3),
            'dispatched_at' => now()->subHour(),
            'return_message_sent_at' => now()->subDays(2),
        ]);

        // Act
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::ReturnedCourier);

        // Assert
        $this->assertNull($moved->refresh()->return_message_sent_at);
    }

    // ── the queue ────────────────────────────────────────────────────────────────────────────

    public function test_the_queue_holds_unmarked_orders_in_a_return_and_nothing_else(): void
    {
        // Arrange
        $courier = $this->returnedOrder(OrderStatus::ReturnedCourier);
        $carrier = $this->returnedOrder(OrderStatus::ReturnedCarrier);
        $this->returnedOrder(OrderStatus::ReturnedCourier)
            ->forceFill(['return_message_sent_at' => now()])->save();
        $this->returnedOrder(OrderStatus::ReturnedOffice);
        Order::factory()->create(['status' => OrderStatus::OutForDelivery, 'dispatched_at' => now()]);

        // Act
        $response = $this->withHeaders($this->messenger())
            ->getJson('/api/v1/orders?is_return_message_sent=0');

        // Assert
        $response->assertOk();
        $ids = collect($response->json('data'))->pluck('id')->sort()->values()->all();
        $this->assertSame(collect([$courier->id, $carrier->id])->sort()->values()->all(), $ids);
    }

    public function test_the_home_box_counts_the_queue_for_the_messenger_only(): void
    {
        // Arrange
        $this->returnedOrder(OrderStatus::ReturnedCourier);
        $this->returnedOrder(OrderStatus::ReturnedCarrier);

        // Act
        $messenger = $this->withHeaders($this->messenger())->getJson('/api/v1/home/summary');
        $viewer = $this->withHeaders($this->auth(PermissionName::ViewOrders))->getJson('/api/v1/home/summary');

        // Assert
        $messenger->assertOk()
            ->assertJsonPath('data.return_message.count', 2)
            ->assertJsonPath('data.return_message.label', 'طلبيات راجعة بانتظار التواصل');
        $viewer->assertOk()->assertJsonMissingPath('data.return_message');
    }

    // ── the texts ────────────────────────────────────────────────────────────────────────────

    public function test_each_return_status_copies_its_own_built_in_text(): void
    {
        // Arrange
        $courier = $this->returnedOrder(OrderStatus::ReturnedCourier);
        $carrier = $this->returnedOrder(OrderStatus::ReturnedCarrier);
        $headers = $this->messenger();

        // Act
        $courierText = $this->withHeaders($headers)->getJson("/api/v1/orders/{$courier->id}")->json('data.return_message_text');
        $carrierText = $this->withHeaders($headers)->getJson("/api/v1/orders/{$carrier->id}")->json('data.return_message_text');

        // Assert
        $this->assertStringContainsString("[ {$courier->code} ]", $courierText);
        $this->assertStringContainsString('مندوب التوصيل حاول يوصلك', $courierText);
        $this->assertStringContainsString("[ {$carrier->code} ]", $carrierText);
        $this->assertStringContainsString('رجعت لشركة التوصيل', $carrierText);
    }

    public function test_an_order_outside_a_return_has_no_return_text(): void
    {
        // Arrange
        $order = Order::factory()->create(['status' => OrderStatus::OutForDelivery, 'dispatched_at' => now()]);

        // Act
        $response = $this->withHeaders($this->messenger())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.return_message_applies', false)
            ->assertJsonPath('data.return_message_text', null);
    }

    public function test_the_ready_text_follows_the_way_the_order_left(): void
    {
        // Arrange
        $pickup = Order::factory()->create([
            'status' => OrderStatus::OfficePickup,
            'fulfilment_type' => FulfilmentType::OfficePickup,
            'dispatched_at' => now(),
        ]);
        $delivery = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'fulfilment_type' => FulfilmentType::Delivery,
            'dispatched_at' => now(),
        ]);
        $headers = $this->messenger();

        // Act
        $pickupText = $this->withHeaders($headers)->getJson("/api/v1/orders/{$pickup->id}")->json('data.ready_message_text');
        $deliveryText = $this->withHeaders($headers)->getJson("/api/v1/orders/{$delivery->id}")->json('data.ready_message_text');

        // Assert
        $this->assertStringContainsString('جاهزة للاستلام من مكتب شركة بريمولا', $pickupText);
        $this->assertStringContainsString("[ {$pickup->code} ]", $pickupText);
        $this->assertStringContainsString('في الطريق إليك مع مندوب التوصيل', $deliveryText);
    }

    /**
     * The owner's words, spacing and all — moved here from the app's own test when the text
     * moved to the server. A customer who has had this message before should recognise it.
     */
    public function test_the_built_in_ready_texts_are_the_owners_words(): void
    {
        // Act
        $pickup = str_replace(CustomerMessage::INVOICE_PLACEHOLDER, '55', CustomerMessage::ReadyPickup->defaultBody());
        $delivery = str_replace(CustomerMessage::INVOICE_PLACEHOLDER, '55', CustomerMessage::ReadyDelivery->defaultBody());

        // Assert
        $this->assertSame(
            "أهلا وسهلا بيك ، يومك طيب إن شاء الله\n\n"
            ."طلبيتك رقم الفاتورة : [ 55 ] جاهزة للاستلام من مكتب شركة بريمولا .\n\n"
            .'ساعات الدوام من الساعة 10 صباحا حتى 10 مساء .',
            $pickup,
        );
        $this->assertSame(
            "أهلا وسهلا بيك ، يومك طيب إن شاء الله\n\n"
            .'طلبيتك رقم الفاتورة : [ 55 ] في الطريق إليك مع مندوب التوصيل .',
            $delivery,
        );
    }

    public function test_the_ready_text_is_absent_before_dispatch(): void
    {
        // Arrange
        $order = Order::factory()->create(['status' => OrderStatus::Ready, 'dispatched_at' => null]);

        // Act
        $response = $this->withHeaders($this->messenger())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.ready_message_text', null);
    }

    public function test_the_admins_wording_replaces_the_built_in_one(): void
    {
        // Arrange
        CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID)
            ->forceFill(['return_courier_message' => 'مرحبا، طلبيتك {رقم_الفاتورة} رجعت مع المندوب'])
            ->save();
        $order = $this->returnedOrder(OrderStatus::ReturnedCourier);

        // Act
        $response = $this->withHeaders($this->messenger())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.return_message_text', "مرحبا، طلبيتك {$order->code} رجعت مع المندوب");
    }

    // ── the settings screen ──────────────────────────────────────────────────────────────────

    public function test_the_settings_list_every_message_with_its_default(): void
    {
        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewCompanySettings))
            ->getJson('/api/v1/settings/customer-messages');

        // Assert — four customer texts and the vendor text (OUTSOURCED-PRODUCTS.md §10).
        $response->assertOk()
            ->assertJsonPath('data.placeholder', CustomerMessage::INVOICE_PLACEHOLDER)
            ->assertJsonCount(5, 'data.messages')
            ->assertJsonPath('data.messages.4.key', 'vendor_request')
            ->assertJsonPath('data.messages.4.placeholders', [CustomerMessage::INVOICE_PLACEHOLDER, CustomerMessage::ITEMS_PLACEHOLDER])
            ->assertJsonPath('data.messages.0.placeholders', [CustomerMessage::INVOICE_PLACEHOLDER])
            ->assertJsonPath('data.messages.0.key', 'ready_pickup')
            ->assertJsonPath('data.messages.0.is_customised', false)
            ->assertJsonPath('data.messages.0.body', CustomerMessage::ReadyPickup->defaultBody())
            ->assertJsonPath('data.messages.2.key', 'return_courier');
    }

    public function test_the_admin_saves_one_message_and_leaves_the_others(): void
    {
        // Arrange
        $headers = $this->auth(PermissionName::ViewCompanySettings, PermissionName::ManageCompanySettings);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings/customer-messages', [
            'messages' => ['ready_delivery' => 'طلبيتك {رقم_الفاتورة} خرجت'],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.messages.1.body', 'طلبيتك {رقم_الفاتورة} خرجت')
            ->assertJsonPath('data.messages.1.is_customised', true)
            ->assertJsonPath('data.messages.0.is_customised', false);
        $this->assertDatabaseHas('company_settings', [
            'id' => CompanySetting::SINGLETON_ID,
            'ready_delivery_message' => 'طلبيتك {رقم_الفاتورة} خرجت',
            'ready_pickup_message' => null,
        ]);
    }

    public function test_an_empty_text_puts_the_built_in_wording_back(): void
    {
        // Arrange
        CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID)
            ->forceFill(['return_carrier_message' => 'نص قديم'])->save();
        $headers = $this->auth(PermissionName::ViewCompanySettings, PermissionName::ManageCompanySettings);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings/customer-messages', [
            'messages' => ['return_carrier' => ''],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.messages.3.is_customised', false)
            ->assertJsonPath('data.messages.3.body', CustomerMessage::ReturnCarrier->defaultBody());
        $this->assertDatabaseHas('company_settings', ['id' => CompanySetting::SINGLETON_ID, 'return_carrier_message' => null]);
    }

    public function test_saving_needs_the_manage_grant(): void
    {
        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewCompanySettings))
            ->putJson('/api/v1/settings/customer-messages', ['messages' => ['ready_pickup' => 'x']]);

        // Assert
        $response->assertForbidden();
    }
}
