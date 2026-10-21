<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\InternalTicket\Models\InternalTicketMessage;

/**
 * علامة القراءة، والإغلاق، والتحويل، وبطاقة الرئيسية، والسجلّ.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketLifecycleTest extends InternalTicketTestCase
{
    // ─────────────────────────── القراءة ───────────────────────────

    public function test_opening_the_thread_marks_it_read_and_shows_my_message_as_read_to_me(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $first = InternalTicketMessage::query()->firstOrFail();

        // Act
        $before = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine);
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs)->assertOk();
        $after = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine);

        // Assert
        $before->assertJsonPath('data.counterpart_read_up_to', null);
        $after->assertJsonPath('data.counterpart_read_up_to', $first->id);
        $this->assertSame($first->id, $ticket->refresh()->assignee_read_message_id);
    }

    public function test_an_admin_reading_someone_elses_thread_moves_nobodys_cursor(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [, $admin] = $this->admin();
        $ticket = $this->open($mine, $colleague);

        // Act
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $admin)->assertOk();

        // Assert
        $this->assertNull($ticket->refresh()->assignee_read_message_id);
    }

    public function test_the_read_endpoint_stops_at_what_was_on_screen_and_never_goes_back(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->say($ticket, $mine, ['body' => 'ثانية'])->assertCreated();
        [$first, $second] = InternalTicketMessage::query()->orderBy('id')->pluck('id')->all();

        // Act
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/read", ['up_to_message_id' => $second], $theirs)->assertOk();
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/read", ['up_to_message_id' => $first], $theirs)->assertOk();

        // Assert
        $this->assertSame($second, $ticket->refresh()->assignee_read_message_id);
    }

    // ─────────────────────────── الإغلاق ───────────────────────────

    public function test_either_party_closes_and_closing_twice_keeps_the_first_name(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $first = $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $theirs);
        $second = $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine);

        // Assert
        $first->assertOk()->assertJsonPath('data.status', 'closed')->assertJsonPath('data.can_reply', false);
        $second->assertOk();
        $this->assertSame($colleague->id, $ticket->refresh()->closed_by);
        $this->assertNotSame($me->id, $ticket->closed_by);
    }

    public function test_an_admin_closes_a_ticket_they_are_not_part_of(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [, $admin] = $this->admin();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $admin);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'closed');
    }

    // ─────────────────────────── التحويل ───────────────────────────

    public function test_the_owner_hands_the_ticket_to_someone_who_takes_their_place(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [$successor, $successorHeaders] = $this->employee('خليفة');
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $successor->id], $mine);
        $successorView = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $successorHeaders);
        $formerView = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine);

        // Assert
        $response->assertOk()->assertJsonPath('data.opener.name', 'خليفة');
        $ticket->refresh();
        $this->assertSame($successor->id, $ticket->opened_by);
        $this->assertSame($colleague->id, $ticket->assignee_id);
        $successorView->assertOk()->assertJsonPath('data.can_reply', true);
        // صاحبها السابق خرج منها.
        $formerView->assertNotFound();
        $this->assertNotSame($me->id, $ticket->opened_by);
    }

    public function test_the_new_owner_starts_with_everything_unread(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        [$successor, $successorHeaders] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->say($ticket, $theirs, ['body' => 'وصلت'])->assertCreated();

        // Act
        $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $successor->id], $mine)->assertOk();
        $list = $this->getJson('/api/v1/internal-tickets', $successorHeaders);

        // Assert
        $this->assertNull($ticket->refresh()->opener_read_message_id);
        // رسالةُ الزميل، ورسالةُ الصاحب السابق — كلتاهما من غيره.
        $list->assertJsonPath('data.0.unread_count', 2);
    }

    public function test_only_the_owner_or_an_admin_transfers(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        [$someone] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $someone->id], $theirs);

        // Assert
        $response->assertForbidden()->assertJsonPath('message', 'يحوّل التذكرة صاحبُها وحده');
    }

    public function test_a_ticket_cannot_be_handed_to_its_assignee_or_owner(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $toAssignee = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $colleague->id], $mine);
        $toMe = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $me->id], $mine);

        // Assert
        $toAssignee->assertUnprocessable()->assertJsonValidationErrors(['new_owner_id']);
        $toMe->assertUnprocessable()->assertJsonValidationErrors(['new_owner_id']);
    }

    public function test_a_closed_ticket_is_not_transferred(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [$someone] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine)->assertOk();

        // Act
        $response = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $someone->id], $mine);

        // Assert
        $response->assertUnprocessable();
    }

    // ─────────────────────────── بطاقة الرئيسية ───────────────────────────

    public function test_the_home_card_lists_what_waits_on_me_from_both_sides(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        // وُجّهت إليّ: آخرُ كلامٍ فيها لزميلي — تنتظرني.
        $sentToMe = $this->open($theirs, $me);
        // فتحتُها أنا وردّ الزميل — تنتظرني أيضاً.
        $answered = $this->open($mine, $colleague);
        $this->say($answered, $theirs, ['body' => 'جاهز'])->assertCreated();
        // فتحتُها ولم يُردّ — تنتظر زميلي لا أنا.
        $this->open($mine, $colleague);

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/home', $mine);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.awaiting_my_reply', 2)
            ->assertJsonPath('data.total_open', 3)
            ->assertJsonPath('data.unread_tickets', 2)
            ->assertJsonPath('data.has_more', false)
            ->assertJsonPath('data.tickets.0.id', $answered->id)
            ->assertJsonPath('data.tickets.1.id', $sentToMe->id)
            ->assertJsonPath('data.tickets.0.awaiting_my_reply', true);
    }

    public function test_the_home_card_shows_ten_and_says_there_are_more(): void
    {
        // Arrange
        [$me] = $this->employee();
        [, $theirs] = $this->employee();
        foreach (range(1, 11) as $i) {
            $this->open($theirs, $me, ['title' => "سؤال {$i}"]);
        }

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/home', $this->headersOf($me));

        // Assert
        $response->assertJsonCount(10, 'data.tickets')
            ->assertJsonPath('data.awaiting_my_reply', 11)
            ->assertJsonPath('data.has_more', true);
    }

    public function test_closed_tickets_leave_the_home_card(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $theirs)->assertOk();

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/home', $mine);

        // Assert
        $response->assertJsonPath('data.awaiting_my_reply', 0)->assertJsonPath('data.total_open', 0);
    }

    // ─────────────────────────── السجلّ ───────────────────────────

    public function test_the_history_needs_logs_view_and_visibility_both(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [$auditor, $auditorHeaders] = $this->employee();
        $me->givePermissionTo(PermissionName::ViewActivityLogs->value);
        $auditor->givePermissionTo(PermissionName::ViewActivityLogs->value);
        $ticket = $this->open($mine, $colleague);

        // Act
        $party = $this->getJson("/api/v1/internal-tickets/{$ticket->id}/logs", $mine);
        $outsider = $this->getJson("/api/v1/internal-tickets/{$ticket->id}/logs", $auditorHeaders);
        $noGrant = $this->getJson("/api/v1/internal-tickets/{$ticket->id}/logs", $this->headersOf($colleague));

        // Assert
        $party->assertOk();
        $this->assertNotEmpty($party->json('data'));
        $outsider->assertNotFound();
        $noGrant->assertForbidden();
    }
}
