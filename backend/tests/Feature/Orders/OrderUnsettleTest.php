<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\PaymentStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Taking an order back out of «تم التسوية», and the refusal that makes it necessary.
 *
 * > **A settled order may not be made to owe. Money comes off it only after somebody takes it
 * > back to «تم الاستلام», says why, and the timeline records it.**
 *
 * «تم التسوية» stays final on the map — `OrderStatusTest` still asserts it leads nowhere — and
 * this endpoint is an undo of one recorded move, like the reinstatement of a cancellation.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderUnsettleTest extends TestCase
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

    /** Someone who may take money off an order, and reopen a settled one to do it. */
    private function accountant(): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::UnsettleOrders,
        );
    }

    /**
     * A settled order of `$total`, paid in full in one cash entry.
     *
     * @param  array<string, string>  $headers
     */
    private function settled(array $headers, string $total = '450.00'): Order
    {
        $order = Order::factory()->create([
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
            'status' => OrderStatus::Settled,
            'settled_at' => now(),
            'collected_amount' => $total,
        ]);

        $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/payments", [
                'amount' => $total,
                'method' => PaymentMethod::Cash->value,
            ])
            ->assertCreated();

        return $order->refresh();
    }

    // ─────────────────────────────── the undo itself ──────────────────────────────────

    public function test_it_takes_a_settled_order_back_to_delivered_and_clears_the_settlement(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'الصك رجع بدون رصيد']);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', OrderStatus::Delivered->value)
            ->assertJsonPath('message', 'تم التراجع عن التسوية، وأُعيدت الطلبية إلى «'.OrderStatus::Delivered->label().'»');

        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $this->assertNull($order->settled_at);
        $this->assertNull($order->collected_amount);
    }

    public function test_the_move_is_written_on_the_timeline_with_its_reason(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);

        // Act
        $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'الصك رجع بدون رصيد'])
            ->assertOk();

        // Assert
        $this->assertDatabaseHas('order_status_transitions', [
            'order_id' => $order->id,
            'from_status' => OrderStatus::Settled->value,
            'to_status' => OrderStatus::Delivered->value,
            'reason' => 'الصك رجع بدون رصيد',
        ]);
    }

    public function test_it_demands_a_reason(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/unsettle", []);

        // Assert
        $response->assertStatus(422)->assertJsonStructure(['errors' => ['reason']]);
        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
    }

    public function test_an_order_that_is_not_settled_is_refused(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = Order::factory()->create(['status' => OrderStatus::Delivered]);

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'تجربة']);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    public function test_the_grant_to_settle_is_not_the_grant_to_unsettle(): void
    {
        // Arrange — the whole reason the permission is its own.
        $order = $this->settled($this->accountant());
        $headers = $this->auth(PermissionName::ViewOrders, PermissionName::SettleOrders);

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'تجربة']);

        // Assert
        $response->assertForbidden();
        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
    }

    // ───────────────────────── the offer on the order ──────────────────────────────────

    public function test_a_settled_order_offers_the_undo_to_somebody_who_holds_the_grant(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.can_unsettle', true);
    }

    public function test_nobody_else_is_offered_it_and_no_other_status_offers_it(): void
    {
        // Arrange
        $order = $this->settled($this->accountant());
        $delivered = Order::factory()->create(['status' => OrderStatus::Delivered]);
        $withoutGrant = $this->auth(PermissionName::ViewOrders);

        // Act & Assert
        $this->withHeaders($withoutGrant)->getJson("/api/v1/orders/{$order->id}")
            ->assertOk()->assertJsonPath('data.can_unsettle', false);
        $this->withHeaders($this->accountant())->getJson("/api/v1/orders/{$delivered->id}")
            ->assertOk()->assertJsonPath('data.can_unsettle', false);
    }

    // ───────────────────── money coming off a settled order ─────────────────────────────

    public function test_reversing_a_payment_that_would_leave_a_settled_order_owing_is_refused(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);
        $payment = OrderPayment::query()->where('order_id', $order->id)->firstOrFail();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/payments/{$payment->id}/reverse", ['reason' => 'خطأ']);

        // Assert — nothing written, the order still paid and still settled.
        $response->assertStatus(422);
        $this->assertDatabaseCount('order_payments', 1);
        $this->assertFalse($payment->refresh()->isReversed());
        $order->refresh();
        $this->assertSame('450.00', (string) $order->paid_amount);
        $this->assertSame(OrderStatus::Settled, $order->status);
    }

    public function test_once_unsettled_the_same_reversal_passes_and_the_order_owes_again(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);
        $payment = OrderPayment::query()->where('order_id', $order->id)->firstOrFail();
        $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'الصك رجع'])
            ->assertOk();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/payments/{$payment->id}/reverse", ['reason' => 'الصك رجع']);

        // Assert
        $response->assertCreated();
        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $this->assertSame(PaymentStatus::Unpaid, $order->paymentStatus());
    }

    public function test_a_refund_that_would_leave_a_settled_order_owing_is_refused(): void
    {
        // Arrange
        $headers = $this->accountant();
        $order = $this->settled($headers);

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
                'amount' => '100.00',
                'method' => PaymentMethod::Cash->value,
            ]);

        // Assert
        $response->assertStatus(422);
        $this->assertDatabaseCount('order_payments', 1);
        $this->assertSame('450.00', (string) $order->refresh()->paid_amount);
    }

    public function test_handing_back_an_overpayment_on_a_settled_order_still_passes(): void
    {
        // Arrange — 450 taken, then the invoice shrank to 400 (a partial delivery does this): the
        // fifty is the customer's. Written straight to the row because the payment endpoint
        // refuses to take more than is owed in the first place.
        $headers = $this->accountant();
        $order = $this->settled($headers);
        $order->forceFill(['items_total' => '400.00', 'grand_total' => '400.00'])->save();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
                'amount' => '50.00',
                'method' => PaymentMethod::Cash->value,
            ]);

        // Assert
        $response->assertCreated();
        $order->refresh();
        $this->assertSame(OrderStatus::Settled, $order->status);
        $this->assertSame(PaymentStatus::Paid, $order->paymentStatus());
    }
}
