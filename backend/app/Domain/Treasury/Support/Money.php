<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

/**
 * Rounding money, once — Treasury's own copy.
 *
 * A sixth copy beside Order, Inventory, PurchaseOrder, Shortage and Investor, for the reason every
 * one of them gives: RULES §3 forbids importing another context's helper, and unifying them is a
 * backlog item that does not ride in on a feature branch. bcmath truncates, so half a minor unit
 * is added before cutting — round half away from zero.
 */
final class Money
{
    public const SCALE = 2;

    public static function round(string $value): string
    {
        $half = bccomp($value, '0', 8) < 0 ? '-0.005' : '0.005';

        return bcadd(bcadd($value, $half, 8), '0', self::SCALE);
    }

    /** A request's number — `"5"`, `5.5` — as a two-place decimal string. */
    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
    }

    public static function sum(string ...$values): string
    {
        $total = '0';

        foreach ($values as $value) {
            $total = bcadd($total, $value, 8);
        }

        return self::round($total);
    }

    public static function isPositive(string $value): bool
    {
        return bccomp($value, '0', self::SCALE) > 0;
    }
}
