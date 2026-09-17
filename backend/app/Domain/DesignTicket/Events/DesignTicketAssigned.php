<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Events;

use App\Domain\DesignTicket\Actions\AssignDesignTicket;
use App\Domain\DesignTicket\Actions\CreateDesignTicket;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A design request has landed in somebody's queue — or in everybody's.
 *
 * **An event rather than a call, for the direction rule.** The reactor is the notification
 * centre, and DesignTicket must not import it: Notification already reads this context to render
 * a sentence, and letting it be read back would make the two mutually dependent. The shape
 * `ShortageAssigned` established.
 *
 * `designerId` is null when the ticket went to the shared pool, and that is not missing data —
 * it is what tells the notification to address every designer rather than one. Fired by both
 * {@see CreateDesignTicket} and {@see AssignDesignTicket}, because "there is work for you" is the
 * same news whichever of them produced it.
 *
 * Carries the actor so a designer who claims work for themselves is not told about it by their
 * own phone — `notifiesCauser()` acts on that, and can only do so if both ids are here.
 */
final readonly class DesignTicketAssigned
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        /** Null means the shared pool: every holder of `design_tickets.accept`. */
        public ?int $designerId = null,
        public ?int $actorId = null,
    ) {}
}
