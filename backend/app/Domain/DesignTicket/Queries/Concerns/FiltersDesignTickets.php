<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Queries\Concerns;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Queries\DesignTicketFilters;
use Illuminate\Database\Eloquent\Builder;

/**
 * The one place a design tickets list is narrowed.
 *
 * Shared by the list and the status counts so the chip row and the page beneath it can never
 * describe different sets of rows — the failure ORDER-DELETE-AND-ARCHIVE §٦ documents, where
 * three queries seeded their own builders and one of them drifted.
 */
trait FiltersDesignTickets
{
    /**
     * @param  Builder<DesignTicket>  $query
     * @return Builder<DesignTicket>
     */
    protected function applyFilters(Builder $query, DesignTicketFilters $filters): Builder
    {
        /*
         * **The visibility narrowing, and it is first because it is not a filter.**
         *
         * A reader without `design_tickets.view_all` is shown the tickets they raised, the ones
         * addressed to them, the ones they took — and the unclaimed pool, which is the only way a
         * designer finds work that has nobody's name on it yet.
         *
         * **In SQL rather than after the fetch**, and that is the whole reason this is not simply
         * `DesignTicket::isVisibleTo()` called in a loop: a page that fetched fifteen rows and then
         * dropped four would paginate to short pages, and the reader would conclude the list had
         * ended. The model method exists for the *single* binding, where the question is a 404
         * rather than a page; the two agree and are deliberately written twice, because one of
         * them has to be a query.
         */
        if ($filters->visibleToUserId !== null) {
            $reader = $filters->visibleToUserId;

            $query->where(function (Builder $mine) use ($reader): void {
                $mine->where('requested_by_user_id', $reader)
                    ->orWhere('assigned_designer_id', $reader)
                    ->orWhere('accepted_by_user_id', $reader)
                    ->orWhere(function (Builder $pool): void {
                        $pool->whereNull('assigned_designer_id')->whereNull('accepted_at');
                    });
            });
        }

        if ($filters->statuses !== null) {
            $query->whereIn('status', array_map(
                fn ($status) => $status->value,
                $filters->statuses,
            ));
        }

        // Two different questions, and only one of them is «مُسنَد إلى فلان». The pool is a queue
        // somebody actually works — it is what the board means by work nobody has picked up.
        if ($filters->unassignedOnly) {
            $query->whereNull('assigned_designer_id')->whereNull('accepted_at');
        } elseif ($filters->designerId !== null) {
            // Either addressed to them or taken by them: after a reassignment those are two
            // different people, and a designer looking for «شغلي» means the work they are doing.
            $designer = $filters->designerId;

            $query->where(function (Builder $theirs) use ($designer): void {
                $theirs->where('assigned_designer_id', $designer)
                    ->orWhere('accepted_by_user_id', $designer);
            });
        }

        if ($filters->requestedByUserId !== null) {
            $query->where('requested_by_user_id', $filters->requestedByUserId);
        }

        if ($filters->customerId !== null) {
            $query->where('customer_id', $filters->customerId);
        }

        if ($filters->orderId !== null) {
            $query->where('order_id', $filters->orderId);
        }

        if ($filters->search !== null) {
            $term = $filters->search;

            $query->where(function (Builder $matches) use ($term): void {
                // `ILIKE` rather than `LIKE`: Postgres is case-sensitive, and somebody typing
                // «كيس» has no way to know how the row was capitalised.
                $matches->where('design_tickets.title', 'ILIKE', '%'.$term.'%')
                    ->orWhere('design_tickets.code', 'ILIKE', $term.'%')
                    // The snapshot, not a join to `customers`: a designer searching by customer
                    // name must not need a grant on that table to do it.
                    ->orWhere('design_tickets.customer_name', 'ILIKE', '%'.$term.'%');
            });
        }

        return $query;
    }
}
