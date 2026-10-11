<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Exceptions;

use App\Support\Exceptions\DomainException;

final class WalletEntryCannotBeReversed extends DomainException
{
    public static function notByHand(string $label): self
    {
        return new self("«{$label}» تُعكس من دفعات الطلبية، لا من المحفظة");
    }

    public static function alreadyReversed(): self
    {
        return new self('هذه الحركة معكوسة من قبل');
    }

    /** Undoing a top-up whose money was already spent would leave the wallet below zero. */
    public static function alreadySpent(string $amount, string $balance): self
    {
        return new self("لا يمكن عكس {$amount}: رصيد المحفظة الآن {$balance} — صُرف جزءٌ من هذا المبلغ");
    }
}
