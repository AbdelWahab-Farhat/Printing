<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Order\Models\Order;

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
}
