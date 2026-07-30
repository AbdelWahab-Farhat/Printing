<?php

declare(strict_types=1);

namespace App\Domain\Customer\Queries;

use App\Domain\Customer\Models\Customer;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The customer index: search, activity filter, newest first.
 *
 * Lives in its own class rather than in the controller so the same list can be reused by an
 * admin panel or an export without duplicating the query.
 */
final class CustomerListQuery
{
    /**
     * @return LengthAwarePaginator<int, Customer>
     */
    public function __invoke(CustomerFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return Customer::query()
            // Eager-loaded: the resource renders shops for every row, which would otherwise
            // be one query per customer.
            ->with('shops')
            ->when($filters->search !== null, function ($query) use ($filters) {
                $term = '%'.$filters->search.'%';

                // Grouped so the OR set cannot escape and swallow the is_active filter.
                $query->where(function ($query) use ($term) {
                    $query->where('name', 'ilike', $term)
                        ->orWhere('code', 'ilike', $term)
                        ->orWhere('primary_phone', 'like', $term);
                });
            })
            ->when($filters->isActive !== null, fn ($query) => $query->where('is_active', $filters->isActive))
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
