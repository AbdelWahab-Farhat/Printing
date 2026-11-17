<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Carbon;

/**
 * `status_changed_at`: when a ticket's status last moved, and the order of the list.
 *
 * Every move is driven through the real endpoints, a minute apart, so each assertion proves that
 * this move stamped the column and not an earlier one.
 *
 * Arrange - Act - Assert.
 */
class DesignTicketStatusChangedAtTest extends DesignTicketTestCase
{
    private function stampOf(DesignTicket $ticket): string
    {
        return $ticket->refresh()->status_changed_at->toDateTimeString();
    }

    /** Moves the clock a minute on, and returns the new now as the column would hold it. */
    private function aMinuteLater(): string
    {
        $this->travel(1)->minutes();

        return Carbon::now()->toDateTimeString();
    }

    /** @param array<string, string> $headers */
    private function raise(array $headers, array $overrides = []): DesignTicket
    {
        return DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($this->customer(), $overrides), $headers)
                ->assertCreated()
                ->json('data.id'),
        );
    }

    public function test_a_new_ticket_is_stamped_when_it_is_raised(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $now = $this->aMinuteLater();

        // Act
        $ticket = $this->raise($employee);

        // Assert
        $this->assertSame($now, $this->stampOf($ticket));
        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee)
            ->assertOk()
            ->assertJsonPath('data.status_changed_at', $ticket->status_changed_at->toIso8601String());
    }

    public function test_every_move_along_the_road_stamps_it_acceptance_included(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->raise($employee);

        // Act + Assert — acceptance is a query-builder update, the one path the model hook misses.
        $at = $this->aMinuteLater();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();
        $this->assertSame($at, $this->stampOf($ticket));

        $at = $this->aMinuteLater();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/versions", ['file' => $this->image('v1.png')], $designer)
            ->assertCreated();
        $this->assertSame($at, $this->stampOf($ticket));

        $at = $this->aMinuteLater();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$ticket->versions()->sole()->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'كبّر الشعار'],
            $employee,
        )->assertOk();
        $this->assertSame(DesignTicketStatus::ChangesRequested, $ticket->refresh()->status);
        $this->assertSame($at, $this->stampOf($ticket));

        $at = $this->aMinuteLater();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/versions", ['file' => $this->image('v2.png')], $designer)
            ->assertCreated();
        $this->assertSame($at, $this->stampOf($ticket));

        $at = $this->aMinuteLater();
        $pending = $ticket->pendingVersion();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$pending->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();
        $this->assertSame(DesignTicketStatus::Completed, $ticket->refresh()->status);
        $this->assertSame($at, $this->stampOf($ticket));
    }

    public function test_a_withdrawal_and_a_cancellation_stamp_it(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->ticketAwaitingReview($this->raise($employee), $designer);

        // Act + Assert
        $at = $this->aMinuteLater();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$ticket->versions()->sole()->id}/withdrawal",
            [],
            $designer,
        )->assertOk();
        $this->assertSame(DesignTicketStatus::InProgress, $ticket->refresh()->status);
        $this->assertSame($at, $this->stampOf($ticket));

        $at = $this->aMinuteLater();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/cancellation", ['reason' => 'ألغى العميل'], $employee)
            ->assertOk();
        $this->assertSame($at, $this->stampOf($ticket));
    }

    public function test_returning_a_taken_ticket_to_the_pool_stamps_it(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->raise($employee);
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        // Act
        $at = $this->aMinuteLater();
        $this->patchJson("/api/v1/design-tickets/{$ticket->id}/designer", ['assigned_designer_id' => null], $employee)
            ->assertOk();

        // Assert
        $this->assertSame(DesignTicketStatus::New, $ticket->refresh()->status);
        $this->assertSame($at, $this->stampOf($ticket));
    }

    public function test_a_message_reading_the_chat_or_editing_the_ticket_does_not_move_it(): void
    {
        // Arrange
        [$requester, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $ticket = $this->conversationBetween($requester, $designerUser);
        $before = $this->stampOf($ticket);

        // Act
        $this->aMinuteLater();
        $this->say($ticket, $employee, ['body' => 'هل وصلك الشعار؟'])->assertCreated();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/messages/read", [], $designer)->assertOk();
        $this->putJson("/api/v1/design-tickets/{$ticket->id}", ['title' => 'عنوان جديد', 'description' => $ticket->description], $employee)->assertOk();
        $this->patchJson("/api/v1/design-tickets/{$ticket->id}/pay", ['designer_pay' => '25'], $employee)->assertOk();

        // Assert — the row moved, the stamp did not.
        $ticket->refresh();
        $this->assertSame('عنوان جديد', $ticket->title);
        $this->assertSame($before, $ticket->status_changed_at->toDateTimeString());
    }

    public function test_the_list_puts_the_latest_status_change_first(): void
    {
        // Arrange — three tickets raised in order, then the oldest one is taken.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $oldest = $this->raise($employee);
        $this->aMinuteLater();
        $middle = $this->raise($employee);
        $this->aMinuteLater();
        $newest = $this->raise($employee);
        $this->aMinuteLater();
        $this->postJson("/api/v1/design-tickets/{$oldest->id}/acceptance", [], $designer)->assertOk();

        // Act
        $response = $this->getJson('/api/v1/design-tickets', $employee);

        // Assert
        $response->assertOk();
        $this->assertSame([$oldest->id, $newest->id, $middle->id], array_column($response->json('data'), 'id'));
    }

    public function test_tickets_that_moved_in_the_same_second_fall_back_to_the_newest_id(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $first = $this->raise($employee);
        $second = $this->raise($employee);

        // Act
        $response = $this->getJson('/api/v1/design-tickets', $employee);

        // Assert
        $this->assertSame([$second->id, $first->id], array_column($response->json('data'), 'id'));
    }

    public function test_the_order_screen_dates_a_design_ticket_by_its_last_status_change(): void
    {
        // Arrange
        [$requester, $employee] = $this->actor(
            PermissionName::ViewOrders,
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ManageDesignTickets,
        );
        [$designerUser, $designer] = $this->designer();
        $order = Order::factory()->create();
        $ticket = DesignTicket::factory()->acceptedBy((int) $designerUser->getKey())
            ->create(['order_id' => $order->id, 'requested_by_user_id' => $requester->getKey()]);
        $stamp = $ticket->refresh()->status_changed_at->toIso8601String();

        // Act — opening the conversation moves `updated_at`, which the section used to read.
        $this->aMinuteLater();
        $this->say($ticket, $employee, ['body' => 'هل وصلك الشعار؟'])->assertCreated();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/messages/read", [], $designer)->assertOk();
        $response = $this->getJson("/api/v1/orders/{$order->id}/tickets", $employee);

        // Assert
        $response->assertOk()->assertJsonPath('data.0.activity_at', $stamp);
    }
}
