<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Domain\PurchaseOrder\Actions\ReverseCostRefund;
use App\Support\Exceptions\DomainException;

/**
 * @see ReverseCostRefund
 */
final class CostRefundAlreadyReversed extends DomainException
{
    public static function make(): self
    {
        return new self('تم التراجع عن هذا الاسترداد من قبل');
    }
}
