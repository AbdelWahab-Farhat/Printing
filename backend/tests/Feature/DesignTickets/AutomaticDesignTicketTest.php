<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderStatusTransition;
use Illuminate\Testing\TestResponse;

/**
 * The ticket «قيد التصميم» opens by itself, what closes it, and the move to «بانتظار التجهيز» its
 * approval makes (owner, 2026-11-18).
 *
 * The automatic ticket is off by default since 2026-11-26 (`design_tickets.auto_open_on_designing`);
 * the tests about it switch it on. Approval moves the order only for a ticket opened while the
 * order was in «قيد التصميم».
 *
 * Arrange - Act - Assert throughout.
 */
class AutomaticDesignTicketTest extends DesignTicketTestCase
{
    private const BLACK = ['name' => 'أسود', 'code' => null, 'hex' => '#000000'];

    private function withAutomaticTickets(): void
    {
        config(['design_tickets.auto_open_on_designing' => true]);
    }

    /**
     * A ticket a person opens on [$order] through the API, as the order stands now.
     *
     * @param  array<string, string>  $headers
     */
    private function openTicketOn(Order $order, array $headers): DesignTicket
    {
        $id = $this->postJson('/api/v1/design-tickets', $this->payload($order->customer, [
            'order_id' => $order->id,
            'print_colors' => [self::BLACK],
        ]), $headers)->assertCreated()->json('data.id');

        return DesignTicket::query()->findOrFail($id);
    }

    /**
     * @return array{User, array<string, string>}
     */
    private function foreman(): array
    {
        return $this->actor(...PermissionName::cases());
    }

    private function orderFor(
        Customer $customer,
        OrderStatus $status = OrderStatus::NoDeposit,
        OrderFlow $flow = OrderFlow::Standard,
    ): Order {
        return Order::factory()->forCustomer($customer)->status($status)->create(['production_flow' => $flow]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function move(Order $order, OrderStatus $to, array $headers, array $extra = []): TestResponse
    {
        return $this->postJson("/api/v1/orders/{$order->id}/status", ['status' => $to->value] + $extra, $headers);
    }

    private function automaticTicketOf(Order $order): DesignTicket
    {
        return DesignTicket::query()
            ->where('order_id', $order->id)
            ->where('opened_automatically', true)
            ->sole();
    }

    /**
     * Taken by [$designer] and a version submitted in black — the version's id.
     *
     * @param  array<string, string>  $designer
     */
    private function submitVersion(DesignTicket $ticket, array $designer): int
    {
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        return (int) $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['files' => $this->versionImages('v1.png'), 'print_colors' => [self::BLACK]],
            $designer + ['Accept' => 'application/json'],
        )->assertCreated()->json('data.id');
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
        );
    }

    private function approvedDesignOn(Order $order): void
    {
        OrderDesign::factory()->create([
            'order_id' => $order->id,
            'status' => OrderDesignStatus::Approved,
            'print_colors' => [self::BLACK],
        ]);
    }

    // ───────────────────────────── opening ─────────────────────────────

    public function test_moving_into_design_opens_no_ticket_by_default(): void
    {
        // Arrange
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer());

        // Act
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();

