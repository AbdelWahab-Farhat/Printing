<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Models\TreasuryMovement;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
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
     * `has_order` يقصر السجلّ على المال الذي تملكه طلبية — دفعاتها وردودها وتسوياتها — وهو فلتر
     * «الطلبيات» في صفحة الحساب. و`search` رقم طلبيةٍ كما يُكتب في مربّع البحث.
     *
     * @param  array{from?: ?string, to?: ?string, kind?: ?string, order_id?: ?int, has_order?: mixed, search?: ?string}  $filters
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
            ->when((bool) ($filters['has_order'] ?? false), fn ($q) => $q->whereNotNull('order_id'))
            ->when($filters['search'] ?? null, fn ($q, $search) => $this->whereOrderNumber($q, $search))
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

    /**
     * رقم الطلبية يُطابق كاملاً كما في بحث شاشة الطلبيات (`OrderSearchTerm`): «129» ليست «1290».
     * والرقم هو `order_id` نفسه الذي يطبعه سطر السجلّ — رقم الطلبية يساوي معرّفها
     * (`AllocateOrderIdentifier`) — فلا حاجة إلى جدول الطلبيات، والخزينة لا تستورد سياق الطلبيات.
     *
     * الأرقام العربية أولاً، فهي ما تُخرجه لوحة المفاتيح الليبية. وما ليس رقماً لا يطابق شيئاً.
     *
     * @param  Builder<TreasuryMovement>  $query
     * @return Builder<TreasuryMovement>
     */
    private function whereOrderNumber(Builder $query, string $search): Builder
    {
        $digits = strtr(trim($search), [
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4',
            '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
            '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
        ]);

        return ctype_digit($digits) && strlen($digits) <= 18
            ? $query->where('order_id', (int) $digits)
            : $query->whereRaw('false');
    }
}
