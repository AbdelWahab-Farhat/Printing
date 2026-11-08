<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries\Concerns;

use App\Domain\Order\Models\OrderPayment;
use Illuminate\Database\Eloquent\Builder;

/**
 * ما تُضيَّق به قائمتا «مراجعة وتسوية الدفعات» معاً: الحساب، وطريقة الدفع، ومَن سجّل، والمبلغ.
 * مكتوبٌ مرّةً كي يعني الفلترُ الشيءَ نفسَه في التبويبين.
 */
trait FiltersPaymentEntries
{
    /**
     * @param  Builder<OrderPayment>  $query
     * @param  array<string, mixed>  $filters
     */
    private function narrowEntries(Builder $query, array $filters): void
    {
        $query
            ->when($filters['account_id'] ?? null, fn ($q, $id) => $q->where('treasury_account_id', $id))
            ->when($filters['method'] ?? null, fn ($q, $method) => $q->where('method', $method))
            ->when($filters['recorded_by'] ?? null, fn ($q, $id) => $q->where('recorded_by', $id))
            // `isset` لا `when` على القيمة: «0» حدٌّ صحيح، و`when` يقرؤها فراغاً.
            ->when(isset($filters['amount_min']), fn ($q) => $q->where('amount', '>=', $filters['amount_min']))
            ->when(isset($filters['amount_max']), fn ($q) => $q->where('amount', '<=', $filters['amount_max']));
    }
}
