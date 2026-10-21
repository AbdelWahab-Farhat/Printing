<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Events\InternalTicketReplyOverdue;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يحمل التذكير إلى مَن يُنتظر ردّه — «فلان ينتظر ردّك» وعنوانُ التذكرة. والقرارُ متى ولمن في
 * `RemindAwaitedParties`؛ هذا يقوله فقط.
 */
final class NotifyWhenInternalTicketReplyIsOverdue implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(InternalTicketReplyOverdue $event): void
    {
        $ticket = InternalTicket::query()->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $waiting = User::query()->withTrashed()->find($event->waitingUserId);

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::InternalTicketReminder,
            subject: $ticket,
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'title' => (string) $ticket->title,
                'awaited_id' => $event->awaitedUserId,
                'waiting_name' => (string) ($waiting?->name ?? ''),
            ],
        ));
    }
}
