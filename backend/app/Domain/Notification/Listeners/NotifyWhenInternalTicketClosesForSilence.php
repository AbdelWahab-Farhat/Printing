<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\InternalTicket\Events\InternalTicketClosedForSilence;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر الطرفين أن تذكرتهما أُغلقت لعدم الردّ — «أُغلقت التذكرة لعدم الردّ» وعنوانُها. والقرارُ
 * متى في `CloseSilentInternalTickets`؛ هذا يقوله فقط.
 */
final class NotifyWhenInternalTicketClosesForSilence implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(InternalTicketClosedForSilence $event): void
    {
        $ticket = InternalTicket::query()->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::InternalTicketClosedForSilence,
            subject: $ticket,
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'title' => (string) $ticket->title,
                'party_ids' => [(int) $ticket->opened_by, (int) $ticket->assignee_id],
            ],
        ));
    }
}
