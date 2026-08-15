<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;

/**
 * Sums a line's three cost components into one figure — the same relationship
 * {@see RecalculateOrderTotals} has with `line_total`/`items_total`.
 *
 * **Null until there is a material cost to build on.** `material_cost` is the fact that a line
 * has actually been produced at all — {@see DeductOrderStock} force-fills it the moment stock
 * leaves the warehouse — so `cogs` staying null until then is the honest answer for a line that
 * has not reached ready yet, not a zero pretending to be a real cost.
 *
 * Called twice in the ordinary flow at ready — once by `DeductOrderStock` right after
 * `material_cost` is known, and again by `ApplyManufacturingRates` once `labor_cost`/
 * `overhead_cost` land moments later in the same transaction — which is fine: this is a pure
 * function of the three columns, not an accumulator.
 */
final class RecalculateOrderItemCost
{
    public function __invoke(OrderItem $item): OrderItem
    {
        if ($item->material_cost === null) {
            $item->forceFill(['cogs' => null])->save();

            return $item;
        }

        $item->forceFill([
            'cogs' => Money::sum(
                (string) $item->material_cost,
                (string) ($item->labor_cost ?? '0'),
                (string) ($item->overhead_cost ?? '0'),
            ),
        ])->save();

        return $item;
    }
}
