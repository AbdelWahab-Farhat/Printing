<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Models\Order;

/**
 * Everything another context needs to split one order's profit, as plain arrays.
 *
 * The seam that lets Investment attribute a sale without ever loading an `Order` — RULES §3: a
 * context reaches another through its Service, and what comes back is data rather than models.
 *
 * **The line's fulfilment movement is the join key, never `stock_movements.reference_id`.** That
 * column has no foreign key, carries `stock_arrivals.id` for an arrival, and is freely settable
 * through `POST /stock-movements/fulfillments` — so a query keyed on it would sweep in rows that
 * belong to no order line at all. `order_items.fulfillment_stock_movement_id` is written by
 * exactly two actions and is rewritten when a line is restated, which is precisely the pointer a
 * profit split must follow.
 */
final class ProfitAttributionQuery
{
    /**
     * @return array{
     *     order_id: int,
     *     code: string,
     *     status: string,
     *     grand_total: string,
     *     items_total: string,
     *     total_cogs: ?string,
     *     gross_profit: ?string,
     *     lines: list<array{
     *         line_id: int,
     *         movement_id: int,
     *         line_total: string,
     *         conversion_cost: string
     *     }>
     * }|null
     */
    public function __invoke(int $orderId): ?array
    {
        $order = Order::query()->with('items')->find($orderId);

        if ($order === null) {
            return null;
        }

        $lines = [];

        foreach ($order->items as $item) {
            if ($item->fulfillment_stock_movement_id === null) {
                continue;
            }

            $lines[] = [
                'line_id' => (int) $item->getKey(),
                'movement_id' => (int) $item->fulfillment_stock_movement_id,
                'line_total' => (string) ($item->line_total ?? '0.00'),
                // What the company added to the goods on this line. Kept separate from material
                // so a deal is never charged for it twice and never credited with it.
                'conversion_cost' => bcadd(
                    bcadd((string) ($item->labor_cost ?? '0.00'), (string) ($item->overhead_cost ?? '0.00'), 2),
                    (string) ($item->outsourcing_cost ?? '0.00'),
                    2,
                ),
            ];
        }

        return [
            'order_id' => (int) $order->getKey(),
            'code' => (string) $order->id,
            'status' => $order->status->value,
            'grand_total' => (string) $order->grand_total,
            'items_total' => (string) $order->items_total,
            'total_cogs' => $order->total_cogs === null ? null : (string) $order->total_cogs,
            'gross_profit' => $order->grossProfit(),
            'lines' => $lines,
        ];
    }
}
