<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A compensation order gives goods away, so it has a grant of its own — `orders.compensation`,
 * separate from the discount's.
 */
final class CompensationRequiresPermission extends DomainException
{
    public static function make(): self
    {
        return new self('لا تملك صلاحية إنشاء طلبية تعويض');
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
