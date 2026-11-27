<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\OrderType;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * «بانتظار التسليم» — stock an instant order has already taken off the books but that is still on
 * the shelf, because the customer has not collected it yet (INSTANT-ORDERS-PLAN.md §4).
 *
 * **Calculated, never stored.** It is read off the draws of the instant orders still «جديدة»: the
 * movement each line points at says which shelf and how much. Nothing can drift or get stuck —
 * the moment the order is handed over, cancelled or edited, the number follows.
 *
 * The shelf count is then «المتاح» + «بانتظار التسليم».
 */
final class AwaitingHandoverQuery
{
    /**
     * How much of each stock item one warehouse holds for instant orders not yet handed over.
     *
     * @param  list<int>  $stockItemIds
     * @return array<int, string>
     */
    public function totals(int $warehouseId, array $stockItemIds): array
    {
        if ($stockItemIds === []) {
            return [];
        }

        return $this->lines($warehouseId)
            ->whereIn('sm.stock_item_id', $stockItemIds)
            ->groupBy('sm.stock_item_id')
            ->selectRaw('sm.stock_item_id, SUM(sm.quantity) AS awaiting')
            ->pluck('awaiting', 'stock_item_id')
            ->mapWithKeys(fn ($quantity, $id): array => [(int) $id => number_format((float) $quantity, 3, '.', '')])
            ->all();
    }

    /**
     * The orders behind one shelf's number: what each is holding, for whom, since when.
     *
     * @return Collection<int, object{order_id: int, code: string, customer_name: string|null, quantity: string, placed_at: string|null}>
     */
    public function orders(int $warehouseId, int $stockItemId): Collection
    {
        return $this->lines($warehouseId)
            ->where('sm.stock_item_id', $stockItemId)
            ->leftJoin('customers as c', 'c.id', '=', 'o.customer_id')
            ->groupBy('o.id', 'o.code', 'c.name', 'o.placed_at')
            ->orderBy('o.placed_at')
            ->selectRaw('o.id AS order_id, o.code, c.name AS customer_name, SUM(sm.quantity) AS quantity, o.placed_at')
            ->get();
    }

    private function lines(int $warehouseId): Builder
    {
        return DB::table('order_items as oi')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->join('stock_movements as sm', 'sm.id', '=', 'oi.fulfillment_stock_movement_id')
            ->where('o.order_type', OrderType::Instant->value)
            ->where('o.status', OrderStatus::New->value)
            ->whereNull('o.deleted_at')
            ->whereNull('oi.deleted_at')
            ->where('sm.from_warehouse_id', $warehouseId);
    }
}
