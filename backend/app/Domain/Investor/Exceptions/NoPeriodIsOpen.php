<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/** لا فترةَ مفتوحة تُقفَل. */
final class NoPeriodIsOpen extends DomainException
{
    public static function make(): self
    {
        return new self('لا توجد فترة مفتوحة تُقفَل — تُفتح واحدةٌ أولاً');
    }
}
