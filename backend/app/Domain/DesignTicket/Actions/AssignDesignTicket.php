<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
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
 * **Addressing an unaccepted ticket to somebody makes it «مُسنَد», and taking the name off makes
 * it «جديد» again.** It used to leave the status at «جديد», on the grounds that only the
 * designer's «قبول» says work has started. That stays true — «مُسنَد» is not «قيد التصميم», and
 * acceptance is still the step that moves it there — but from the outside an addressed ticket was
 * indistinguishable from one nobody had routed, so a supervisor could not see which tickets still
 * needed a designer. «جديد» now means exactly that: addressed to nobody, taken by nobody.
 *
 * Once a designer has accepted, assigning somebody else leaves the status alone: the ticket is
 * past routing, and its status describes the work.
 *
 * **Returning an accepted ticket to the pool releases the claim, not just the address**, and the
 * three columns move together because the pool is defined by all of them: `FiltersDesignTickets`
 * calls it `assigned_designer_id IS NULL AND accepted_at IS NULL`. Clearing
 * only the first is what this action used to do, and it produced a ticket that was in nobody's
 * queue and in no pool — invisible to every designer except the one it had just been taken from,
 * while «قيد التصميم» still counted it as work in hand. A lost ticket, which is the one failure
 * this whole feature exists to prevent.
 *
 * **This overturns an earlier decision that `accepted_by_user_id` is «a record of what happened»
 * and must survive a reassignment.** That record is real, but it belongs to the audit trail, which
 * already holds the acceptance and the release with their causers and their times. These columns
 * describe where the ticket stands *now*; keeping a stale claim in them to preserve history
 * duplicates the log and breaks the queue.
 *
 * **It is the one thing that moves a ticket back to «جديد»**, against the rule
 * {@see DesignTicketStatus::allowedNext()} states — that «جديد» is unreachable from everywhere,
 * because a count that could go up «for reasons nobody did» is a lie. This is the exception that
 * proves it: a release is something a person did, under their own name, and the ticket genuinely
 * is unclaimed again. The map itself is left alone deliberately — no design-ticket action guards
 * against it, and listing «جديد» there would publish it in `available_transitions` as a move the
 * app could offer, which it must never be.
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

        // Only a ticket somebody had actually taken has a claim to release.
        $releasesClaim = $designer === null && $ticket->isAccepted();

        // An unaccepted ticket's status is its routing: «مُسنَد» with a name, «جديد» without.
        // An accepted one keeps its status unless the claim is released.
        $status = match (true) {
            $releasesClaim => DesignTicketStatus::New,
            $ticket->isAccepted() => $ticket->status,
            default => $designer === null ? DesignTicketStatus::New : DesignTicketStatus::Assigned,
        };

        $ticket->forceFill([
            'assigned_designer_id' => $designer?->getKey(),
            ...$releasesClaim ? [
                'accepted_by_user_id' => null,
                'accepted_at' => null,
            ] : [],
            // Writing the value it already holds is not dirty, so a reassignment between two
            // designers puts no status change in the history and does not reset its time.
            // Any versions already uploaded stay on a released ticket: they are what the next
            // designer needs in order not to start the job twice.
            'status' => $status,
        ])->save();

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
