<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Exceptions\PaymentCannotBeSettled;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * «تسوية دفعة» — one or several payments' money carried to the account it reached, **without
 * waiting for the order to reach «تم التسوية»**. TREASURY-DESIGN §٢٣.
 *
 * Nawris pays a week of parcels in one transfer, and a customer's transfer reaches «مصرف علي»
 * days before the order is closed: the money is real now, and the ledger should say where it is
 * now. Neither the order's status nor what the customer paid changes — this only moves money.
 *
 * **All or nothing.** Ten payments settled together are ten operations, so each can be undone on
 * its own, but one refusal takes the other nine back with it: half a Nawris transfer settled is a
 * transfer nobody can match any more.
 *
 * **Locks: the orders in id order, then the accounts in id order** — the order every other path
 * takes (a payment, a reversal, «تم التسوية» each lock the order before its accounts), so two
 * batches, or a batch and a settlement, wait for each other rather than deadlock.
 */
final class SettleOrderPayments
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  list<array{payment_id: int, fee?: ?string}>  $rows
     * @param  ?int  $accountId  where they all go — null: each to its own automatic account
     * @return Collection<int, OrderPayment>
     */
    public function __invoke(array $rows, ?int $accountId, ?User $actor = null): Collection
    {
        return DB::transaction(function () use ($rows, $accountId, $actor): Collection {
            $ids = array_map(fn (array $row) => (int) $row['payment_id'], $rows);
            $payments = OrderPayment::query()->whereIn('id', $ids)->get()->keyBy('id');

            $orders = Order::query()
                ->whereIn('id', $payments->pluck('order_id')->unique()->all())
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->keyBy('id');

            $this->treasury->lockAccounts($payments->pluck('treasury_account_id')->filter()->map(fn ($id) => (int) $id)->values()->all());

            $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();

            foreach ($rows as $index => $row) {
                $payment = $payments->get((int) $row['payment_id'])
                    ?? throw PaymentCannotBeSettled::missing()->onField("payments.{$index}.payment_id");
                $order = $orders->get($payment->order_id);

                if ($refusal = $payment->settlementRefusal($order)) {
                    throw $refusal->onField("payments.{$index}.payment_id");
                }

                $this->treasury->settlePayment(
                    (int) $order->getKey(),
                    (int) $payment->getKey(),
                    (int) $payment->treasury_account_id,
                    (string) $payment->amount,
                    $accountId,
                    isset($row['fee']) ? (string) $row['fee'] : null,
                    $actorId,
                    (string) $order->code,
                    paymentField: "payments.{$index}.payment_id",
                    accountField: 'account_id',
                    feeField: "payments.{$index}.fee",
                );
            }

            return OrderPayment::query()->whereIn('id', $ids)->get();
        });
    }
}
