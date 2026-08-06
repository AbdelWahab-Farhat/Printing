<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;

/**
 * Adds the ledger up and writes the answer onto the order.
 *
 * **The one place `orders.paid_amount` is ever written**, which is why the column is absent from
 * the model's fillable list. Everything else records an entry; this totals them. Exactly the
 * arrangement {@see RecalculateOrderTotals} has with the lines, and
 * `ApplyStockChange` has with a shelf balance.
 *
 * Must run inside the transaction that wrote the entry — otherwise a reader can catch the ledger
 * and its total disagreeing, which is the one thing a cached total must never do.
 *
 * **The rows are loaded rather than summed in SQL.** An order's ledger is a handful of entries,
 * `SUM(CASE WHEN …)` states the direction rule a second time in a second language, and
 * {@see OrderPayment::signedAmount()} already holds it once. If an order ever carried enough
 * entries for that to matter, something else has gone wrong.
 */
final class RecalculateOrderPayments
{
    public function __invoke(Order $order): Order
    {
        $total = '0';

        foreach ($order->payments()->get() as $entry) {
            $total = bcadd($total, $entry->signedAmount(), 8);
        }

        // forceFill, because `paid_amount` is deliberately not fillable: a request that could
        // set it could tell us it had been paid.
        $order->forceFill(['paid_amount' => Money::round($total)])->save();

        return $order;
    }
}
