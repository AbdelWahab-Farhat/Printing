<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Notification\Definitions\DesignTicketReachedStatus;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * Tells whichever side of a ticket is now being waited on.
 *
 * **Both parties travel in the payload**, and the definition picks between them from the status —
 * see {@see DesignTicketReachedStatus}. The alternative,
 * resolving the recipient here, would put half the rule in a listener and half in a definition,
 * which is exactly the split that makes a notification hard to change later.
 *
 * **A dedupe key on the ticket and the status**, unlike its neighbour. A ticket does bounce: a
 * designer who uploads, is asked for a change and uploads again produces «وصل تصميم للمراجعة»
 * twice, and inside the storm window those really are the same news. Across a longer revision
 * round the window has passed and both are sent, which is the behaviour wanted.
 *
 * Queued and after commit — an approval that rolled back must never have been announced.
 */
final class NotifyWhenDesignTicketProgresses implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(DesignTicketProgressed $event): void
    {
        $ticket = DesignTicket::query()->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::DesignTicketStatus,
            subject: $ticket,
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'code' => $ticket->code,
                'title' => $ticket->title,
                'customer_name' => $ticket->customer_name,
                'status' => $event->status->value,
                // Both sides. Which one hears is the definition's to decide, because that is a
                // fact about the message rather than about the event.
                'requester_id' => $ticket->requested_by_user_id,
                // Whoever is actually doing the work: after a reassignment that is the person who
                // accepted, not the one the ticket is now addressed to.
                'designer_id' => $ticket->accepted_by_user_id ?? $ticket->assigned_designer_id,
            ],
            causerId: $event->actorId,
        ));
    }
}
