<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Support;

/**
 * Rounding money, once — this context's own copy, for the reason Treasury's gives: RULES §3
 * forbids importing another context's helper. bcmath throughout; never a float.
 */
final class Money
{
    public const SCALE = 2;

    public static function round(string $value): string
    {
        $half = bccomp($value, '0', 8) < 0 ? '-0.005' : '0.005';

        return bcadd(bcadd($value, $half, 8), '0', self::SCALE);
    }

    /** Up to the next dirham-hundredth — a total charged never falls short of the fee. */
    public static function ceil(string $value): string
    {
        $truncated = bcadd($value, '0', self::SCALE);

        return bccomp($value, $truncated, 8) > 0 ? bcadd($truncated, '0.01', self::SCALE) : $truncated;
    }

    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
    }

    public static function isPositive(string $value): bool
    {
        return bccomp($value, '0', self::SCALE) > 0;
    }
}