        // Assert
        $this->assertSame(0, DesignTicket::query()->where('order_id', $order->id)->count());
    }

    public function test_a_ticket_records_the_order_status_it_was_opened_in(): void
    {
        // Arrange
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer(), OrderStatus::AwaitingDeposit);

        // Act
        $ticket = $this->openTicketOn($order, $headers);

        // Assert
        $this->assertSame(OrderStatus::AwaitingDeposit, $ticket->order_status_at_open);
    }

    public function test_with_the_switch_on_moving_into_design_opens_a_ticket(): void
    {
        // Arrange
        $this->withAutomaticTickets();
        [$user, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer());

        // Act
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();

        // Assert — in the shared pool, without colours, requested by whoever moved the order.
        $ticket = $this->automaticTicketOf($order);
        $this->assertSame(DesignTicketStatus::New, $ticket->status);
        $this->assertSame((int) $order->customer_id, (int) $ticket->customer_id);
        $this->assertStringContainsString((string) $order->code, $ticket->title);
        $this->assertNull($ticket->assigned_designer_id);
        $this->assertNull($ticket->print_colors);
        $this->assertSame((int) $user->id, (int) $ticket->requested_by_user_id);
    }

    public function test_an_order_with_an_open_ticket_gets_no_second_one(): void
    {
        // Arrange — somebody opened one by hand while the order was «بدون عربون».
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer());
        DesignTicket::factory()->create(['customer_id' => $order->customer_id, 'order_id' => $order->id]);

        // Act
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();

        // Assert
        $this->assertSame(1, DesignTicket::query()->where('order_id', $order->id)->count());
    }

    public function test_a_correction_trip_back_opens_a_fresh_ticket(): void
    {
        // Arrange — at the press's door, the earlier ticket long approved.
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer(), OrderStatus::ReadyToPrint);
        $order->forceFill(['stock_deducted_at' => now()])->save();
        DesignTicket::factory()->create([
            'customer_id' => $order->customer_id,
            'order_id' => $order->id,
            'status' => DesignTicketStatus::Cancelled,
            'cancellation_reason' => 'قديمة',
        ]);

        // Act
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();

        // Assert
        $this->assertSame(DesignTicketStatus::New, $this->automaticTicketOf($order)->status);
    }

    public function test_the_designer_gives_the_colours_with_the_first_version(): void
    {
        // Arrange
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $ticket = $this->automaticTicketOf($order);
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        // Act — a version with no colours.
        $response = $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['files' => $this->versionImages('v1.png')],
            $designer + ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
    }

    // ───────────────────────────── closing ─────────────────────────────

    public function test_moving_on_by_hand_cancels_an_automatic_ticket_nobody_worked_on(): void
    {
        // Arrange — the customer sent the final file; it is on the order, approved.
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $this->approvedDesignOn($order);

        // Act
        $response = $this->move($order->refresh(), OrderStatus::Preparing, $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'preparing');
        $ticket = $this->automaticTicketOf($order);
        $this->assertSame(DesignTicketStatus::Cancelled, $ticket->status);
        $this->assertSame('أُلغيت لأن الطلبية خرجت من «قيد التصميم»', $ticket->cancellation_reason);
    }

    public function test_an_automatic_ticket_with_a_version_still_holds_the_order(): void
    {
        // Arrange — a designer has submitted work.
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $this->submitVersion($this->automaticTicketOf($order), $designer);
        $this->approvedDesignOn($order);

        // Act
        $response = $this->move($order->refresh(), OrderStatus::Preparing, $headers);

        // Assert — refused, and the designer's work is still open for review.
        $response->assertStatus(422)->assertJsonValidationErrors('design_ticket');
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
        $this->assertSame(DesignTicketStatus::UnderReview, $this->automaticTicketOf($order)->status);
    }

    public function test_a_ticket_a_person_opened_still_holds_the_order(): void
    {
        // Arrange
        [, $headers] = $this->foreman();
        $order = $this->orderFor($this->customer(), OrderStatus::Designing);
        $manual = DesignTicket::factory()->create(['customer_id' => $order->customer_id, 'order_id' => $order->id]);
        $this->approvedDesignOn($order);

        // Act
        $response = $this->move($order, OrderStatus::Preparing, $headers);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_ticket');
        $this->assertSame(DesignTicketStatus::New, $manual->fresh()->status);
    }

    public function test_cancelling_the_order_cancels_its_automatic_ticket(): void
    {
        // Arrange — even one a designer is working on.
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $this->submitVersion($this->automaticTicketOf($order), $designer);

        // Act
        $this->move($order->refresh(), OrderStatus::Cancelled, $headers, ['reason' => 'الزبون تراجع'])->assertOk();

        // Assert
        $ticket = $this->automaticTicketOf($order);
        $this->assertSame(DesignTicketStatus::Cancelled, $ticket->status);
        $this->assertSame('أُلغيت لأن الطلبية أُلغيت', $ticket->cancellation_reason);
    }

    // ───────────────────────────── approval ─────────────────────────────

    public function test_approving_the_design_moves_the_order_to_preparing(): void
    {
        // Arrange — the person who moved the order reviews the ticket it opened.
        $this->withAutomaticTickets();
        [$reviewer, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $ticket = $this->automaticTicketOf($order);
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $headers)->assertOk();

        // Assert — moved, stamped, and the reviewer named on the timeline.
        $order->refresh();
        $this->assertSame(OrderStatus::Preparing, $order->status);
        $this->assertNotNull($order->preparing_started_at);
        // Both images of the version, approved together as one design number.
        $faces = OrderDesign::query()->where('order_id', $order->id)->orderBy('face')->get();
        $this->assertSame([1, 2], $faces->pluck('face')->all());
        $this->assertSame([1, 1], $faces->pluck('version')->all());
        $this->assertTrue($faces->every(fn (OrderDesign $face) => $face->status === OrderDesignStatus::Approved));
        $transition = OrderStatusTransition::query()
            ->where('order_id', $order->id)
            ->where('to_status', OrderStatus::Preparing->value)
            ->sole();
        $this->assertSame((int) $reviewer->id, (int) $transition->user_id);
    }

    public function test_the_approval_stands_when_the_order_cannot_move_on(): void
    {
        // Arrange — a second ticket, opened by a person, is still open on the order.
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $ticket = $this->automaticTicketOf($order);
        DesignTicket::factory()->create(['customer_id' => $order->customer_id, 'order_id' => $order->id]);
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $response = $this->approve($ticket, $versionId, $headers);

        // Assert — approved; the order waits for a person.
        $response->assertOk();
        $this->assertSame(DesignTicketStatus::Completed, $ticket->fresh()->status);
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
    }

    public function test_a_ticket_opened_in_design_moves_the_order_on_approval(): void
    {
        // Arrange — the switch off; a person opens the ticket while the order is in «قيد التصميم».
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), OrderStatus::Designing);
        $ticket = $this->openTicketOn($order, $headers);
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $headers)->assertOk();

        // Assert
        $this->assertSame(OrderStatus::Preparing, $order->fresh()->status);
    }

    public function test_a_ticket_opened_awaiting_deposit_leaves_the_order_where_it_is(): void
    {
        // Arrange
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), OrderStatus::AwaitingDeposit);
        $ticket = $this->openTicketOn($order, $headers);
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $headers)->assertOk();

        // Assert — approved, the design on the order, the status untouched.
        $this->assertSame(DesignTicketStatus::Completed, $ticket->fresh()->status);
        $this->assertSame(OrderStatus::AwaitingDeposit, $order->fresh()->status);
        $this->assertTrue(
            OrderDesign::query()->where('order_id', $order->id)->where('status', OrderDesignStatus::Approved)->exists(),
        );
    }

    public function test_a_ticket_opened_before_design_does_not_move_the_order_once_it_is_there(): void
    {
        // Arrange — opened in «بانتظار العربون»; the order reached «قيد التصميم» afterwards.
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), OrderStatus::AwaitingDeposit);
        $ticket = $this->openTicketOn($order, $headers);
        $order->forceFill(['status' => OrderStatus::Designing])->save();
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $headers)->assertOk();

        // Assert
        $this->assertSame(DesignTicketStatus::Completed, $ticket->fresh()->status);
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
    }

    public function test_an_outsourced_order_stays_in_design_after_approval(): void
    {
        // Arrange — the وسيط road has no «بانتظار التجهيز».
        $this->withAutomaticTickets();
        [, $headers] = $this->foreman();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), OrderStatus::NoDeposit, OrderFlow::Outsourced);
        $this->move($order, OrderStatus::Designing, $headers)->assertOk();
        $ticket = $this->automaticTicketOf($order);
        $versionId = $this->submitVersion($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $headers)->assertOk();

        // Assert
        $this->assertSame(OrderStatus::Designing, $order->fresh()->status);
    }
}
