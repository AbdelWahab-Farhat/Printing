<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/** تغيّر الأجر بعد أن قرأه المعتمد في نافذة التأكيد، فلا يُدفع غير ما وافق عليه. */
final class DesignTicketPayChanged extends DomainException
{
    public static function make(): self
    {
        return new self('تغيّر أجر التصميم. راجعه ثم اعتمد من جديد');
    }
}
