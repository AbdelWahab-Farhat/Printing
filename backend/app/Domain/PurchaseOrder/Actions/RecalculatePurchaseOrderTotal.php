<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\Money;

/**
 * Derives `total_amount` and `total_additional_cost` from an order's own lines and additional
 * costs.
 *
 * The one place that decides what a purchase order is planned to cost, so a client can never post
 * a total and no two code paths can disagree about how one is reached — the same role
 * {@see RecalculateOrderTotals} plays for orders. Called after
 * {@see AllocatePurchaseOrderAdditionalCosts}, whenever anything could move a line's cost or the
 * order's additional costs: creating the order, replacing its lines or its additional costs.
 *
 * `total_amount` sums each line's `final_total_cost` — base cost plus its allocated share — so it
 * is already the order's grand total, inclusive of additional costs; `total_additional_cost`
 * exists so that split stays visible rather than folded away. Costs added on the receive screen
 * are spread over what arrived rather than inside a line's `final_total_cost`, so they are added
 * to it here.
 *
 * `vendor_amount` is the total less every cost paid to somebody else — a drawer or a manual
 * payable — and is what the vendor is owed (Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md).
 *
 * A line with no `final_total_cost` contributes nothing to `total_amount` rather than failing the
 * sum — cost is optional history on rows written before this feature existed, not a reason a new
 * save should be refused.
 */
final class RecalculatePurchaseOrderTotal
{
    public function __invoke(PurchaseOrder $order): PurchaseOrder
    {
        $lineTotals = $order->items()->get()
            ->map(fn (PurchaseOrderItem $item) => $item->final_total_cost === null ? null : (string) $item->final_total_cost)
            ->filter(fn (?string $total) => $total !== null)
            ->all();

        $costs = $order->additionalCosts()->get();

        $sum = fn (iterable $costs): string => Money::sum('0', ...collect($costs)
            ->map(fn (PurchaseOrderAdditionalCost $cost) => (string) $cost->amount)
            ->all());

        // A line's final_total_cost already holds its share of the planned costs; the arrival
        // costs are spread over what arrived and sit outside it, so they are added on top.
        $total = $lineTotals === []
            ? null
            : Money::sum($sum($costs->whereNotNull('stock_arrival_id')), ...$lineTotals);

        $order->forceFill([
            'total_amount' => $total,
            'total_additional_cost' => $sum($costs),
            'vendor_amount' => $total === null
                ? null
                : Money::round(bcsub($total, $sum($costs->filter->isPaidElsewhere()), 8)),
        ])->save();

        return $order;
    }
}
