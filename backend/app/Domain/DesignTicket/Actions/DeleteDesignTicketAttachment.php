<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Models\DesignTicketFile;

/**
 * Removes one of the employee's reference files from a ticket.
 *
 * **Hides the row; the object stays**, the same commitment `customer_designs` makes and for a
 * related reason: a designer may already be working from this picture, and a tidy-up that made it
 * unopenable would break work in progress with no way to get it back.
 *
 * **Only a brief can reach this.** There is deliberately no endpoint that removes a submission: a
 * version is a statement in a conversation, and deleting one would leave a change request
 * referring to something nobody can see. The route's binding is what enforces it — see the
 * controller.
 */
final class DeleteDesignTicketAttachment
{
    public function __invoke(DesignTicketFile $file): void
    {
        $file->delete();
    }
}
