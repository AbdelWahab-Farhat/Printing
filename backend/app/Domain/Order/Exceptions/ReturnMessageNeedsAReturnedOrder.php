<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\MarkReturnMessageSent;
use App\Domain\Order\Models\Order;
use App\Support\Exceptions\DomainException;

/**
 * Somebody confirmed «رسالة الراجع» on an order that is not in a return asking for one.
 *
 * See {@see Order::returnMessageApplies()} for which statuses count and
 * {@see MarkReturnMessageSent} for the write this refuses. The app is told the same thing by
 * `return_message_applies`, so this guards a switch that was never drawn.
 */
final class ReturnMessageNeedsAReturnedOrder extends DomainException
{
    public static function make(): self
    {
        return new self('لا يُؤكَّد التواصل مع الزبون إلا والطلبية «راجع لدى المندوب» أو «راجع لدى شركة التوصيل»');
    }
}
