<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\Order\Models\Order;
use Closure;
use Illuminate\Support\Facades\DB;

/**
 * An order from the app, placed once however many times it is sent.
 *
 * **The case it is for**: the server wrote the order and the reply never reached the phone — a
 * timeout, a dropped signal. The basket is still full, so the customer presses «إرسال» again.
 * The app sends the same `client_token` until an order lands, and the same key again is answered
 * with the first order (`wasRecentlyCreated` false) — no second one on the review queue, and no
 * second عربون from the wallet.
 *
 * **Asked under the customer's lock**, the one {@see PayOrderFromWallet} also takes, so two
 * copies racing each other meet there: the second waits, then finds the first. The unique index
 * on `orders (customer_id, client_token)` is the last guard.
 *
 * **Deleted orders count**, as the index counts them: a resend of an order the shop deleted gets
 * that order back, not a fresh copy of it.
 */
final class PlaceOrderOnce
{
    /**
     * @param  Closure(): Order  $place  writes the order — {@see RequestOrder} or
     *                                   {@see PlaceOrderWithDeposit}
     */
    public function __invoke(int $customerId, ?string $clientToken, Closure $place): Order
    {
        // An app older than the key: every press is an order, as it always was.
        if ($clientToken === null) {
            return $place();
        }

        return DB::transaction(function () use ($customerId, $clientToken, $place): Order {
            Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

            $placed = Order::withTrashed()
                ->where('customer_id', $customerId)
                ->where('client_token', $clientToken)
                ->first();

            return $placed ?? $place();
        });
    }
}
