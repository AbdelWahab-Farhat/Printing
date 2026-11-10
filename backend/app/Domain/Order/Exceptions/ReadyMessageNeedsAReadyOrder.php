<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\MarkReadyMessageSent;
use App\Domain\Order\Models\Order;
use App\Support\Exceptions\DomainException;

/**
 * Somebody confirmed «رسالة الجاهزية» on an order that has not been dispatched yet.
 *
 * The message goes out when the order enters «استلام مكتب» or «جاري التوصيل», so there is
 * nothing to send before that — see {@see Order::readyMessageApplies()} for why that is read
 * from `dispatched_at` rather than from the status, and {@see MarkReadyMessageSent} for the
 * write this refuses.
 *
 * The app is told the same thing by `ready_message_applies`, so this is the guard behind a box
 * that was never drawn rather than a refusal anybody should meet.
 */
final class ReadyMessageNeedsAReadyOrder extends DomainException
{
    public static function make(): self
    {
        return new self('لا تُؤكَّد رسالة الجاهزية قبل أن تبلغ الطلبية «استلام مكتب» أو «جاري التوصيل»');
    }
}
