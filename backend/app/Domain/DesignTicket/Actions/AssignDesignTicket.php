<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Events\DesignTicketAssigned;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;

/**
 * Puts a ticket in somebody's queue, moves it to somebody else's, or returns it to the pool.
 *
 * **One action for all three**, because they are one fact with three values — assigning,
 * reassigning and unassigning differ only in what the column ends up holding, and splitting them
 * would mean three endpoints and three permissions for one column. The shape `AssignShortage`
 * settled on.
 *
 * **It does not change the status, and that is the difference from `AssignShortage`.** There,
 * assigning meant work had started, so «جديد» became «جاري البحث». Here the equivalent claim is
 * made by the designer accepting, not by a supervisor routing — the whole reason the acceptance
 * step exists. A ticket addressed to somebody who has not yet said yes is still «جديد», and
 * saying otherwise would make «جديد: ١٢» count work nobody has agreed to do.
 *
 * **Reassigning after acceptance does not take the work away.** `accepted_by_user_id` is a record
 * of what happened and is deliberately left alone — see the column's comment. What changes is who
 * the ticket is addressed to next.
 */
final class AssignDesignTicket
{
    /**
     * @throws DesignTicketIsClosed
     */
    public function __invoke(DesignTicket $ticket, ?User $designer, ?User $actor = null): DesignTicket
    {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        $ticket->forceFill(['assigned_designer_id' => $designer?->getKey()])->save();

        // Only for a real assignment. Returning a ticket to the pool is not news anybody needs on
        // their phone, and telling somebody their work was taken away is a different message that
        // nobody has asked for.
        if ($designer !== null) {
            DesignTicketAssigned::dispatch(
                (int) $ticket->getKey(),
                (int) $designer->getKey(),
                $actor === null ? null : (int) $actor->getKey(),
            );
        }

        return $ticket->refresh();
    }
}
