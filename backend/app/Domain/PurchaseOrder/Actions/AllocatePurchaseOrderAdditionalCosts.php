<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\LargestRemainder;
use App\Domain\PurchaseOrder\Support\Money;

/**
 * Spreads an order's additional costs (delivery, unloading, customs, ...) across its own lines,
 * proportional to each line's share of the order's base cost, and derives every cost-shaped
 * figure a line carries from the result.
 *
 * The one place that decides a line's `base_unit_cost`, `allocated_additional_cost`,
 * `final_unit_cost` and `final_total_cost` — never trusted from the request, the same treatment
 * `total_cost`/`unit` already got before this feature existed. Called after a purchase order's
 * lines and additional costs are both persisted, and before {@see RecalculatePurchaseOrderTotal}
 * sums the result into the order's own totals.
 *
 * Allocation is done in integer cents by {@see LargestRemainder} — never a float, per RULES.md
 * §8 — so the allocated shares always sum to exactly the additional-costs total; a naive
 * per-line round would leave them a cent more or less on almost any order with more than one
 * line.
 *
 * A line with zero `base_total_cost` has no meaningful share of the base cost to divide by — if
 * every line on the order is free and there is still something to distribute, it is split
 * equally across lines instead of being left unplaced.
 */
final class AllocatePurchaseOrderAdditionalCosts
{
    public function __invoke(PurchaseOrder $order): void
    {
        $items = $order->items()->get();

        if ($items->isEmpty()) {
            return;
        }

        $allocatedCents = LargestRemainder::split(
            $this->totalAdditionalCostCents($order),
            $items->mapWithKeys(fn (PurchaseOrderItem $item) => [
                $item->getKey() => LargestRemainder::toCents((string) $item->base_total_cost),
            ])->all(),
        );

        foreach ($items as $item) {
            $allocated = LargestRemainder::fromCents($allocatedCents[$item->getKey()]);
            $baseUnitCost = Money::roundTo(
                bcdiv((string) $item->base_total_cost, (string) $item->quantity_ordered, 10),
                3,
            );
            $finalTotalCost = Money::sum((string) $item->base_total_cost, $allocated);
            $finalUnitCost = Money::roundTo(bcdiv($finalTotalCost, (string) $item->quantity_ordered, 10), 3);

            $item->forceFill([
                'base_unit_cost' => $baseUnitCost,
                'allocated_additional_cost' => $allocated,
                'final_unit_cost' => $finalUnitCost,
                'final_total_cost' => $finalTotalCost,
            ])->save();
        }
    }

    /**
     * The planned costs only. A cost added on the receive screen is spread over what that receipt
     * brought, not over what was ordered — {@see ReceivePurchaseOrder}.
     */
    private function totalAdditionalCostCents(PurchaseOrder $order): string
    {
        $amounts = $order->additionalCosts()
            ->whereNull('stock_arrival_id')
            ->get()
            ->map(fn ($cost) => (string) $cost->amount)
            ->all();

        return $amounts === [] ? '0' : LargestRemainder::toCents(Money::sum(...$amounts));
    }
}
