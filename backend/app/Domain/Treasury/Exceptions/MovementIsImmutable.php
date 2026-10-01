<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

final class MovementIsImmutable extends DomainException
{
    public static function make(): self
    {
        return new self('حركات الحسابات لا تُعدَّل — التصحيح يكون بعكس الحركة');
    }

    public static function cannotBeDeleted(): self
    {
        return new self('حركات الحسابات لا تُحذف — التصحيح يكون بعكس الحركة');
    }
}
