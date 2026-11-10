<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Support\Exceptions\DomainException;

/**
 * A delivered or settled order is closed to every edit but its discount.
 *
 * Separate from {@see OrderIsClosed} because the answer is different: that one says «nothing may
 * be done here», this one says «one thing may, and it was not the thing you sent». See
 * {@see Order::discountIsEditable()}.
 */
final class ClosedOrderTakesOnlyADiscount extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        return new self("الطلبية «{$status->label()}» ولا يُعدَّل فيها إلا الخصم");
    }
}
