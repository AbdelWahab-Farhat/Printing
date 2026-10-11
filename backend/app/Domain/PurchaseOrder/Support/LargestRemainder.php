<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Support;

use App\Domain\PurchaseOrder\Actions\AllocatePurchaseOrderAdditionalCosts;
use App\Domain\PurchaseOrder\Actions\ReceivePurchaseOrder;

/**
 * Splits a sum of money across weighted parts so the parts add up to it **exactly** — the
 * largest-remainder method (Hamilton's), in integer cents, through bcmath and never a float.
 *
 * Each part's raw share is floored, then the cents the floors left over are handed out one at a
 * time to the parts with the largest remainder, ties broken by key ascending — deterministic, and
 * never a cent short or over, which a per-part round would be on almost any split of three.
 *
 * Every weight zero and still something to split: shared equally rather than by an undefined
 * proportion.
 *
 * One algorithm for both splits a purchase order makes — its planned costs over what was ordered
 * ({@see AllocatePurchaseOrderAdditionalCosts}) and its arrival
 * costs over what arrived ({@see ReceivePurchaseOrder}).
 */
final class LargestRemainder
{
    /**
     * @param  string  $totalCents  What to split, in whole cents.
     * @param  array<int, string>  $weightCents  Each part's weight, in whole cents, keyed by id.
     * @return array<int, string> Cents per key, summing to `$totalCents`.
     */
    public static function split(string $totalCents, array $weightCents): array
    {
        if ($weightCents === []) {
            return [];
        }

        if (bccomp($totalCents, '0', 0) === 0) {
            return array_map(fn () => '0', $weightCents);
        }

        $sumWeights = '0';

        foreach ($weightCents as $weight) {
            $sumWeights = bcadd($sumWeights, $weight, 0);
        }

        $usesEqualSplit = bccomp($sumWeights, '0', 0) === 0;
        $denominator = $usesEqualSplit ? (string) count($weightCents) : $sumWeights;

        $floors = [];
        $remainders = [];
        $sumFloors = '0';

        foreach ($weightCents as $key => $weight) {
            $numerator = bcmul($totalCents, $usesEqualSplit ? '1' : $weight, 0);

            $floors[$key] = bcdiv($numerator, $denominator, 0);
            $remainders[$key] = bcmod($numerator, $denominator);
            $sumFloors = bcadd($sumFloors, $floors[$key], 0);
        }

        $leftover = (int) bcsub($totalCents, $sumFloors, 0);

        $keys = array_keys($weightCents);
        usort($keys, fn (int $a, int $b) => bccomp($remainders[$b], $remainders[$a], 0) ?: $a <=> $b);

        foreach (array_slice($keys, 0, $leftover) as $key) {
            $floors[$key] = bcadd($floors[$key], '1', 0);
        }

        return $floors;
    }

    public static function toCents(string $value): string
    {
        return bcmul($value, '100', 0);
    }

    public static function fromCents(string $cents): string
    {
        return bcdiv($cents, '100', 2);
    }
}
