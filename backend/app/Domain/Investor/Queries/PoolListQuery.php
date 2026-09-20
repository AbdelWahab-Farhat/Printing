<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The pools screen: the صناديق, by name.
 *
 * **Ordered by name rather than by date.** A deal list is a history and reads newest first; a pool
 * list is a standing set of four or five materials that the business will look at every week, and
 * it should be in the same order every time so the eye learns where «ورق» sits.
 *
 * Deliberately no status filter: every pool is open, always. What has a status here is the
 * period.
 */
final class PoolListQuery
{
    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, InvestorDeal>
     */
    public function __invoke(array $filters, int $perPage = 15): LengthAwarePaginator
    {
        $search = isset($filters['search']) ? trim((string) $filters['search']) : '';

        return InvestorDeal::query()
            ->where('kind', PoolKind::Pool->value)
            ->with(['poolItems.stockItem', 'shares.investor'])
            ->when($search !== '', fn ($q) => $q->where(fn ($w) => $w
                ->where('name', 'ilike', '%'.$search.'%')
                ->orWhere('code', 'ilike', '%'.$search.'%')))
            ->when(
                isset($filters['investor_id']) && $filters['investor_id'] !== '',
                fn ($q) => $q->whereHas('shares', fn ($s) => $s->where('investor_id', (int) $filters['investor_id'])),
            )
            ->when(
                isset($filters['stock_item_id']) && $filters['stock_item_id'] !== '',
                fn ($q) => $q->whereHas('poolItems', fn ($i) => $i->where('stock_item_id', (int) $filters['stock_item_id'])),
            )
            ->orderBy('name')
            ->orderBy('id')
            ->paginate($perPage);
    }
}
