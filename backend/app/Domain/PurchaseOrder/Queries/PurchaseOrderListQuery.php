<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Queries;

use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * The purchase-order list: filterable by vendor, warehouse and status, newest first.
 */
final class PurchaseOrderListQuery
{
    /**
     * @return LengthAwarePaginator<int, PurchaseOrder>
     */
    public function __invoke(PurchaseOrderFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return PurchaseOrder::query()
            ->with(['vendor', 'warehouse', 'items.productVariant.product'])
            ->when($filters->vendorId !== null, fn (Builder $q) => $q->where('vendor_id', $filters->vendorId))
            ->when($filters->warehouseId !== null, fn (Builder $q) => $q->where('warehouse_id', $filters->warehouseId))
            ->when($filters->status !== null, fn (Builder $q) => $q->where('status', $filters->status))
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
