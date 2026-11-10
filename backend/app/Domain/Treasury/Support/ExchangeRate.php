<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

use App\Domain\Treasury\Exceptions\OperationRefused;

/**
 * «صرف عملة»'s three figures — dinars, dollars and the rate — from any two of them.
 * USD-ACCOUNTS §٣.
 *
 * **What was typed is kept as typed; what was worked out is rounded** — an amount to the dirham
 * or the cent, a rate to four places. Two amounts are the receipt's own figures, so neither is
 * ever bent to fit a rounded rate.
 *
 * **A third figure, when sent, must agree** with the two others — under any one of the three
 * ways of working it out, because the app may have derived it either way before sending it.
 */
final class ExchangeRate
{
    public const SCALE = 4;

    /** A request's rate — `"7.15"`, `7.1537` — as a four-place decimal string. */
    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
    }

    public static function round(string $value): string
    {
        return bcadd(bcadd($value, '0.00005', 10), '0', self::SCALE);
    }

    /**
     * @return array{lyd: string, usd: string, rate: string}
     *
     * @throws OperationRefused when fewer than two figures are given, or three that disagree
     */
    public static function figures(?string $lyd, ?string $usd, ?string $rate): array
    {
        $given = count(array_filter([$lyd, $usd, $rate], fn (?string $figure) => $figure !== null));

        if ($given < 2) {
            throw OperationRefused::exchangeNeedsTwoFigures();
        }

        if ($lyd !== null && $usd !== null) {
            $worked = self::round(bcdiv($lyd, $usd, 10));

            if ($rate !== null && ! self::agree($lyd, $usd, $rate)) {
                throw OperationRefused::exchangeFiguresDisagree(Money::round(bcmul($usd, $rate, 10)));
            }

            return ['lyd' => $lyd, 'usd' => $usd, 'rate' => $rate ?? $worked];
        }

        // Two figures were given and they were not the two amounts, so the rate is one of them.
        $rate = (string) $rate;

        $figures = $lyd !== null
            ? ['lyd' => $lyd, 'usd' => Money::round(bcdiv($lyd, $rate, 10)), 'rate' => $rate]
            : ['lyd' => Money::round(bcmul((string) $usd, $rate, 10)), 'usd' => (string) $usd, 'rate' => $rate];

        // 0.01 dinars at a rate of 7 is no cent at all — nothing would move on one side.
        if (! Money::isPositive($figures['lyd']) || ! Money::isPositive($figures['usd'])) {
            throw OperationRefused::exchangeTooSmall();
        }

        return $figures;
    }

    /** Whether three typed figures say the same thing, however the third was worked out. */
    private static function agree(string $lyd, string $usd, string $rate): bool
    {
        return bccomp(self::round(bcdiv($lyd, $usd, 10)), $rate, self::SCALE) === 0
            || bccomp(Money::round(bcmul($usd, $rate, 10)), $lyd, Money::SCALE) === 0
            || bccomp(Money::round(bcdiv($lyd, $rate, 10)), $usd, Money::SCALE) === 0;
    }
}
