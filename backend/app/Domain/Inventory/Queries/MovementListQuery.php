<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Queries;

use App\Domain\Inventory\Models\StockMovement;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * Reading the stock ledger.
 *
 * This is where a warehouse's history is actually read — deliberately not through
 * `Warehouse::auditTrailSubjects()`, which would have to pluck every movement id it has ever
 * been part of into an `IN` clause that grows for as long as the business trades. Here the
 * filter is a `where` against an index, and pages properly.
 */
final class MovementListQuery
{
    /**
     * @return LengthAwarePaginator<int, StockMovement>
     */
    public function __invoke(MovementFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return StockMovement::query()
            // Every row renders the size, both ends and who moved it. Strict mode makes a
            // forgotten eager load throw rather than fire four queries per row.
            ->with(['stockItem', 'fromWarehouse', 'toWarehouse', 'employee'])
            ->when($filters->warehouseId !== null, function (Builder $q) use ($filters) {
                // Either end — see MovementFilters. Grouped so the OR set cannot escape and
                // swallow the date and type filters beside it.
                $q->where(function (Builder $q) use ($filters) {
                    $q->where('from_warehouse_id', $filters->warehouseId)
                        ->orWhere('to_warehouse_id', $filters->warehouseId);
                });
            })
            ->when(
                $filters->stockItemId !== null,
                fn (Builder $q) => $q->where('stock_item_id', $filters->stockItemId),
            )
            ->when(
                $filters->movementType !== null,
                fn (Builder $q) => $q->where('movement_type', $filters->movementType?->value),
            )
            ->when($filters->employeeId !== null, fn (Builder $q) => $q->where('employee_id', $filters->employeeId))
            ->when($filters->referenceId !== null, fn (Builder $q) => $q->where('reference_id', $filters->referenceId))
            ->when($filters->from !== null, fn (Builder $q) => $q->where('created_at', '>=', $filters->from))
            ->when($filters->to !== null, fn (Builder $q) => $q->where('created_at', '<=', $filters->to))
            // Newest first, and by id rather than created_at: a transfer writes its two balance
            // updates and its ledger row inside one transaction, so several movements recorded
            // together share a timestamp to the second and ordering by it alone would shuffle
            // them between pages. The id is the only total order there is.
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
