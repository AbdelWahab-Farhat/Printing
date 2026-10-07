<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Events\OrderPaymentsRecalculated;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;

/**
 * Adds the ledger up and writes the answers onto the order.
 *
 * **The one place `orders.paid_amount` and `orders.written_off_amount` are ever written**, which
 * is why both columns are absent from the model's fillable list. Everything else records an
 * entry; this totals them. Exactly the arrangement {@see RecalculateOrderTotals} has with the
 * lines, and `ApplyStockChange` has with a shelf balance.
 *
 * **Three totals out of one walk, because the ledger holds three different kinds of closing.**
 * Cash lands in the first, forgiven money in the second, and money the courier took at the door in
 * the third — see {@see OrderPayment::affectsWriteOff()} and
 * {@see OrderPayment::affectsCarrierSettlement()}, which are also what route a *reversal* to
 * whichever total its original belonged to. Summing all three here rather than in three passes is
 * what makes it impossible for one to be written without the others.
 *
 * Must run inside the transaction that wrote the entry — otherwise a reader can catch the ledger
 * and its totals disagreeing, which is the one thing a cached total must never do.
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
        $totals = ['paid' => '0', 'written_off' => '0', 'carrier_settled' => '0', 'excess' => '0'];

        // `reversedPayment` eagerly, because a reversal is asked what it undoes: strict mode
        // would refuse the lazy load, and even without it this is the N+1 that turns saving one
        // payment into a query per row of the ledger.
        //
        // **Each row says what it does to each total** — {@see OrderPayment::contributions()} —
        // which is how a payment of 100 on a debt of 99 lands 99 on «المدفوع» and 1 on what is
        // owed back to the customer, without this loop knowing which part was which.
        foreach ($order->payments()->with('reversedPayment')->get() as $entry) {
            foreach ($entry->contributions() as $total => $part) {
                $totals[$total] = bcadd($totals[$total], $part, 8);
            }
        }

        // forceFill, because none of the four is fillable: a request that could set
        // `paid_amount` could tell us it had been paid, one that could set `written_off_amount`
        // could forgive a debt without anybody deciding to, one that could set
        // `carrier_settled_amount` could close an order by claiming a courier had been paid, and
        // one that could set `excess_amount` could make the shop owe a customer money.
        $order->forceFill([
            'paid_amount' => Money::round($totals['paid']),
            'written_off_amount' => Money::round($totals['written_off']),
            'carrier_settled_amount' => Money::round($totals['carrier_settled']),
            'excess_amount' => Money::round($totals['excess']),
        ])->save();

        // **خزينةُ الصندوق تتحرّك من هنا.** هذا هو المعبرُ الذي يمرّ به كلُّ طريقٍ يحرّك مالَ
        // طلبية، فحدثٌ واحدٌ فيه أضمنُ من أربعةٍ عند كلٍّ منها. والمستمعُ في نطاق المستثمرين
        // يعيد حساب نصيب الصندوق ويصحّح نفسه، فلا يضرّه أن يصل مرّتين.
        event(new OrderPaymentsRecalculated((int) $order->getKey()));

        return $order;
    }
}
