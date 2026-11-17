<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * «أجرة التصميم» belongs to whoever holds `orders.design_fee`. ORDER-DESIGN-FEE.md.
 */
final class DesignFeeRequiresPermission extends DomainException
{
    public static function make(): self
    {
        return new self('لا تملك صلاحية تحديد أجرة التصميم');
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
