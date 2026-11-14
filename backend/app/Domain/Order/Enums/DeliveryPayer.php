<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * Who pays the courier's fee for an order: the recipient at the door, or us.
 *
 * **The recipient is the default and every order before 2026-11-13 is one.** Delivery left
 * `grand_total` on 2026-09-08 — «سعر التوصيل ... هو فقط على الزبون» — so the customer pays the
 * courier at the door and the fee is nobody's cost here.
 *
 * **When we pay, the fee is the order's own cost** (owner's decision, 2026-11-13, «الخيار ب»).
 * `orders.delivery_cost` carries it, `Order::grossProfit()` subtracts it, and the profit split
 * takes it off the order's extras — so the investors whose goods the order sold share it, exactly
 * as they share a discount. See Docs/orders/DELIVERY-PAYER.md.
 */
enum DeliveryPayer: string
{
    case Recipient = 'recipient';

    case Us = 'us';

    public function label(): string
    {
        return match ($this) {
            self::Recipient => 'المستلم',
            self::Us => 'علينا',
        };
    }
}
