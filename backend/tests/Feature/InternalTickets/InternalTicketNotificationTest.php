<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Notification\Models\NotificationRecipient;

/**
 * الجرس: تذكرةٌ جديدة لمن وُجّهت إليه، ورسالةٌ للطرف الآخر وحده، ولا شيء على التعديل والحذف.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketNotificationTest extends InternalTicketTestCase
{
    /**
     * @return list<int>
     */
    private function recipientsOf(Notification $notification): array
    {
        return $notification->recipients()->pluck('user_id')->map(fn ($id) => (int) $id)->all();
    }

    public function test_a_new_ticket_rings_the_colleague_it_was_sent_to(): void
    {
        // Arrange
        [, $mine] = $this->employee('سالم');
        [$colleague] = $this->employee();
        $this->employee('غريب');

        // Act
        $ticket = $this->open($mine, $colleague, ['title' => 'فاتورة المطبعة']);

        // Assert
        $notification = Notification::query()->sole();
        $this->assertSame(NotificationType::InternalTicketOpened, $notification->type);
        $this->assertSame('internal_ticket', $notification->subject_type);
        $this->assertSame($ticket->id, $notification->subject_id);
        $this->assertSame([$colleague->id], $this->recipientsOf($notification));
        $this->assertSame('تذكرة جديدة من سالم', $this->rendered($notification)->title);
        $this->assertSame('فاتورة المطبعة', $this->rendered($notification)->body);
        $this->assertSame("/internal-tickets/{$ticket->id}", $this->rendered($notification)->route);
    }

    public function test_a_reply_rings_the_other_side_alone_without_quoting_it(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee('هدى');
        $ticket = $this->open($mine, $colleague, ['title' => 'المخزن']);

        // Act
        $this->say($ticket, $theirs, ['body' => 'سرّ لا يُقال على شاشةٍ مقفلة'])->assertCreated();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::InternalTicketMessage)->sole();
        $this->assertSame([$me->id], $this->recipientsOf($notification));
        $this->assertSame('هدى · المخزن', $this->rendered($notification)->title);
        $this->assertStringNotContainsString('سرّ', (string) $this->rendered($notification)->body);
    }

    public function test_a_voice_note_says_so_in_the_bell(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $this->say($ticket, $theirs, ['file' => $this->voice(), 'duration_seconds' => 9])->assertCreated();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::InternalTicketMessage)->sole();
        $this->assertSame('🎤 رسالة صوتية', $this->rendered($notification)->body);
    }

    public function test_messages_in_a_row_are_one_bell_until_they_are_read(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $this->say($ticket, $theirs, ['body' => 'السلام عليكم'])->assertCreated();
        $this->say($ticket, $theirs, ['body' => 'وصلت'])->assertCreated();
        $before = Notification::query()->where('type', NotificationType::InternalTicketMessage)->count();
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine)->assertOk();
        $this->say($ticket, $theirs, ['body' => 'شيء آخر'])->assertCreated();

        // Assert
        $this->assertSame(1, $before);
        $this->assertSame(2, Notification::query()->where('type', NotificationType::InternalTicketMessage)->count());
    }

    public function test_editing_and_deleting_ring_nothing(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $before = Notification::query()->count();

        // Act
        $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", ['body' => 'تصحيح'], $mine)->assertOk();
        $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", [], $mine)->assertOk();

        // Assert
        $this->assertSame($before, Notification::query()->count());
    }

    public function test_opening_the_thread_silences_its_bells_for_that_reader(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs)->assertOk();

        // Assert
        $unread = NotificationRecipient::query()->where('user_id', $colleague->id)->whereNull('read_at')->count();
        $this->assertSame(0, $unread);
    }
}
