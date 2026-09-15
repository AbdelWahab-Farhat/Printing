<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Actions\AcceptDesignTicket;
use App\Support\Exceptions\DomainException;

/**
 * Two designers reached for the same ticket, and this is the second one.
 *
 * **Names who holds it**, which is the point of refusing rather than merely failing: the designer
 * who lost the race needs to know whom to talk to, not only that they may not have it. That is
 * «لا تضيع هوية المصمم الذي استلم الطلب» read from the other side.
 *
 * The race itself is settled by a conditional update in {@see AcceptDesignTicket}, never by the
 * check that raises this — a check in PHP is passed by both requests before either commits.
 */
final class DesignTicketAlreadyAccepted extends DomainException
{
    public static function make(?string $designerName = null): self
    {
        return new self($designerName === null
            ? 'تم قبول هذه التذكرة من مصمم آخر'
            : "تم قبول هذه التذكرة من {$designerName}");
    }
}
