<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A period will not close while somebody still has to look at returned goods.
 *
 * When a printed order is cancelled, its material is credited back to the shelf **as good stock** —
 * and paper that has been through a press is not good stock. Nothing in the system can tell the
 * difference, because the movement ledger records quantities and not whether there is ink on them.
 *
 * Close over that question and the pool's period shows profit it did not earn on goods it does not
 * have, divides it, and pays it into wallets the money can be drawn from that afternoon. The
 * friction is the point.
 */
final class PeriodHasUnansweredReturns extends DomainException
{
    public static function make(string $pool): self
    {
        return new self(
            "الصندوق «{$pool}» فيه بضاعة راجعة من طلبيات ملغاة لم تُفحص بعد — أجب عنها قبل الإقفال"
        );
    }
}
