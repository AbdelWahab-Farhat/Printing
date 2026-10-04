<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * «دفعات بانتظار المراجعة» — the reviewer's work list, across every order.
 *
 * **Three conditions, the same three {@see OrderPayment::awaitsReview()} answers for one row**: the
 * entry was stamped `requires_review`, nobody has reviewed it, and it was not cancelled as a
 * mistake since. A reversed payment leaves the list the moment it is reversed — there is nothing
 * left in it to check.
 *
 * **Oldest first**, because it is a queue and not a feed: the entry that has waited longest is the
 * one the reviewer reaches for. Ordered by when the money moved, so a back-dated deposit sits where
 * its day is.
 *
 * Entries on a deleted order are left out with the order — the archive is read, not worked.
 */
final class PaymentReviewQueue
{
    /**
     * @param  array{from?: ?string, to?: ?string, account_id?: ?int, recorded_by?: ?int, type?: ?string}  $filters
     * @return LengthAwarePaginator<int, OrderPayment>
     */
    public function page(array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->with(['order.customer', 'recorder', 'reviewer', 'reversal', 'treasuryAccount'])
            ->orderBy('paid_at')
            ->orderBy('id')
            ->paginate($perPage);
    }

    /**
     * What the filtered queue adds up to, in and out — never one signed figure: «٥٠٠ بانتظار
     * المراجعة» made of 700 in and 200 out would describe no money anybody holds.
     *
     * @param  array{from?: ?string, to?: ?string, account_id?: ?int, recorded_by?: ?int, type?: ?string}  $filters
     * @return array{incoming_total: string, outgoing_total: string}
     */
    public function totals(array $filters): array
    {
        $sum = fn (OrderPaymentType $type): string => Money::round((string) $this->filtered($filters)
            ->where('type', $type->value)
            ->sum('amount'));

        return [
            'incoming_total' => $sum(OrderPaymentType::Payment),
            'outgoing_total' => $sum(OrderPaymentType::Refund),
        ];
    }

    /**
     * @param  array{from?: ?string, to?: ?string, account_id?: ?int, recorded_by?: ?int, type?: ?string}  $filters
     * @return Builder<OrderPayment>
     */
    private function filtered(array $filters): Builder
    {
        return OrderPayment::query()
            ->where('requires_review', true)
            ->whereNull('reviewed_at')
            ->whereDoesntHave('reversal')
            ->whereHas('order')
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->where('paid_at', '>=', Carbon::parse($from)->startOfDay()))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->where('paid_at', '<=', Carbon::parse($to)->endOfDay()))
            ->when($filters['account_id'] ?? null, fn ($q, $id) => $q->where('treasury_account_id', $id))
            ->when($filters['recorded_by'] ?? null, fn ($q, $id) => $q->where('recorded_by', $id))
            ->when($filters['type'] ?? null, fn ($q, $type) => $q->where('type', $type));
    }
}
