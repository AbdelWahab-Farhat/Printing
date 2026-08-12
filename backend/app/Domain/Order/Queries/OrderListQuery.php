<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Models\Order;
use App\Domain\Order\Queries\Concerns\FiltersOrders;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The orders list.
 *
 * Newest first: an order screen is a work queue, and the thing taken five minutes ago is the
 * one somebody is asking about.
 */
final class OrderListQuery
{
    use FiltersOrders;

    /**
     * @return LengthAwarePaginator<int, Order>
     */
    public function __invoke(OrderFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        $query = Order::query()
            // Eager-loaded: the list renders the customer's name and counts the lines, and
            // strict mode turns a forgotten load into an exception rather than a query per row.
            //
            // The whole row, not a column list: CustomerResource renders `is_active`, and under
            // strict mode an attribute that was never selected throws instead of reading null.
            // A narrower select here is a 500 the next time that resource gains a field.
            ->with('customer')
            // The lines, for the same reason the customer is: every row is asked what its moves
            // would want, and two of those answers are made of lines — «نواقص» asks per size
            // («الناقص من 30*30»), and whether «جاهزة» must have a weight depends on whether
            // any line is sold by the kilo. Left to fetch themselves that is a query per order,
            // which is what a work queue can least afford.
            ->with('items')
            ->withCount('items');

        return $this->applyFilters($query, $filters)
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
