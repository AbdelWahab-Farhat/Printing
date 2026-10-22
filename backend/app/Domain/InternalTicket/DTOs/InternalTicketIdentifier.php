<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\DTOs;

/** رقمُ التذكرة المحجوز وكودها، قبل أن يُكتب الصف. */
final readonly class InternalTicketIdentifier
{
    public function __construct(
        public int $id,
        public string $code,
    ) {}
}
