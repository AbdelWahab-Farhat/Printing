<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Enums\WalletEntryCategory;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * One investor's movements, newest first — the staff screen and the investor's own portal read
 * the same list.
 *
 * **A category filter keeps the reversals of what it matches.** A reversal's own type is
 * `reversal`, so filtering on `type` alone would show a deposit and hide the row that took it
 * back, and the list would add up to more than the wallet holds.
 */
final class InvestorStatementQuery
{
    /**
     * @param  array{category?: ?string, investor_deal_id?: ?int, from?: ?string, to?: ?string}  $filters
     * @return LengthAwarePaginator<int, InvestorWalletEntry>
     */
    public function __invoke(int $investorId, array $filters, int $perPage = 25): LengthAwarePaginator
    {
        $category = isset($filters['category']) ? WalletEntryCategory::tryFrom((string) $filters['category']) : null;
        $dealId = $filters['investor_deal_id'] ?? null;
        $from = $filters['from'] ?? null;
        $to = $filters['to'] ?? null;

        return InvestorWalletEntry::query()
            ->with(['deal', 'period', 'recordedBy', 'reversedEntry.deal', 'reversedBy', 'fundUnits'])
            ->where('investor_id', $investorId)
            ->when($dealId !== null, fn (Builder $q) => $q->where('investor_deal_id', (int) $dealId))
            ->when($category !== null, fn (Builder $q) => $this->inCategory($q, $category))
            ->when($from !== null, fn (Builder $q) => $q->where('occurred_at', '>=', Carbon::parse($from)->startOfDay()))
            // Inclusive: `to` counts the whole of its day.
            ->when($to !== null, fn (Builder $q) => $q->where('occurred_at', '<=', Carbon::parse($to)->endOfDay()))
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * @param  Builder<InvestorWalletEntry>  $query
     */
    private function inCategory(Builder $query, WalletEntryCategory $category): void
    {
        $types = array_map(fn (WalletEntryType $type) => $type->value, $category->types());

        $query->where(fn (Builder $w) => $w
            ->whereIn('type', $types)
            ->orWhere(fn (Builder $r) => $r
                ->where('type', WalletEntryType::Reversal->value)
                ->whereHas('reversedEntry', fn (Builder $o) => $o->whereIn('type', $types))));
    }
}
