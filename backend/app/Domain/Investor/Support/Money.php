<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

/**
 * Rounding money, once — Investment's own copy.
 *
 * A fourth copy beside Order, Inventory and PurchaseOrder, and deliberately so: RULES §3 forbids
 * one context importing another's helper, and unifying the four into `App\Support` is an
 * existing item in the backlog that must not ride in on a feature branch.
 *
 * bcmath **truncates** rather than rounds, so `bcadd('1.005', '0', 2)` is 1.00 — half a piastre
 * off every split, which over a year of profit shares is a number an investor can point at.
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

    /** A money amount as it arrived from a request — see Order\Support\Money for why the cast. */
    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
    }

    /** Adds decimal strings at full precision, rounding once at the end. */
    public static function sum(string ...$values): string
    {
        $total = '0';

        foreach ($values as $value) {
            $total = bcadd($total, $value, 8);
        }

        return self::round($total);
    }

    /** Whether a decimal string is greater than zero, at money scale. */
    public static function isPositive(string $value): bool
    {
        return bccomp($value, '0', self::SCALE) > 0;
    }

    /**
     * Splits an amount across weights so the parts sum to it **exactly**.
     *
     * Largest remainder in integer minor units, ties broken by position — the same shape
     * `AllocatePurchaseOrderAdditionalCosts::allocateCents()` uses, and for the same reason: a
     * proportional split done with three rounded divisions loses or invents a piastre, and an
     * investor's share is precisely where somebody will add the column up by hand.
     *
     * A zero total weight returns all zeros rather than dividing by it — the caller decides what
     * that means, because for a deal split it means «this order drew nothing from anybody».
     *
     * @param  list<string>  $weights
     * @return list<string>
     */
    public static function allocate(string $amount, array $weights): array
    {
        if ($weights === []) {
            return [];
        }

        $negative = bccomp($amount, '0', self::SCALE) < 0;
        $magnitude = $negative ? bcmul($amount, '-1', self::SCALE) : $amount;

        $totalMinor = (int) bcmul($magnitude, '100', 0);
        $totalWeight = '0';

        foreach ($weights as $weight) {
            $totalWeight = bcadd($totalWeight, $weight, 8);
        }

        if (bccomp($totalWeight, '0', 8) <= 0) {
            return array_fill(0, count($weights), '0.00');
        }

        $floors = [];
        $remainders = [];
        $assigned = 0;

        foreach ($weights as $index => $weight) {
            $exact = bcdiv(bcmul((string) $totalMinor, $weight, 8), $totalWeight, 8);
            $floor = (int) bcadd($exact, '0', 0);

            $floors[$index] = $floor;
            $remainders[$index] = bcsub($exact, (string) $floor, 8);
            $assigned += $floor;
        }

        // Hand the leftover minor units out one at a time, largest fractional part first. The
        // index tiebreak keeps the result deterministic, which is what makes it testable.
        $order = array_keys($remainders);
        usort($order, function (int $a, int $b) use ($remainders): int {
            $comparison = bccomp($remainders[$b], $remainders[$a], 8);

            return $comparison !== 0 ? $comparison : $a <=> $b;
        });

        for ($i = 0; $i < $totalMinor - $assigned; $i++) {
            $floors[$order[$i % count($order)]]++;
        }

        $result = [];

        foreach ($floors as $index => $minor) {
            $value = bcdiv((string) $minor, '100', self::SCALE);
            $result[$index] = $negative && $minor !== 0 ? '-'.$value : $value;
        }

        ksort($result);

        return array_values($result);
    }
}
