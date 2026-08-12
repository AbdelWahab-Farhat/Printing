<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Support;

/**
 * Rounding money, once.
 *
 * A same-domain copy of {@see \App\Domain\Order\Support\Money} rather than a shared import: this
 * module already depends on Vendor only (see `PurchaseOrderService`), and reaching into `Order`
 * for a two-method helper would open a dependency RULES.md §3 does not otherwise ask for. The
 * codebase already tolerates this kind of small duplication elsewhere — every DTO here carries its
 * own `textOrNull()`/`intOrNull()` rather than sharing one.
 *
 * bcmath **truncates** rather than rounds, so `bcadd('1.005', '0', 2)` is `1.00` — a vendor cost
 * quietly short by a fraction on every line, which becomes a real number over a year of orders.
 * Adding half a minor unit before cutting gives round-half-away-from-zero.
 */
final class Money
{
    public const SCALE = 2;

    /** Rounds a decimal string to two places, half away from zero. */
    public static function round(string $value): string
    {
        $half = bccomp($value, '0', 8) < 0 ? '-0.005' : '0.005';

        return bcadd(bcadd($value, $half, 8), '0', self::SCALE);
    }

    /** Adds a list of decimal strings at full precision, then rounds once at the end. */
    public static function sum(string ...$values): string
    {
        $total = '0';

        foreach ($values as $value) {
            $total = bcadd($total, $value, 8);
        }

        return self::round($total);
    }
}
