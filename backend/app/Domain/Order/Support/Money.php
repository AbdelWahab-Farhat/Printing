<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

/**
 * Rounding money, once.
 *
 * bcmath **truncates** rather than rounds, so `bcadd('1.005', '0', 2)` is 1.00 — a customer
 * quietly billed a fraction less on every line, which becomes a real number over a year of
 * orders. Adding half a minor unit before cutting gives round-half-away-from-zero, the
 * behaviour an invoice is expected to have.
 *
 * A helper rather than a value object: there is one operation here, and a class with a single
 * static method that everything already agrees on is less machinery than wrapping every total
 * in an object it would immediately be unwrapped from.
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
