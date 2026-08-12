<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\Money;

/**
 * Derives `total_amount` from an order's own lines.
 *
 * The one place that decides what a purchase order is planned to cost, so a client can never post
 * a total and no two code paths can disagree about how one is reached — the same role
 * {@see RecalculateOrderTotals} plays for orders. Called after anything
 * that could move a line's cost: creating the order, replacing its lines.
 *
 * A line with no `unit_cost` contributes nothing rather than failing the sum — cost is optional
 * history on rows written before this feature existed, not a reason a new save should be refused.
 */
final class RecalculatePurchaseOrderTotal
{
    public function __invoke(PurchaseOrder $order): PurchaseOrder
    {
        $lineTotals = $order->items()->get()
            ->map(fn (PurchaseOrderItem $item) => $item->total_cost === null ? null : (string) $item->total_cost)
            ->filter(fn (?string $total) => $total !== null)
            ->all();

        $order->forceFill([
            'total_amount' => $lineTotals === [] ? null : Money::sum(...$lineTotals),
        ])->save();

        return $order;
    }
}
