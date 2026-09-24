<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * Undoing a settlement on an order that was never settled.
 *
 * The same shape as {@see OrderIsNotCancelled}, for the same reason: a correction was asked for
 * of something that has not happened, and the answer names where the order actually stands.
 */
final class OrderIsNotSettled extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        $settled = OrderStatus::Settled->label();

        return new self("الطلبية ليست في «{$settled}» — حالتها «{$status->label()}»، ولا توجد تسوية يُتراجع عنها");
    }
}
