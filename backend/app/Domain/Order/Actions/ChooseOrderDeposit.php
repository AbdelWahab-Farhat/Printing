<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\CheckoutPayment;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderDepositChosen;
use App\Domain\Order\Exceptions\CheckoutDepositRefused;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\CheckoutDeposit;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Support\Facades\DB;

/**
 * The customer chooses the عربون of an app order the shop accepted after review — owner,
 * 2026-10-19.
 *
 * **The basket's deposit step, for the orders that could not have one there.** A basket with a
 * وسيط or a «حسب الطلب» line went to «بانتظار المراجعة» instead (see {@see PlaceOrderWithDeposit});
 * once staff accept it to «جديدة» it has its vendor and its prices, and the app offers the same
 * choice: at least a quarter of the goods in whole dinars, at the office or from the wallet. An
 * online payment is a top-up the app completes first, then this, from the wallet.
 *
 * - **في المكتب** — «جديدة» → «انتظار العربون», the amount and «نقداً» written by the move itself.
 * - **من المحفظة** — the same move, then {@see PayOrderFromWallet} in the same transaction, whose
 *   own rule takes it on to «عربون مدفوع». A wallet that cannot cover it takes the move back.
 *
 * **Through {@see ChangeOrderStatus}, not beside it**: the order really does move, and the move
 * writes the timeline row, the event and the deposit columns exactly as a clerk's would. Nobody on
 * the staff made it, so the actor is null — the customer made it — and the customer's own push
 * stays quiet about a choice they just made (`NotifyCustomerWhenOrderStageChanges`).
 */
final class ChooseOrderDeposit
{
    public function __construct(
        private readonly ChangeOrderStatus $changeStatus,
        private readonly PayOrderFromWallet $payFromWallet,
    ) {}

    /**
     * @param  ?string  $clientToken  the app's key for the wallet payment — a retry pays nothing
     *
     * @throws CheckoutDepositRefused
     */
    public function __invoke(
        Order $order,
        CheckoutPayment $payment,
        string $amount,
        ?string $clientToken = null,
    ): Order {
        $amount = Money::normalize($amount);

        $order = DB::transaction(function () use ($order, $payment, $amount, $clientToken): Order {
            // Locked, then asked: two taps racing each other meet here, and the second finds the
            // order already in «انتظار العربون».
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if (! CheckoutDeposit::isOfferedAfterReview($locked)) {
                throw CheckoutDepositRefused::noLongerOffered();
            }

            $total = (string) $locked->grand_total;
            $minimum = CheckoutDeposit::minimum($total);
            $maximum = CheckoutDeposit::maximum($total);

            // Under `amount`, where this request carries it — the basket's is `deposit.amount`.
            if (bccomp($amount, $minimum, Money::SCALE) < 0) {
                throw CheckoutDepositRefused::belowMinimum($minimum, 'amount');
            }

            if (bccomp($amount, $maximum, Money::SCALE) > 0) {
                throw CheckoutDepositRefused::aboveTotal($maximum, 'amount');
            }

            ($this->changeStatus)($locked, OrderStatus::AwaitingDeposit, null, null, [
                TransitionFields::DEPOSIT_AMOUNT => $amount,
                TransitionFields::DEPOSIT_METHOD => $payment->expectedMethod()->value,
            ]);

            if ($payment === CheckoutPayment::Wallet) {
                ($this->payFromWallet)($locked->refresh(), $amount, null, $clientToken);
            }

            return $locked->refresh();
        });

        // After the commit: whoever accepted it is told what the customer decided.
        OrderDepositChosen::dispatch((int) $order->getKey());

        return $order;
    }
}
