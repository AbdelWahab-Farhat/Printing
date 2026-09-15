<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\DTOs;

/**
 * A reserved primary key together with the ticket code derived from it.
 *
 * The two travel as one value because the whole point is that they agree: a ticket whose id is 7
 * always shows D7. The `ShortageIdentifier` shape.
 */
final readonly class DesignTicketIdentifier
{
    public function __construct(
        public int $id,
        public string $code,
    ) {}
}
