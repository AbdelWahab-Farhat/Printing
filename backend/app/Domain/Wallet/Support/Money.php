<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Support;

/**
 * Rounding money, once — the Wallet's own copy, for the reason Treasury's gives: RULES §3 forbids
 * importing another context's helper. bcmath truncates, so half a minor unit is added before
 * cutting — round half away from zero.
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

    public static function isPositive(string $value): bool
    {
        return bccomp($value, '0', self::SCALE) > 0;
    }

    /** The smaller of two amounts. */
    public static function min(string $a, string $b): string
    {
        return bccomp($a, $b, self::SCALE) <= 0 ? $a : $b;
    }
}
