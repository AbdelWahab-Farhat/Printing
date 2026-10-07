<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Support\Money;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * «المصاريف» — every expense out of every account, newest first. TREASURY-DESIGN §٢١.
 *
 * **The same lines as the account page's «المصاريف» filter**, read across accounts: movements of
 * kind `expense` — a hand expense, what Nawris kept at settlement («رسوم شركة التوصيل»), and an
 * investor deal's expense. So the tab and each account always agree.
 *
 * **The money leaving, not its mirror.** A reversal is a line of its own that puts the money
 * back; here the original is listed and drawn struck through (`is_reversed`), and left out of the
 * total. The reversal line itself would be a second row for one expense.
 */
final class ExpenseLedger
{
    /**
     * @param  array{from?: ?string, to?: ?string, category_id?: ?int, account_id?: ?int, search?: ?string}  $filters
     * @return LengthAwarePaginator<int, TreasuryMovement>
     */
    public function page(array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->with([
                'account',
                'recorder',
                'operation.category',
                'operation.employee',
                // لـ`is_reversible` و`is_reversed` — دفعةً واحدة للصفحة، كما في سجلّ الحساب.
                'operation.reversedBy',
                'reversedBy',
            ])
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * What the filtered expenses add up to — the reversed ones left out.
     *
     * @param  array{from?: ?string, to?: ?string, category_id?: ?int, account_id?: ?int, search?: ?string}  $filters
     */
    public function total(array $filters): string
    {
        $sum = $this->filtered($filters)->whereDoesntHave('reversedBy')->sum('amount');

        return Money::round((string) $sum);
    }

    /**
     * @param  array{from?: ?string, to?: ?string, category_id?: ?int, account_id?: ?int, search?: ?string}  $filters
     * @return Builder<TreasuryMovement>
     */
    private function filtered(array $filters): Builder
    {
        return TreasuryMovement::query()
            ->where('kind', MovementKind::Expense->value)
            ->where('direction', MovementDirection::Out->value)
            ->whereNull('reverses_movement_id')
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->where('occurred_at', '>=', Carbon::parse($from)->startOfDay()))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->where('occurred_at', '<=', Carbon::parse($to)->endOfDay()))
            ->when($filters['account_id'] ?? null, fn ($q, $id) => $q->where('account_id', $id))
            // The category lives on the operation. A carrier fee's settlement names «رسوم شركة
            // التوصيل»; a deal expense has no operation, so no category filter matches it.
            ->when($filters['category_id'] ?? null, fn ($q, $id) => $q->whereHas(
                'operation',
                fn ($q) => $q->where('category_id', $id),
            ))
            ->when(trim((string) ($filters['search'] ?? '')), fn ($q, $search) => $this->whereMatches($q, $search));
    }

    /**
     * مربّع البحث في التبويب — **كلُّ ما يُقرأ في السطر**: اسم التصنيف، واسم الحساب، والملاحظة
     * (على الحركة أو على العملية)، واسم الموظف الذي صُرف له، والمبلغ.
     *
     * المبلغ يُطابَق **بالتمام** لا بالجزء: «150» تجد مصروف ١٥٠ لا ١٥٠٠. والأرقام العربية تُقرأ
     * كما تكتبها لوحة المفاتيح، والفاصلة العربية «٫» نقطةً.
     *
     * @param  Builder<TreasuryMovement>  $query
     * @return Builder<TreasuryMovement>
     */
    private function whereMatches(Builder $query, string $search): Builder
    {
        $like = '%'.$search.'%';
        $amount = strtr($search, [
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9', '٫' => '.',
        ]);

        return $query->where(function (Builder $q) use ($like, $amount): void {
            $q->where('notes', 'ilike', $like)
                ->orWhereHas('account', fn ($q) => $q->where('name', 'ilike', $like))
                ->orWhereHas('operation', fn ($q) => $q
                    ->where('notes', 'ilike', $like)
                    ->orWhereHas('category', fn ($q) => $q->where('name', 'ilike', $like))
                    ->orWhereHas('employee', fn ($q) => $q->where('name', 'ilike', $like)));

            // Plain digits with at most one point — `is_numeric` would let «1e5» through to bcmath.
            if (preg_match('/^\d{1,12}(\.\d{1,2})?$/', $amount) === 1) {
                $q->orWhere('amount', Money::round($amount));
            }
        });
    }
}
