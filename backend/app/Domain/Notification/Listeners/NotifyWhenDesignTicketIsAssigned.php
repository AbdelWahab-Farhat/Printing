<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\DesignTicket\Events\DesignTicketAssigned;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * Tells a designer — or every designer — that there is artwork to draw.
 *
 * Lives in Notification rather than in DesignTicket, like every other listener here: this context
 * reads the ones it reacts to, and none of them may read it back.
 *
 * **No dedupe key.** `NotifyWhenOrderEntersShortage` carries one because an order bounces in and
 * out of «نواقص» while somebody works on it and the news is identical each time. Reassignment is
 * the opposite: each one is addressed to a different person, and suppressing the second would
 * mean the second person was never told.
 *
 * Queued and after commit, for the reason its neighbours spell out — a notification about a
 * transaction that later rolled back cannot be taken back.
 */
final class NotifyWhenDesignTicketIsAssigned implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(DesignTicketAssigned $event): void
    {
        $ticket = DesignTicket::query()->find($event->ticketId);

        // It can have gone between the commit and this job running. Nothing to say about work
        // that no longer exists.
        if ($ticket === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::DesignTicketAssigned,
            subject: $ticket,
            // Frozen now, so the sentence still reads correctly after the ticket is approved or
            // renamed — and so the list needs no joins to render.
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'code' => $ticket->code,
                'title' => $ticket->title,
                'customer_name' => $ticket->customer_name,
                // Null is the shared pool, and the definition reads it to choose its audience.
                'designer_id' => $event->designerId,
            ],
            causerId: $event->actorId,
        ));
    }
}
