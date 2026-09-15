<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A ticket was called off with nothing said.
 *
 * A cancellation is the one ending that is not a verdict on anybody's work, so the reason is all
 * that distinguishes «الزبون غيّر رأيه» from «فُتحت بالخطأ» — and a designer whose job disappeared
 * overnight is owed the difference.
 *
 * Guarded in the database too, by `design_tickets_cancellation_shape`: validation gives the
 * readable 422, the constraint is the guarantee.
 */
final class DesignTicketCancellationRequiresReason extends DomainException
{
    public static function make(): self
    {
        return new self('اكتب سبب إلغاء التذكرة');
    }
}
