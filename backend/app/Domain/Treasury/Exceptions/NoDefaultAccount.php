<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * No account to fall back to. Cannot happen through the API — the default of a kind can be
 * neither switched off nor removed — so meeting this means somebody edited the table by hand.
 */
final class NoDefaultAccount extends DomainException
{
    public static function forKind(string $kind): self
    {
        return new self("لا يوجد حساب افتراضي من نوع «{$kind}» — عيّن حساباً افتراضياً من شاشة الحسابات");
    }

    public static function system(string $code): self
    {
        return new self("حساب النظام «{$code}» غير موجود");
    }
}
