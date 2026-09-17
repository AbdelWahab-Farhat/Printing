<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Exceptions\DesignTicketAlreadyAccepted;
use App\Domain\DesignTicket\Exceptions\DesignTicketBelongsToAnotherDesigner;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;

/**
 * A designer says «أنا آخذها».
 *
 * **The step the brief asks for by name**, and the reason is operational rather than
 * bureaucratic: «الهدف من القبول هو معرفة أن أحد المصممين استلم الطلب فعليًا، ومنع ضياع الطلب أو
 * عمل أكثر من شخص عليه». A queue where anybody can start drawing without saying so produces two
 * designers on one bag and a request nobody realises was dropped.
 *
 * **The race is settled by the database, not by the check.**
 *
 * Two designers tapping «قبول» on a pool ticket within the same second both pass a PHP check
 * before either commits — that is the classic lost update, and RULES §8 is explicit that a rule
 * which loses to concurrency belongs in the database. So the write is a conditional update whose
 * `WHERE accepted_at IS NULL` is the actual arbiter: exactly one of the two statements affects a
 * row, and the other is told who won. The check above it is not redundant either — it is what
 * turns the common, uncontended case into a message naming the holder rather than a silent no-op.
 *
 * **Accepting does not require having been assigned**, unless somebody was: a ticket addressed to
 * nobody is the shared pool and belongs to whoever reaches it first, while one addressed to a
 * named designer is refused to everybody else. Both rules live in
 * {@see DesignTicket::isWorkableBy()}, because the app asks the same question to decide whether
 * to draw the button.
 */
final class AcceptDesignTicket
{
    /**
     * @throws DesignTicketIsClosed
     * @throws DesignTicketAlreadyAccepted
     * @throws DesignTicketBelongsToAnotherDesigner
     */
    public function __invoke(DesignTicket $ticket, User $designer): DesignTicket
    {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        if ($ticket->isAccepted()) {
            throw DesignTicketAlreadyAccepted::make($ticket->acceptedBy?->name);
        }

        if (! $ticket->isWorkableBy($designer)) {
            throw DesignTicketBelongsToAnotherDesigner::make();
        }

        $now = now();

        // The arbiter. `update()` on a filtered builder rather than on the model, so the
        // condition travels to PostgreSQL instead of being evaluated here.
        $claimed = DesignTicket::query()
            ->whereKey($ticket->getKey())
            ->whereNull('accepted_at')
            ->update([
                'accepted_by_user_id' => $designer->getKey(),
                'accepted_at' => $now,
                'status' => DesignTicketStatus::InProgress,
                'updated_at' => $now,
            ]);

        // Somebody else's statement landed first. Re-read before naming them: the model in hand
        // still says the ticket was free.
        if ($claimed === 0) {
            throw DesignTicketAlreadyAccepted::make($ticket->refresh()->acceptedBy?->name);
        }

        // A mass update fires no model events, so the history would lose the one moment this
        // whole step exists to record. Touching the model puts the acceptance in the trail with
        // its causer — the `->each()` rule from RULES §10, applied to a single row.
        $ticket->refresh();
        $ticket->forceFill(['accepted_at' => $now])->save();

        DesignTicketProgressed::dispatch(
            (int) $ticket->getKey(),
            DesignTicketStatus::InProgress,
            (int) $designer->getKey(),
        );

        return $ticket->refresh();
    }
}
