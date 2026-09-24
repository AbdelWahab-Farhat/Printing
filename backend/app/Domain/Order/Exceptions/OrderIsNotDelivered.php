<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * Undoing a delivery on an order that is not standing in «تم الاستلام».
 *
 * A settled order gets its own sentence, because it *was* delivered and the way back exists — it
 * is one step further: the settlement comes off first.
 */
final class OrderIsNotDelivered extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        $delivered = OrderStatus::Delivered->label();

        if ($status === OrderStatus::Settled) {
            return new self(
                "الطلبية في «{$status->label()}». تراجع عن التسوية أولاً — ترجع إلى «{$delivered}» — ثم تراجع عن التسليم",
            );
        }

        return new self("الطلبية ليست في «{$delivered}» — حالتها «{$status->label()}»، ولا يوجد تسليم يُتراجع عنه");
    }
}
