<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Exceptions;

use App\Support\Exceptions\DomainException;

final class EmployeeWalletEntryCannotBeReversed extends DomainException
{
    public static function isAReversal(): self
    {
        return new self('هذه الحركة عكسٌ لغيرها — تُعكس الحركة الأصلية لا عكسها');
    }

    public static function alreadyReversed(): self
    {
        return new self('هذه الحركة معكوسة من قبل');
    }

    /** عكسُ مالٍ خرج يترك المحفظة تحت الصفر، فيُعكس السحبُ أولاً. */
    public static function alreadySpent(string $amount, string $balance): self
    {
        return new self("لا يمكن عكس {$amount}: رصيد المحفظة الآن {$balance} — سُحب جزءٌ من هذا المبلغ");
    }
}
