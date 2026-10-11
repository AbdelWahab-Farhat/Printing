<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Exceptions\PaymentAmountMustBePositive;
use App\Domain\Order\Exceptions\WalletPaymentRefused;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Wallet\WalletService;
use Illuminate\Support\Facades\DB;

/**
 * «الدفع من المحفظة» — the one door through which an order is paid out of its customer's wallet.
 * Docs/payments/CUSTOMER-WALLET.md §٤.
 *
 * **Locks the order, then the customer** — the wallet's lock order — and only then reads the two
 * ceilings: what the wallet holds and what the order still owes. Paying beyond either is refused;
 * there is no overpayment from a wallet, so wallet money never becomes «زائد = إيراد».
 *
 * The payment itself is an ordinary row on the order's ledger, written by {@see RecordOrderPayment}
 * with the method «المحفظة» into «أرصدة محافظ الزبائن» — so the paid total, the investor listeners,
 * reversals and refunds all work as they do for cash. The wallet's own row points at it.
 *
 * **«بانتظار العربون» moves on by itself** when this payment covers the agreed عربون (or none was
 * agreed): the order goes to «تم دفع العربون», this payment becomes its deposit, and the receipt
 * is confirmed — nobody has to vouch for money the system itself moved. The owner's decision of
 * 2026-10-11.
 *
 * Called by a member of staff (`$actor`) or by the customer from the app (`$actor` null).
 */
final class PayOrderFromWallet
{
    public function __construct(
        private readonly RecordOrderPayment $recordPayment,
        private readonly ChangeOrderStatus $changeStatus,
        private readonly WalletService $wallet,
    ) {}

    /**
     * **A retry pays nothing.** `$clientToken` is the app's key for this request, kept until the
     * payment succeeds: the same key again — a connection that dropped after the server paid —
     * is answered with the first payment (`wasRecentlyCreated` false), asked before anything and
     * again under the locks, where two copies racing each other meet. The unique index on the
     * wallet's row is the last guard. A key already spent on another order is refused.
     *
     * @param  ?string  $amount  null pays as much as both ceilings allow
     */
    public function __invoke(
        Order $order,
        ?string $amount,
        ?User $actor = null,
        ?string $clientToken = null,
    ): OrderPayment {
        if (($sent = $this->alreadySent($order, $clientToken)) !== null) {
            return $sent;
        }

        if ($amount !== null && bccomp($amount, '0', Money::SCALE) <= 0) {
            throw PaymentAmountMustBePositive::make($amount);
        }

        return DB::transaction(function () use ($order, $amount, $actor, $clientToken): OrderPayment {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status === OrderStatus::Requested || $locked->status === OrderStatus::RequestRejected) {
                throw WalletPaymentRefused::notAnOrderYet($locked->status->label());
            }

            $remaining = $locked->remainingAmount();

            if (bccomp($remaining, '0', Money::SCALE) <= 0) {
                throw WalletPaymentRefused::nothingOwed();
            }

            // Under the customer's lock — two payments from one wallet cannot both spend its last
            // dinar. The order's own ceiling is checked by RecordOrderPayment under the order lock.
            $customerId = (int) $locked->customer_id;
            $balance = $this->wallet->lockedBalanceOf($customerId);

            // Under the order's lock and the customer's: a twin of this request that got here
            // first has written its row, and this one is it.
            if (($sent = $this->alreadySent($locked, $clientToken)) !== null) {
                return $sent;
            }

            // «ادفع ما تستطيع»: the smaller of what is owed and what is held.
            $amount ??= bccomp($balance, $remaining, Money::SCALE) < 0 ? $balance : $remaining;

            $this->wallet->guardCanPay($customerId, $amount);

            $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();
            $notes = $actor === null ? 'دُفعت من المحفظة عبر التطبيق' : 'دُفعت من المحفظة';

            $payment = ($this->recordPayment)($locked, OrderPaymentData::fromArray([
                'amount' => $amount,
                'method' => PaymentMethod::Wallet->value,
                'notes' => $notes,
            ])->intoSystemAccount(TreasuryAccount::CUSTOMER_WALLETS), $actor);

            $this->wallet->recordOrderPayment(
                $customerId,
                (int) $locked->getKey(),
                (int) $payment->getKey(),
                (string) $payment->amount,
                $payment->paid_at,
                $actorId,
                "الطلبية {$locked->code}",
                $clientToken,
            );

            $this->settleTheDeposit($locked->refresh(), $payment, $actor);

            return $payment;
        });
    }

    /**
     * The payment this key already made, or null when the key is new. Refused when the key paid
     * a different order: that is not a retry of this request, and answering with another order's
     * payment would tell the app this one is paid.
     */
    private function alreadySent(Order $order, ?string $clientToken): ?OrderPayment
    {
        $sent = $this->wallet->sentPayment((int) $order->customer_id, $clientToken);

        if ($sent === null) {
            return null;
        }

        [$orderId, $paymentId] = $sent;

        if ($orderId !== (int) $order->getKey()) {
            throw WalletPaymentRefused::keyUsedOnAnotherOrder();
        }

        return OrderPayment::query()->findOrFail($paymentId);
    }

    /**
     * «بانتظار العربون» → «تم دفع العربون», when this payment covers what was agreed.
     *
     * Moved through {@see ChangeOrderStatus} like any move — events, notifications and the
     * transition row included — carrying no payment field, so it writes nothing to the ledger;
     * this payment is then named as the deposit, and the receipt stamped as confirmed with nobody's
     * name: the system moved it.
     */
    private function settleTheDeposit(Order $order, OrderPayment $payment, ?User $actor): void
    {
        if ($order->status !== OrderStatus::AwaitingDeposit) {
            return;
        }

        if ($order->asksForADeposit()
            && bccomp((string) $payment->amount, (string) $order->deposit_expected_amount, Money::SCALE) < 0) {
            return;
        }

        ($this->changeStatus)($order, OrderStatus::DepositPaid, null, $actor);

        $order->refresh()->forceFill([
            'deposit_payment_id' => $payment->getKey(),
            'is_deposit_received' => true,
            'deposit_confirmed_at' => now(),
            'deposit_confirmed_by' => null,
        ])->save();
    }
}
