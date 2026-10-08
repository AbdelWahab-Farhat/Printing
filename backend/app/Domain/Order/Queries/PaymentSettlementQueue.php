<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\BusinessDay;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * «تسوية الدفعات» — the payments whose money is still where it landed, and those already carried
 * on. TREASURY-DESIGN §٢٣.
 *
 * **«بانتظار التسوية»**: every live payment with an account, on an order not yet «تم التسوية»,
 * whose own settlement does not stand — **wherever the money sits**. The owner's choice B,
 * 2026-10-08: cash in the company's box may still be taken to somebody's own account or another,
 * so it waits too until somebody settles it. Money that would move by itself at settlement
 * carries its account in `settlement_target`; money already in its place carries none and is
 * settled to an account somebody names. Oldest first, by when the money was taken: it is a work
 * list. The dates filter that day.
 *
 * **«مسوّاة»**: a payment whose own settlement stands. Newest settlement first, and the dates
 * filter the day it was settled — the question there is «what did we settle this week».
 */
final class PaymentSettlementQueue
{
    public const PENDING = 'pending';

    public const SETTLED = 'settled';

    /**
     * @param  array{state?: ?string, from?: ?string, to?: ?string, account_id?: ?int, q?: ?string}  $filters
     * @return LengthAwarePaginator<int, OrderPayment>
     */
    public function page(array $filters, int $perPage): LengthAwarePaginator
    {
        $query = $this->filtered($filters)->with([
            'order.customer',
            'recorder',
            'reviewer',
            'reversal',
            'treasuryAccount',
            'standingSettlement.toAccount',
            'standingSettlement.recorder',
            'standingSettlement.movements',
        ]);

        if ($this->settled($filters)) {
            return $query
                ->orderByDesc($this->settlementColumn('occurred_at'))
                ->orderByDesc('id')
                ->paginate($perPage);
        }

        return $query->orderBy('paid_at')->orderBy('id')->paginate($perPage);
    }

    /**
     * What the whole filtered list adds up to.
     *
     * @param  array{state?: ?string, from?: ?string, to?: ?string, account_id?: ?int, q?: ?string}  $filters
     * @return array{amount_total: string}
     */
    public function totals(array $filters): array
    {
        return ['amount_total' => Money::round((string) $this->filtered($filters)->sum('amount'))];
    }

    /**
     * @param  array{state?: ?string, from?: ?string, to?: ?string, account_id?: ?int, q?: ?string}  $filters
     * @return Builder<OrderPayment>
     */
    private function filtered(array $filters): Builder
    {
        // أيامُ المحلّ بتوقيت طرابلس، لا أيامُ UTC ({@see BusinessDay}).
        $from = ($filters['from'] ?? null) === null ? null : BusinessDay::start($filters['from']);
        $to = ($filters['to'] ?? null) === null ? null : BusinessDay::end($filters['to']);

        $query = OrderPayment::query()
            ->where('type', OrderPaymentType::Payment->value)
            ->whereNotNull('treasury_account_id')
            ->whereDoesntHave('reversal')
            ->when($filters['account_id'] ?? null, fn ($q, $id) => $q->where('treasury_account_id', $id))
            ->when(trim((string) ($filters['q'] ?? '')), fn ($q, $term) => $q->whereHas('order', fn ($order) => $order
                ->where(fn ($match) => $match
                    ->where('code', 'ilike', "%{$term}%")
                    ->orWhereHas('customer', fn ($customer) => $customer->where('name', 'ilike', "%{$term}%")))));

        if ($this->settled($filters)) {
            return $query->whereHas('standingSettlement', fn ($s) => $s
                ->when($from, fn ($q) => $q->where('occurred_at', '>=', $from))
                ->when($to, fn ($q) => $q->where('occurred_at', '<=', $to)));
        }

        return $query
            ->whereHas('order', fn ($order) => $order->where('status', '<>', OrderStatus::Settled->value))
            ->whereDoesntHave('standingSettlement')
            ->when($from, fn ($q) => $q->where('paid_at', '>=', $from))
            ->when($to, fn ($q) => $q->where('paid_at', '<=', $to));
    }

    /**
     * @param  array{state?: ?string}  $filters
     */
    private function settled(array $filters): bool
    {
        return ($filters['state'] ?? self::PENDING) === self::SETTLED;
    }

    /**
     * @return Builder<TreasuryOperation>
     */
    private function settlementColumn(string $column): Builder
    {
        return TreasuryOperation::query()
            ->select($column)
            ->whereColumn('order_payment_id', 'order_payments.id')
            ->where('type', OperationType::Settlement->value)
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy')
            ->limit(1);
    }
}
