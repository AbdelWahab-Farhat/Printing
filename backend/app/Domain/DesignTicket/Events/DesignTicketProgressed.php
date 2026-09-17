<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Events;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A ticket moved, and the other side of the conversation has not heard yet.
 *
 * **One event for five moves**, the way `OrderReachedStatus` is one notification type for fifteen
 * statuses: acceptance, submission, a change request, a revised version and an approval share a
 * subject, a route and a shape of sentence, and the status itself rides in the payload. Five
 * events would have meant five listeners doing the same lookup.
 *
 * The audience is not decided here — that is the notification definition's job, from `status`.
 * This says only what happened.
 */
final readonly class DesignTicketProgressed
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        public DesignTicketStatus $status,
        public ?int $actorId = null,
    ) {}
}
