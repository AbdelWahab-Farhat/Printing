<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Somebody tried to work on a ticket that is not theirs.
 *
 * Distinct from {@see DesignTicketAlreadyAccepted}, which answers an *acceptance*. This answers
 * an upload, and the difference matters to whoever reads it: one says "you were too late", the
 * other says "this was never yours".
 */
final class DesignTicketBelongsToAnotherDesigner extends DomainException
{
    public static function make(): self
    {
        return new self('هذه التذكرة مُسنَدة إلى مصمم آخر');
    }
}
