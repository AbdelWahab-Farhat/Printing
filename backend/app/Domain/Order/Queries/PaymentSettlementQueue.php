<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * «تسوية الدفعات» — the payments whose money is still where it landed, and those already carried
 * on. TREASURY-DESIGN §٢٣.
 *
 * **«بانتظار التسوية»**: a live payment, on an order not yet «تم التسوية», sitting in an account
 * whose money would move at settlement — custody always, an employee's or a branch's account
 * where the settler's account or collection would take it ({@see TreasuryService::accountsAwaitingSettlement()}).
 * A payment straight into its final account is in its place and never listed. Oldest first, by
 * when the money was taken: it is a work list. The dates filter that day.
 *
 * **«مسوّاة»**: a payment whose own settlement stands. Newest settlement first, and the dates
 * filter the day it was settled — the question there is «what did we settle this week».
 */
final class PaymentSettlementQueue
{
    public const PENDING = 'pending';

    public const SETTLED = 'settled';

    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  array{state?: ?string, from?: ?string, to?: ?string, account_id?: ?int, q?: ?string}  $filters
     * @return LengthAwarePaginator<int, OrderPayment>
     */
    public function page(array $filters, int $perPage, ?int $actorId): LengthAwarePaginator
    {
        $query = $this->filtered($filters, $actorId)->with([
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
    public function totals(array $filters, ?int $actorId): array
    {
        return ['amount_total' => Money::round((string) $this->filtered($filters, $actorId)->sum('amount'))];
    }

    /**
     * @param  array{state?: ?string, from?: ?string, to?: ?string, account_id?: ?int, q?: ?string}  $filters
     * @return Builder<OrderPayment>
     */
    private function filtered(array $filters, ?int $actorId): Builder
    {
        $from = ($filters['from'] ?? null) === null ? null : Carbon::parse($filters['from'])->startOfDay();
        $to = ($filters['to'] ?? null) === null ? null : Carbon::parse($filters['to'])->endOfDay();

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
            ->whereIn('treasury_account_id', $this->treasury->accountsAwaitingSettlement($actorId))
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
