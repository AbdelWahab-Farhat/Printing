<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Models\ManufacturingCostRate;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

final class ManufacturingCostRateListQuery
{
    /**
     * @return LengthAwarePaginator<int, ManufacturingCostRate>
     */
    public function __invoke(ManufacturingCostRateFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ManufacturingCostRate::query()
            ->with('product')
            ->when($filters->productId !== null, fn ($query) => $query->where('product_id', $filters->productId))
            ->when($filters->costType !== null, fn ($query) => $query->where('cost_type', $filters->costType))
            ->when($filters->isActive !== null, fn ($query) => $query->where('is_active', $filters->isActive))
            // The default rate for each type first — it is what applies to everything without
            // its own row, so it is the one a reader most needs to find quickly.
            ->orderByRaw('product_id IS NOT NULL')
            ->orderBy('cost_type')
            ->paginate($perPage);
    }
}
