<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Models\DesignTicket;

/**
 * Corrects what was asked for, while it is still being asked.
 *
 * **Three fields and no more.** The brief, the title and the instructions are the request itself;
 * everything else on the row is a record of something that happened, and a record that can be
 * edited is not one.
 *
 * **The customer cannot be changed.** Not an oversight: attachments, versions and a conversation
 * hang off a ticket by the time anybody notices the wrong customer was picked, and moving them
 * would mean deciding whether the first customer's name stays on the files already uploaded. A
 * ticket opened against the wrong customer is cancelled and opened again, which costs one tap and
 * leaves an honest record of what happened.
 *
 * **A closed ticket refuses this**, because «مكتمل» means somebody approved artwork against the
 * words that were there at the time, and rewriting them afterwards would make the approval a
 * signature on a document that has since changed.
 */
final class UpdateDesignTicket
{
    /**
     * @param  array<string, mixed>  $attributes  already-validated request data
     *
     * @throws DesignTicketIsClosed
     */
    public function __invoke(DesignTicket $ticket, array $attributes): DesignTicket
    {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        $ticket->update(array_intersect_key(
            $attributes,
            array_flip(['title', 'description', 'instructions']),
        ));

        return $ticket->refresh();
    }
}
