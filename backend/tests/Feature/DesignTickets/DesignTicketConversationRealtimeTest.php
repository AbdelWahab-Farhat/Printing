<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Application\Realtime\Events\DesignTicketThreadChanged;
use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use Illuminate\Support\Facades\Event;

/**
 * محادثة التذكرة حيّة، كالتذاكر الداخلية: ما يُبثّ إلى القناة، وبأيّ شكل.
 *
 * **الحمولةُ بلا قارئ** هي ما يُحرس أكثر: البثُّ يقع والكاتبُ ما زال صاحبَ الطلب (`defer`)، فموردٌ
 * يُحلّ بطلبه كان سيقول لزميله إن الرسالة رسالتُه وإنه يملك تعديلها.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class DesignTicketConversationRealtimeTest extends DesignTicketTestCase
{
    public function test_a_reply_reaches_the_thread_channel(): void
    {
        // Arrange
        [$employee] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        Event::fake([DesignTicketThreadChanged::class]);

        // Act
        $this->say($ticket, $designerHeaders, ['body' => 'وصلني'])->assertCreated();

        // Assert
        $message = DesignTicketMessage::query()->sole();
        Event::assertDispatched(
            DesignTicketThreadChanged::class,
            fn (DesignTicketThreadChanged $e) => $e->ticket->is($ticket)
                && $e->change === DesignConversationChange::MessagePosted
                && $e->message?->is($message)
                && $e->broadcastOn()[0]->name === "private-design-tickets.{$ticket->id}",
        );
    }

    public function test_the_payload_belongs_to_nobody(): void
    {
        // Arrange
        [$employee] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        Event::fake([DesignTicketThreadChanged::class]);

        // Act
        $this->say($ticket, $designerHeaders, ['body' => 'وصلني'])->assertCreated();

        // Assert
        Event::assertDispatched(DesignTicketThreadChanged::class, function (DesignTicketThreadChanged $e) use ($designer): bool {
            $payload = $e->broadcastWith();

            return $payload['change'] === 'message_posted'
                && $payload['message']['is_mine'] === false
                && $payload['message']['can_edit'] === false
                && $payload['message']['mutable_until'] !== null
                && $payload['message']['author']['id'] === $designer->id
                && $payload['thread']['read_up_to']['designer'] === $payload['message']['id']
                && ! array_key_exists('original_body', $payload['message']);
        });
    }

    public function test_reading_is_heard_only_when_something_new_was_read(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->assertCreated();
        Event::fake([DesignTicketThreadChanged::class]);

        // Act
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $designerHeaders)->assertOk();
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $designerHeaders)->assertOk();

        // Assert
        Event::assertDispatchedTimes(DesignTicketThreadChanged::class, 1);
        Event::assertDispatched(
            DesignTicketThreadChanged::class,
            fn (DesignTicketThreadChanged $e) => $e->change === DesignConversationChange::Read,
        );
    }

    public function test_an_edit_and_a_deletion_are_heard_live(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الأسود'])->json('data.messages.0.id');
        Event::fake([DesignTicketThreadChanged::class]);

        // Act
        $this->patchJson("/api/v1/design-tickets/{$ticket->id}/messages/{$id}", ['body' => 'معدّلة'], $employeeHeaders)
            ->assertOk();
        $this->deleteJson("/api/v1/design-tickets/{$ticket->id}/messages/{$id}", [], $employeeHeaders)->assertOk();

        // Assert
        Event::assertDispatched(
            DesignTicketThreadChanged::class,
            fn (DesignTicketThreadChanged $e) => $e->change === DesignConversationChange::MessageEdited
                && $e->broadcastWith()['message']['body'] === 'معدّلة',
        );
        Event::assertDispatched(
            DesignTicketThreadChanged::class,
            fn (DesignTicketThreadChanged $e) => $e->change === DesignConversationChange::MessageRetracted
                && $e->broadcastWith()['message']['body'] === 'تم حذف هذه الرسالة',
        );
    }
}
