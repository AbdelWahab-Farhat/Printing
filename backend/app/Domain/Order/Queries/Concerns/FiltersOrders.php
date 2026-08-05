<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries\Concerns;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Queries\OrderFilters;
use App\Domain\Order\Queries\OrderSearchKind;
use App\Domain\Order\Queries\OrderSearchTerm;
use Illuminate\Database\Eloquent\Builder;

/**
 * The filters, written once, for the two queries that need to agree about them.
 *
 * The list and the per-status counts beside it are two questions about the same set. If the
 * count said «جاهزة ٧» while the list showed four, the number would be worse than not being
 * there — so they cannot be allowed to apply a search differently, and the only way to
 * guarantee that is for there to be one implementation.
 *
 * The status filter is the one thing they *must* differ on: the list narrows to the chosen
 * status, while the counts have to see every status to be able to count them. Hence the flag
 * rather than two copies.
 */
trait FiltersOrders
{
    /**
     * @param  Builder<Order>  $query
     * @return Builder<Order>
     */
    private function applyFilters(Builder $query, OrderFilters $filters, bool $withStatus = true): Builder
    {
        return $query
            ->when(
                $filters->search !== null,
                fn (Builder $q) => $this->applySearch($q, OrderSearchTerm::from($filters->search)),
            )
            ->when(
                $withStatus && $filters->statuses !== null,
                fn (Builder $q) => $q->whereIn(
                    'status',
                    array_map(fn (OrderStatus $s) => $s->value, $filters->statuses),
                ),
            )
            ->when($filters->customerId !== null, fn (Builder $q) => $q->where('customer_id', $filters->customerId))
            ->when($filters->cityId !== null, fn (Builder $q) => $q->where('city_id', $filters->cityId))
            ->when($filters->from !== null, fn (Builder $q) => $q->whereDate('created_at', '>=', $filters->from))
            ->when($filters->to !== null, fn (Builder $q) => $q->whereDate('created_at', '<=', $filters->to));
    }

    /**
     * One box, one column — decided by the shape of what was typed.
     *
     * **Not an OR across every column, which is what this replaces.** The old query matched a
     * term anywhere in the order code, the tracking number, the customer's name, their phone and
     * their code at once, so `52` returned the order numbered 52 alongside every customer whose
     * phone happened to contain those digits. A search that answers a question nobody asked is a
     * search people stop trusting.
     *
     * Each kind is matched the way that kind is meant. A phone is a **prefix** — people type as
     * much of it as they remember, and `0912` should be narrowing the list, not failing. An
     * order number and a customer code are **exact**: «طلبية رقم ٥٢» means that one, and
     * returning 52, 520 and 521 beside it is noise the reader has to filter by eye.
     *
     * @param  Builder<Order>  $query
     */
    private function applySearch(Builder $query, OrderSearchTerm $term): void
    {
        match ($term->kind) {
            OrderSearchKind::OrderCode => $query->where('code', $term->value),

            OrderSearchKind::Phone => $query->whereHas(
                'customer',
                fn ($q) => $q->where('phone', 'like', $term->value.'%'),
            ),

            OrderSearchKind::CustomerCode => $query->whereHas(
                'customer',
                fn ($q) => $q->where('code', $term->value),
            ),

            // `ilike`, because Postgres `like` is case-sensitive and a name is not a code.
            OrderSearchKind::Name => $query->whereHas(
                'customer',
                fn ($q) => $q->where('name', 'ilike', '%'.$term->value.'%'),
            ),
        };
    }
}
