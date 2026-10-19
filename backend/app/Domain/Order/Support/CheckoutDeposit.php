<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderStatusTransition;
use Illuminate\Database\Eloquent\Builder;

/**
 * The rule for the عربون a customer chooses in the basket — owner, 2026-10-19.
 *
 * **At least a quarter of the goods, at most all of them, in whole dinars.** The base is the
 * order's own total — the goods, with no delivery: the courier's fee is paid at the door and is
 * not ours to take a deposit on, and it is the same figure staff are capped at when they name a
 * deposit by hand (`TransitionFields::deposit()`). And no fractions (owner, same day): the least
 * is the quarter **rounded up** to the dinar, the most is the goods **rounded down** to it — so a
 * 500.50 order takes at most 500, and the half dinar is paid with the rest.
 *
 * **The floor binds the customer only.** Staff still name whatever عربون they agree with the
 * customer, with no floor beyond «أكبر من صفر» — what the shop asks for at its own counter is the
 * shop's business. This class is read by the basket's quote and by `PlaceOrderWithDeposit`, so
 * what the app offers and what the server accepts are one rule.
 */
final class CheckoutDeposit
{
    /** The least share of the total a customer may pay as عربون, in percent. */
    public const MIN_PERCENT = '25';

    /**
     * A quarter of [$total], **rounded up to the whole dinar**: rounding down would let a payment
     * short of a quarter through, which is the one thing the floor exists to stop.
     */
    public static function minimum(string $total): string
    {
        $exact = bcdiv(bcmul($total, self::MIN_PERCENT, 8), '100', 8);
        $whole = bcadd($exact, '0', 0);

        if (bccomp($exact, $whole, 8) > 0) {
            $whole = bcadd($whole, '1', 0);
        }

        return bcadd($whole, '0', Money::SCALE);
    }

    /** The goods, **rounded down to the whole dinar** — the most a basket deposit may be. */
    public static function maximum(string $total): string
    {
        return bcadd(bcadd($total, '0', 0), '0', Money::SCALE);
    }

    /**
     * Whether a whole-dinar deposit fits between the two at all. An order under a dinar, or one
     * whose quarter rounds up past its own whole dinars, has none to offer.
     */
    public static function fits(string $total): bool
    {
        return bccomp($total, '0', Money::SCALE) > 0
            && bccomp(self::minimum($total), '0', Money::SCALE) > 0
            && bccomp(self::minimum($total), self::maximum($total), Money::SCALE) <= 0;
    }

    /**
     * Whether an order just written from the basket may skip review and go straight to its
     * عربون. **Every line priced, nothing for a vendor, and a whole-dinar deposit to take**: an
     * unpriced line has no total to take a quarter of, a وسيط order needs a vendor only staff can
     * name. Either goes to «بانتظار المراجعة» as before.
     */
    public static function isOfferedFor(Order $order): bool
    {
        return ! $order->hasUnpricedLines()
            && ! $order->production_flow->needsAVendor()
            && self::fits((string) $order->grand_total);
    }

    /**
     * Whether an app order the shop has just accepted asks the customer for their عربون —
     * owner, 2026-10-19 (`ChooseOrderDeposit`).
     *
     * **The basket's step, deferred.** A basket with a وسيط line or a «حسب الطلب» line could not be
     * offered the deposit when it was placed — there was a vendor to name or a price to quote —
     * so it went to review. Once accepted it has both, and the customer is offered the same choice
     * the basket would have offered: at least a quarter, office or wallet.
     *
     * Only **while «جديدة»** — staff who move it on have decided to go ahead without one — and
     * only for an order that **came through review**: a clerk's order never had a basket, and an
     * order that already names a deposit, or has money on it, has had its answer.
     */
    public static function isOfferedAfterReview(Order $order): bool
    {
        return $order->status === OrderStatus::New
            && $order->deposit_expected_amount === null
            && bccomp((string) $order->paid_amount, '0', Money::SCALE) <= 0
            && ! $order->hasUnpricedLines()
            && self::fits((string) $order->grand_total)
            && self::cameThroughReview($order);
    }

    /**
     * [isOfferedAfterReview] asked of a query — «طلباتي» filtering by stage, where the order is
     * «بانتظار العربون» to its customer while still «جديدة» to the shop.
     *
     * **The same conditions in SQL**, less the unpriced lines — an order accepted out of review has
     * every line priced by the guard on that move — and with «a whole-dinar deposit fits» written
     * as `grand_total >= 1`, which is what {@see fits()} comes to.
     *
     * @param  Builder<Order>  $query
     * @return Builder<Order>
     */
    public static function whereOfferedAfterReview(Builder $query): Builder
    {
        return $query
            ->where('status', OrderStatus::New->value)
            ->whereNull('deposit_expected_amount')
            ->where('paid_amount', '<=', 0)
            ->where('grand_total', '>=', 1)
            ->whereHas('transitions', fn (Builder $transition) => self::acceptance($transition));
    }

    /**
     * The acceptance row, for a list that asks every order at once — eager as `came_through_review`
     * through `withExists`, so a page of fifteen is one query, not fifteen.
     *
     * @param  Builder<OrderStatusTransition>  $transition
     * @return Builder<OrderStatusTransition>
     */
    public static function acceptance(Builder $transition): Builder
    {
        return $transition
            ->where('from_status', OrderStatus::Requested->value)
            ->where('to_status', OrderStatus::New->value);
    }

    /** The order was accepted out of «بانتظار المراجعة» — it was the customer's, from the app. */
    private static function cameThroughReview(Order $order): bool
    {
        // Eager on a list — see {@see acceptance()}.
        if (array_key_exists('came_through_review', $order->getAttributes())) {
            return (bool) $order->getAttribute('came_through_review');
        }

        if ($order->relationLoaded('transitions')) {
            return $order->transitions->contains(
                fn (OrderStatusTransition $t): bool => $t->from_status === OrderStatus::Requested
                    && $t->to_status === OrderStatus::New,
            );
        }

        return self::acceptance($order->transitions()->getQuery())->exists();
    }
}
