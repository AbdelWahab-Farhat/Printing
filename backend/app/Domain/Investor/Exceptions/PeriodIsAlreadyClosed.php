<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A period is closed once.
 *
 * Closing is the most irreversible act in this feature: it divides the period's profit, writes
 * losses down against capital, and releases money into wallets it can be withdrawn from the same
 * afternoon. Running it twice would double every one of those.
 *
 * The row lock and the `status` check together are what make the second attempt fail rather than
 * race; `investment_periods_closed_is_complete` is the database's own backstop.
 */
final class PeriodIsAlreadyClosed extends DomainException
{
    public static function make(string $startsOn): self
    {
        return new self("فترة {$startsOn} مغلقة بالفعل");
    }
}
