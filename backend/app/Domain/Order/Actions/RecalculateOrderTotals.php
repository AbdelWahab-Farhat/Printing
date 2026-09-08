<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Exceptions\DiscountExceedsTotal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;

/**
 * Derives every total on an order from its lines.
 *
 * The one place that decides what an order costs, so a client can never post a total and no two
 * code paths can disagree about how one is reached. Called after anything that could move a
 * number: lines changing, the destination changing, a design fee being agreed, a discount being
 * applied.
 *
 * A design fee only counts when we did the design. Left as it is on the row rather than blanked,
 * so switching `design_source` back and forth does not lose a number a clerk typed — it simply
 * stops being charged.
 *
 * **`delivery_price` is not one of these numbers, by the owner's instruction.** The fee is the
 * courier's, collected from the customer at their door on the courier's own account — it is
 * neither money we take nor a cost we bear, so an order's total is the goods and our own charges
 * and nothing else. The column stays on the row and on every screen, because a clerk quoting an
 * order still has to say what the trip will cost; it simply stops being added to anything. See
 * {@see \App\Domain\Carrier\Actions\BuildNawrisPayload::amountToCollect()}, which stopped
 * subtracting it on the same day for the same reason.
 *
 * **The additional cost joins the base the discount is measured against, deliberately.** The
 * ceiling on a discount is what the customer would otherwise pay, and a charge for packaging is
 * part of that — so an order of 350 carrying a 10 charge may be discounted by 360 and reach
 * zero, but never below it. The two stay separate columns either side of this sum: an order's
 * total is read as «هذا ما أُضيف وهذا ما خُصم», not as one net figure that explains neither.
 */
final class RecalculateOrderTotals
{
    /**
     * @throws DiscountExceedsTotal
     */
    public function __invoke(Order $order): Order
    {
        $itemsTotal = Money::sum(
            ...$order->items()->get()->map(fn (OrderItem $item) => (string) $item->line_total)->all(),
        );

        $designFee = $order->design_source->isChargeable() ? (string) $order->design_fee : '0.00';

        $beforeDiscount = Money::sum(
            $itemsTotal,
            $designFee,
            (string) $order->additional_cost,
        );
        $discount = (string) $order->discount;

        // Refused rather than clamped: silently shrinking a discount to fit would charge the
        // customer more than the clerk told them, and nothing on screen would say so.
        if (bccomp($discount, $beforeDiscount, Money::SCALE) > 0) {
            throw DiscountExceedsTotal::make($discount, $beforeDiscount);
        }

        $order->forceFill([
            'items_total' => $itemsTotal,
            'grand_total' => Money::round(bcsub($beforeDiscount, $discount, 8)),
        ])->save();

        return $order;
    }
}
