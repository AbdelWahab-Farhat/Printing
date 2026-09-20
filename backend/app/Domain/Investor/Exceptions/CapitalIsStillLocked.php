<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An exit asked for before the minimum term has run.
 *
 * **It names the date**, because «لا يمكنك السحب» with no date is a refusal somebody has to come
 * back and ask about. The figure is computed by the same function the screen shows him before he
 * presses anything, so the two cannot disagree.
 */
final class CapitalIsStillLocked extends DomainException
{
    public static function make(string $pool, string $freeOn, int $termMonths): self
    {
        return new self(
            "رأس المال في «{$pool}» لا يُسحب قبل {$termMonths} شهراً من دخوله — يمكن طلب السحب ابتداءً من {$freeOn}"
        );
    }
}
