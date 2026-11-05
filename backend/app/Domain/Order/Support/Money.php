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

    /**
     * What a line is billed: its exact amount with the fraction dropped — owner, 2026-11-05.
     *
     * **Down, never up**, so nobody pays more than the listed price × the quantity. **And never
     * down to nothing:** 0.80 for a single bag bills 1.00, because a line at 0.00 reads as goods
     * given away. Only an amount that really is zero stays zero.
     */
    public static function wholeDinars(string $value): string
    {
        $whole = bcadd($value, '0', 0);

        if (bccomp($whole, '0', 0) === 0 && bccomp($value, '0', 8) > 0) {
            return bcadd('1', '0', self::SCALE);
        }

        return bcadd($whole, '0', self::SCALE);
    }

    /** Whether a decimal string has no fraction: `25.00` does, `25.50` does not. */
    public static function isWhole(string $value): bool
    {
        return bccomp($value, bcadd($value, '0', 0), 8) === 0;
    }

    /**
     * A money amount as it arrived from a request, turned into a decimal string at two places.
     *
     * **Cast through a float and straight back out of it.** That looks like the mistake this
     * whole file exists to prevent, and it is the one moment it is right: what arrives from JSON
     * is already a float or a string of unknown shape — `"5"`, `5.5`, `"1e3"` — and bcmath
     * refuses the last of those outright. One cast at the boundary normalises every form; from
     * here on the number is a string and stays one, which is the rule that matters.
     */
    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
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
