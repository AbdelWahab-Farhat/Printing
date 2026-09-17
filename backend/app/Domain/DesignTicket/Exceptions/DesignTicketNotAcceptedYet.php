<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A version was uploaded to a ticket nobody has taken.
 *
 * The acceptance step exists precisely so that work is never in flight with no name against it.
 * Letting an upload imply acceptance would make the step decorative, and the first symptom would
 * be two designers drawing the same bag — the duplication the brief asks to prevent.
 */
final class DesignTicketNotAcceptedYet extends DomainException
{
    public static function make(): self
    {
        return new self('يجب قبول التذكرة قبل رفع تصميم');
    }
}
