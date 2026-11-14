<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\MarkVendorMessageSent;
use App\Domain\Order\Models\Order;
use App\Support\Exceptions\DomainException;

/**
 * Somebody confirmed «رسالة المورد» on an order that is not an outsourced one still on its way
 * to the vendor.
 *
 * See {@see Order::vendorMessageApplies()} for which orders count and
 * {@see MarkVendorMessageSent} for the write this refuses. The app is told the same thing by
 * `vendor_message_applies`, so this guards a switch that was never drawn.
 */
final class VendorMessageNeedsAnOutsourcedOrder extends DomainException
{
    public static function make(): self
    {
        return new self('لا يُؤكَّد إرسال رسالة المورد إلا لطلبية تصنيع «جديدة» أو «قيد التصميم» أو «قيد التصنيع»');
    }
}
