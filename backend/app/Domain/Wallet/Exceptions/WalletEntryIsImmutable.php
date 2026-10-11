<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Exceptions;

use App\Support\Exceptions\DomainException;

final class WalletEntryIsImmutable extends DomainException
{
    public static function make(): self
    {
        return new self('حركات المحفظة لا تُعدَّل — التصحيح يكون بعكس الحركة');
    }

    public static function cannotBeDeleted(): self
    {
        return new self('حركات المحفظة لا تُحذف — التصحيح يكون بعكس الحركة');
    }
}
