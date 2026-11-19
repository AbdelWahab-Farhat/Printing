<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Listeners\NotifyWhenDesignFeeIsFilled;
use App\Domain\Notification\Models\Notification;
use App\Domain\Order\Enums\CompensationReason;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderDesignFeeFilled;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Event;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

/**
 * «أجرة التصميم» filled from «أجرة المصمم» when nobody set it — Docs/orders/ORDER-DESIGN-FEE.md.
 *
 * The order's ticket is approved; if no person has decided the customer's fee, it becomes what the
 * designers of the order's approved tickets are paid, and whoever may see it is told.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderDesignFeeFromTicketTest extends DesignTicketTestCase
{
    private const BLACK = ['name' => 'أسود', 'code' => null, 'hex' => '#000000'];

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function orderFor(Customer $customer, array $attributes = []): Order
    {
        return Order::factory()->forCustomer($customer)->status(OrderStatus::ReadyToPrint)->create([
            'production_flow' => OrderFlow::Standard,
            'stock_deducted_at' => now(),
            'design_source' => DesignSource::Customer,
            ...$attributes,
        ]);
    }

    /**
     * Raised on the order with [$pay], taken and drawn — waiting for its verdict.
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     * @return array{DesignTicket, int}
     */
    private function drawn(Order $order, ?string $pay, array $employee, array $designer): array
    {
        $id = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload(Customer::query()->findOrFail($order->customer_id), [
                'order_id' => $order->id,
                'print_colors' => [self::BLACK],
                'designer_pay' => $pay,
            ]),
            $employee,
        )->assertCreated()->json('data.id');

        $ticket = DesignTicket::query()->findOrFail($id);
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        $versionId = (int) $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png'), 'print_colors' => [self::BLACK]],
            $designer + ['Accept' => 'application/json'],
        )->assertCreated()->json('data.id');

        return [$ticket, $versionId];
    }

    /**
     * @param  array<string, string>  $employee
     */
    private function approve(DesignTicket $ticket, int $versionId, array $employee): TestResponse
    {
        return $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$versionId}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();
    }

    private function holderOfTheFee(): User
    {
        $role = Role::findOrCreate('fee-reader-'.uniqid(), 'web');
        $role->givePermissionTo(Permission::findOrCreate(PermissionName::SetOrderDesignFee->value, 'web'));

        $user = User::factory()->create(['is_active' => true]);
        $user->assignRole($role);
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $user;
    }

    // ── the copy ─────────────────────────────────────────────────────────────────────────

    public function test_an_unset_fee_takes_the_designers_pay_and_the_design_becomes_ours(): void
    {
        // Arrange
        Event::fake([OrderDesignFeeFilled::class]);
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert — still nobody's decision, so it reads «تلقائية» and may be filled again.
        $order->refresh();
        $this->assertSame('30.00', (string) $order->design_fee);
        $this->assertSame(DesignSource::InHouse, $order->design_source);
        $this->assertSame('30.00', (string) $order->grand_total);
        $this->assertNull($order->design_fee_set_at);
        Event::assertDispatched(
            OrderDesignFeeFilled::class,
            fn (OrderDesignFeeFilled $event) => $event->orderId === (int) $order->id && $event->amount === '30.00',
        );
    }

    public function test_the_holder_reads_the_copied_fee_as_automatic(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);
        $this->approve($ticket, $versionId, $employee);
        [, $owner] = $this->actor(PermissionName::ViewOrders, PermissionName::SetOrderDesignFee);

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}", $owner);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.design_fee', '30.00')
            ->assertJsonPath('data.design_fee_is_auto', true);
    }

    public function test_a_fee_somebody_set_is_never_overwritten(): void
    {
        // Arrange
        Event::fake([OrderDesignFeeFilled::class]);
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), [
            'design_source' => DesignSource::InHouse,
            'design_fee' => '100.00',
            'design_fee_set_at' => now(),
        ]);
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame('100.00', (string) $order->refresh()->design_fee);
        Event::assertNotDispatched(OrderDesignFeeFilled::class);
    }

    public function test_a_fee_somebody_cleared_on_purpose_stays_cleared(): void
    {
        // Arrange — «بلا أجرة» is a decision too.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), ['design_fee_set_at' => now()]);
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame('0.00', (string) $order->refresh()->design_fee);
    }

    public function test_two_approved_tickets_add_up(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$first, $firstVersion] = $this->drawn($order, '30', $employee, $designer);
        $this->approve($first, $firstVersion, $employee);
        [$second, $secondVersion] = $this->drawn($order->refresh(), '20', $employee, $designer);

        // Act
        $this->approve($second, $secondVersion, $employee);

        // Assert
        $this->assertSame('50.00', (string) $order->refresh()->design_fee);
    }

    public function test_a_ticket_with_no_pay_fills_nothing(): void
    {
        // Arrange
        Event::fake([OrderDesignFeeFilled::class]);
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->drawn($order, null, $employee, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $order->refresh();
        $this->assertSame('0.00', (string) $order->design_fee);
        $this->assertSame(DesignSource::Customer, $order->design_source);
        Event::assertNotDispatched(OrderDesignFeeFilled::class);
    }

    public function test_an_order_delivered_meanwhile_is_left_alone(): void
    {
        // Arrange — the total the investors' share was worked out from is not reopened.
        Event::fake([OrderDesignFeeFilled::class]);
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);
        $order->forceFill(['status' => OrderStatus::Delivered])->save();

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame('0.00', (string) $order->refresh()->design_fee);
        Event::assertNotDispatched(OrderDesignFeeFilled::class);
    }

    public function test_a_compensation_order_is_left_alone(): void
    {
        // Arrange
        Event::fake([OrderDesignFeeFilled::class]);
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), [
            'is_compensation' => true,
            'compensation_reason' => CompensationReason::cases()[0],
        ]);
        [$ticket, $versionId] = $this->drawn($order, '30', $employee, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame('0.00', (string) $order->refresh()->design_fee);
        Event::assertNotDispatched(OrderDesignFeeFilled::class);
    }

    // ── the alert ────────────────────────────────────────────────────────────────────────

    public function test_whoever_may_see_the_fee_is_told(): void
    {
        // Arrange
        $holder = $this->holderOfTheFee();
        [$clerk] = $this->actor(PermissionName::ViewOrders, PermissionName::ManageOrders);
        $order = $this->orderFor($this->customer());

        // Act
        app(NotifyWhenDesignFeeIsFilled::class)->handle(new OrderDesignFeeFilled((int) $order->id, '30.00', null));

        // Assert
        $notification = Notification::query()->sole();
        $this->assertSame(NotificationType::OrderDesignFeeFilled, $notification->type);
        $this->assertSame('30.00', $notification->payload['amount']);
        $this->assertDatabaseHas('notification_recipients', [
            'notification_id' => $notification->getKey(),
            'user_id' => $holder->getKey(),
        ]);
        $this->assertDatabaseMissing('notification_recipients', [
            'notification_id' => $notification->getKey(),
            'user_id' => $clerk->getKey(),
        ]);
    }

    public function test_the_alert_waits_for_the_transaction_to_commit(): void
    {
        // Arrange & Act
        $listener = app(NotifyWhenDesignFeeIsFilled::class);

        // Assert
        $this->assertTrue($listener->afterCommit);
        $this->assertInstanceOf(ShouldQueue::class, $listener);
    }
}
