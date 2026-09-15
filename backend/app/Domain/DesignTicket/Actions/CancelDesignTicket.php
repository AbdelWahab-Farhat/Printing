<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Exceptions\DesignTicketCancellationRequiresReason;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;

/**
 * Calls a request off.
 *
 * **Not in the brief, and added deliberately.** Tickets are opened by mistake, customers change
 * their minds, and orders get cancelled — without this the wrong ticket sits in a designer's
 * queue for ever, and the only way out is a delete, which erases the record of the request ever
 * having been made. See DESIGN-TICKETS-DESIGN.md §12 Q1.
 *
 * **It is not a way to reject a design.** That is «تعديل مطلوب», which keeps the ticket alive and
 * the conversation going. This says the request itself should not have been made or is no longer
 * wanted, which is why it is available from every open status including «بانتظار المراجعة» — an
 * order cancelled while artwork is in review takes the request with it.
 *
 * **The reason is required**, and it is the only thing separating «الزبون غيّر رأيه» from «فُتحت
 * بالخطأ» for a designer whose job disappeared overnight. Guarded here for the readable message
 * and in `design_tickets_cancellation_shape` for the guarantee.
 *
 * Versions already uploaded are left exactly where they are. The work was done, and hiding it
 * would make the cancellation look like it had never had any.
 */
final class CancelDesignTicket
{
    /**
     * @throws DesignTicketIsClosed
     * @throws DesignTicketCancellationRequiresReason
     */
    public function __invoke(DesignTicket $ticket, ?string $reason, ?User $actor = null): DesignTicket
    {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        $reason = $reason === null ? '' : trim($reason);

        if ($reason === '') {
            throw DesignTicketCancellationRequiresReason::make();
        }

        $ticket->forceFill([
            'status' => DesignTicketStatus::Cancelled,
            'cancellation_reason' => $reason,
        ])->save();

        DesignTicketProgressed::dispatch(
            (int) $ticket->getKey(),
            DesignTicketStatus::Cancelled,
            $actor === null ? null : (int) $actor->getKey(),
        );

        return $ticket->refresh();
    }
}
