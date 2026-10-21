<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Application\Realtime\Events\InternalTicketThreadChanged;
use App\Application\Realtime\Events\StaffInternalTicketsChanged;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Support\Facades\Event;

/**
 * التذاكر الداخلية حيّة: ما يُبثّ إلى المحادثة، وما يُبثّ إلى قناة كل طرف، وبأيّ شكل.
 *
 * **الحمولةُ بلا قارئ** هي ما يُحرس أكثر: البثُّ يقع والكاتبُ ما زال صاحبَ الطلب (`defer`)، فموردٌ
 * يُحلّ بطلبه كان سيقول لزميله إن الرسالة رسالتُه وإنه يملك تعديلها.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketRealtimeTest extends InternalTicketTestCase
{
    private function listen(): void
    {
        Event::fake([InternalTicketThreadChanged::class, StaffInternalTicketsChanged::class]);
    }

    public function test_a_reply_reaches_the_thread_and_both_parties_channels(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->listen();

        // Act
        $this->say($ticket, $theirs, ['body' => 'وصلت'])->assertCreated();

        // Assert
        $message = InternalTicketMessage::query()->latest('id')->firstOrFail();
        Event::assertDispatched(
            InternalTicketThreadChanged::class,
            fn (InternalTicketThreadChanged $e) => $e->ticket->is($ticket)
                && $e->change === InternalTicketChange::MessagePosted
                && $e->message?->is($message)
                && $e->broadcastOn()[0]->name === "private-internal-tickets.{$ticket->id}",
        );
        Event::assertDispatched(
            StaffInternalTicketsChanged::class,
            fn (StaffInternalTicketsChanged $e) => $e->ticketId === $ticket->id
                && array_map(fn ($c) => $c->name, $e->broadcastOn()) === ["private-staff.{$me->id}", "private-staff.{$colleague->id}"],
        );
    }

    public function test_the_payload_belongs_to_nobody(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee('هدى');
        $ticket = $this->open($mine, $colleague);
        $this->listen();

        // Act
        $this->say($ticket, $theirs, ['body' => 'وصلت'])->assertCreated();

        // Assert
        Event::assertDispatched(InternalTicketThreadChanged::class, function (InternalTicketThreadChanged $e): bool {
            $payload = $e->broadcastWith();

            return $payload['change'] === 'message_posted'
                && $payload['message']['is_mine'] === false
                && $payload['message']['can_edit'] === false
                && $payload['message']['mutable_until'] !== null
                && $payload['message']['author']['name'] === 'هدى'
                && $payload['ticket']['read_up_to']['assignee'] === $payload['message']['id']
                && ! array_key_exists('original_body', $payload['message']);
        });
    }

    public function test_reading_is_heard_only_when_something_new_was_read(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->listen();

        // Act
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs)->assertOk();
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs)->assertOk();

        // Assert
        Event::assertDispatchedTimes(InternalTicketThreadChanged::class, 1);
        Event::assertDispatched(
            InternalTicketThreadChanged::class,
            fn (InternalTicketThreadChanged $e) => $e->change === InternalTicketChange::Read,
        );
    }

    public function test_an_edit_and_a_deletion_are_heard_live(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $this->listen();

        // Act
        $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", ['body' => 'معدّلة'], $mine)->assertOk();
        $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", [], $mine)->assertOk();

        // Assert
        Event::assertDispatched(
            InternalTicketThreadChanged::class,
            fn (InternalTicketThreadChanged $e) => $e->change === InternalTicketChange::MessageEdited
                && $e->broadcastWith()['message']['body'] === 'معدّلة',
        );
        Event::assertDispatched(
            InternalTicketThreadChanged::class,
            fn (InternalTicketThreadChanged $e) => $e->change === InternalTicketChange::MessageRetracted
                && $e->broadcastWith()['message']['body'] === 'تم حذف هذه الرسالة',
        );
    }

    public function test_a_transfer_also_tells_the_former_owner(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [$successor] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->listen();

        // Act
        $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $successor->id], $mine)->assertOk();

        // Assert
        Event::assertDispatched(
            StaffInternalTicketsChanged::class,
            fn (StaffInternalTicketsChanged $e) => $e->change === InternalTicketChange::Transferred
                && in_array($me->id, $e->userIds, true)
                && in_array($successor->id, $e->userIds, true)
                && in_array($colleague->id, $e->userIds, true),
        );
    }
}
