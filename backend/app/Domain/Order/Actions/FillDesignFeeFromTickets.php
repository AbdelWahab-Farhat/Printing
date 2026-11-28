<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Events\OrderDesignFeeFilled;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;

/**
 * Fills «أجرة التصميم» from «أجرة المصمم» when nobody set it. See ORDER-DESIGN-FEE.md.
 *
 * Called when one of the order's design tickets is approved, inside that transaction, with what
 * the designers of all its approved tickets are paid together. The fee becomes that sum and the
 * design becomes ours, so the customer pays at least what the designers cost. Whoever may see the
 * fee is told, through {@see OrderDesignFeeFilled}, so they can set the real price.
 *
 * **Silent when it may not act**: a fee a person decided (zero included), an order that has closed
 * or is a compensation, or no pay at all. Approving the design must never fail over the fee.
 *
 * Turned off entirely by `ORDERS_FILL_DESIGN_FEE_FROM_PAY=false` (config/orders.php).
 */
final class FillDesignFeeFromTickets
{
    public function __construct(
        private readonly RecalculateOrderTotals $recalculateTotals,
        private readonly RecalculateOrderPayments $recalculatePayments,
    ) {}

    /**
     * @return string|null the fee written, or null when nothing was
     */
    public function __invoke(Order $order, string $designersPay, ?int $actorId = null): ?string
    {
        if (! config('orders.design_fee.fill_from_designer_pay', true)) {
            return null;
        }

        $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->first();

        if ($locked === null || $locked->design_fee_set_at !== null || ! $locked->designFeeIsEditable()) {
            return null;
        }

        $amount = Money::normalize($designersPay);

        if (bccomp($amount, '0', Money::SCALE) <= 0) {
            return null;
        }

        if (bccomp($amount, (string) $locked->design_fee, Money::SCALE) === 0
            && $locked->design_source->isChargeable()) {
            return null;
        }

        $locked->forceFill([
            'design_fee' => $amount,
            'design_source' => DesignSource::InHouse,
        ])->save();

        ($this->recalculateTotals)($locked->load('items'));
        ($this->recalculatePayments)($locked->refresh());

        OrderDesignFeeFilled::dispatch((int) $locked->getKey(), $amount, $actorId);

        return $amount;
    }
}
