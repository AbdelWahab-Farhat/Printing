<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use Illuminate\Support\Facades\DB;

/**
 * The orders that ate this deal's stock and have not become final yet.
 *
 * **The reason closing a deal is not simply «is the shelf empty».** Stock leaves at «جاهزة
 * للطباعة», days before a parcel reaches anybody, and the road from there runs through «راجع
 * مندوب» and «راجع مكتب» to a full cancellation — at which point `CreditBackStockBatches` puts
 * the goods back into the very layers this deal owns. A deal closed and paid out in between
 * leaves the company holding the stock and the investor holding the money.
 *
 * Only `delivered` and `settled` are safe: from those the state machine offers no road back.
 *
 * Written as a query builder rather than through OrderService because it reads nothing but ids
 * and a status string, and returning order *codes* for a refusal message is the whole of it.
 */
final class DealOrdersInFlightQuery
{
    /**
     * @return list<string> the order codes blocking the close, empty when nothing does
     */
    public function __invoke(int $dealId): array
    {
        return DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->join('order_items as oi', 'oi.fulfillment_stock_movement_id', '=', 'm.id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->where('b.investor_deal_id', $dealId)
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereNull('oi.deleted_at')
            ->whereNull('o.deleted_at')
            ->whereNotIn('o.status', ['delivered', 'settled', 'cancelled'])
            // A reversed draw is not holding anything: the goods went back to the shelf.
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'))
            ->distinct()
            ->orderBy('o.id')
            ->pluck('o.id')
            ->map(fn ($id) => (string) $id)
            ->all();
    }
}
