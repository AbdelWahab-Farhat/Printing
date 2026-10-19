<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\CheckoutPayment;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderRequested;
use App\Domain\Order\Exceptions\CheckoutDepositRefused;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\CheckoutDeposit;
use App\Domain\Order\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * A customer orders from the app **and chooses the عربون in the basket** — owner, 2026-10-19.
 *
 * The other door beside {@see RequestOrder}, and built on the same {@see CreateOrder}. What it
 * changes is that the order skips «بانتظار المراجعة»:
 *
 * - **في المكتب** — born «انتظار العربون» with the amount the customer chose, expected in cash.
 *   Staff move it to «عربون مدفوع» when the money reaches the counter, as for any deposit.
 * - **من المحفظة** — born «انتظار العربون» and paid from the wallet in the same transaction,
 *   which moves it to «عربون مدفوع» by the rule {@see PayOrderFromWallet} already keeps. A wallet
 *   that cannot cover it refuses the payment, and the order goes with it: nothing is written.
 *
 * **Online is the wallet, after the money is in** (owner, 2026-10-19): the app tops the wallet up
 * with the deposit first and places the order only once that top-up has succeeded — so no order
 * ever waits on a payment that may not come.
 *
 * **Born there, not walked there.** The order is written straight into «انتظار العربون» rather
 * than accepted and moved: nobody on the staff accepted it, and a «جديدة» row between would be a
 * move nobody made — and would tell the customer «قبلنا طلبيتك» about an order they placed a
 * second ago. The deposit columns are the two `ChangeOrderStatus` writes on the way in, written
 * here for that reason.
 *
 * **Only for a basket review has nothing to add** — see {@see CheckoutDeposit::isOfferedFor()}.
 * The basket is asked first through {@see QuoteBasket}, the same question that drew the step in
 * the app, so a basket that grew a وسيط line since is refused before an order is written — the
 * vendor rule in `CreateOrder` would otherwise refuse it with words about a vendor the customer
 * never heard of.
 */
final class PlaceOrderWithDeposit
{
    public function __construct(
        private readonly QuoteBasket $quoteBasket,
        private readonly CreateOrder $createOrder,
        private readonly PayOrderFromWallet $payFromWallet,
    ) {}

    /**
     * @param  ?string  $clientToken  the app's key for the wallet payment — a retry pays nothing
     *
     * @throws CheckoutDepositRefused
     */
    public function __invoke(
        OrderData $data,
        CheckoutPayment $payment,
        string $amount,
        ?string $clientToken = null,
    ): Order {
        $amount = Money::normalize($amount);

        if (($this->quoteBasket)($data->items ?? [], null)->depositMinimum === null) {
            throw CheckoutDepositRefused::notOffered();
        }

        $order = DB::transaction(function () use ($data, $payment, $amount, $clientToken): Order {
            $order = ($this->createOrder)($data, null, OrderStatus::AwaitingDeposit);

            if (! CheckoutDeposit::isOfferedFor($order)) {
                throw CheckoutDepositRefused::notOffered();
            }

            $total = (string) $order->grand_total;
            $minimum = CheckoutDeposit::minimum($total);
            $maximum = CheckoutDeposit::maximum($total);

            if (bccomp($amount, $minimum, Money::SCALE) < 0) {
                throw CheckoutDepositRefused::belowMinimum($minimum);
            }

            if (bccomp($amount, $maximum, Money::SCALE) > 0) {
                throw CheckoutDepositRefused::aboveTotal($maximum);
            }

            $order->forceFill([
                'deposit_expected_amount' => $amount,
                'deposit_expected_method' => $payment->expectedMethod(),
            ])->save();

            if ($payment === CheckoutPayment::Wallet) {
                ($this->payFromWallet)($order, $amount, null, $clientToken);
            }

            return $order->refresh();
        });

        // After the commit, like `RequestOrder`: the reviewers' bell, saying this one needs no
        // review but is new to them all the same.
        OrderRequested::dispatch((int) $order->getKey(), skippedReview: true);

        return $order;
    }
}
