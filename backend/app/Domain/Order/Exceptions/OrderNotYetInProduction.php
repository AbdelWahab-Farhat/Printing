<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\DeductOrderStock;
use App\Domain\Order\Actions\RecordScrapLoss;
use App\Support\Exceptions\DomainException;

/**
 * Scrap was reported for an order that has never entered printing.
 *
 * There is nothing to spoil before the press has run: `orders.fulfillment_warehouse_id` is only
 * ever set the same moment {@see DeductOrderStock} runs, and that is
 * also the warehouse a scrap loss draws from — see {@see RecordScrapLoss}.
 */
final class OrderNotYetInProduction extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكن تسجيل تلف لطلبية لم تدخل مرحلة الطباعة بعد');
    }
}
