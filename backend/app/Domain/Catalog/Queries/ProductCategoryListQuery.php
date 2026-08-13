<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Queries;

use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The category picker's listing, and the management screen's.
 *
 * One query for both: they ask the same question and differ only by `is_active`.
 */
final class ProductCategoryListQuery
{
    /**
     * @return LengthAwarePaginator<int, ProductCategory>
     */
    public function __invoke(ProductCategoryFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ProductCategory::query()
            // Counted, not loaded: the screen says how many products are in each category, and
            // loading them to count them would be a query per row.
            ->withCount('products')
            ->when(
                $filters->search !== null,
                fn ($query) => $query->where('name', 'ilike', '%'.$filters->search.'%'),
            )
            ->when($filters->isActive !== null, fn ($query) => $query->where('is_active', $filters->isActive))
            // The catalogue's own order first, then the name so equal ranks are at least stable
            // — an unordered list renders differently on every request and looks like a bug.
            ->orderBy('sort_order')
            ->orderBy('name')
            ->paginate($perPage);
    }
}
