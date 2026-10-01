<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Models\TreasuryMovement;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;

/**
 * An account's history, newest first, each row carrying the balance it left behind.
 *
 * **The running balance is computed over the whole history, then filtered.** Filtering first
 * would restart the sum at the filter's edge, and «الرصيد بعد الحركة» would be a figure that
 * never existed.
 */
final class AccountLedger
{
    /**
     * @param  array{from?: ?string, to?: ?string, kind?: ?string, order_id?: ?int}  $filters
     * @return LengthAwarePaginator<int, TreasuryMovement>
     */
    public function page(int $accountId, array $filters, int $perPage): LengthAwarePaginator
    {
        $withBalance = TreasuryMovement::query()
            ->where('account_id', $accountId)
            ->select('treasury_movements.*')
            ->selectRaw(
                "SUM(CASE WHEN direction = 'in' THEN amount ELSE -amount END) "
                .'OVER (ORDER BY occurred_at, id) AS balance_after'
            );

        return TreasuryMovement::query()
            ->fromSub($withBalance, 'treasury_movements')
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->where('occurred_at', '>=', Carbon::parse($from)->startOfDay()))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->where('occurred_at', '<=', Carbon::parse($to)->endOfDay()))
            ->when($filters['kind'] ?? null, fn ($q, $kind) => $q->where('kind', $kind))
            ->when($filters['order_id'] ?? null, fn ($q, $orderId) => $q->where('order_id', $orderId))
            ->with([
                'recorder',
                'counterpartAccount',
                'operation.category',
                'operation.employee',
                // لـ`is_reversible`: أعُكست عمليةُ السطر؟ — دفعةً واحدة للصفحة لا سؤالاً لكل سطر.
                'operation.reversedBy',
                // ولـ`is_reversed`: أعُكس السطرُ نفسه؟ — السؤالُ نفسه بالطريقة نفسها.
                'reversedBy',
            ])
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
