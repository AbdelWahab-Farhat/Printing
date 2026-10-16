<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * More asked of a wallet than it holds. A wallet never goes below zero — no path writes debt into
 * it — so this is the refusal every debit meets, read under the lock on the customer.
 */
final class WalletBalanceTooLow extends DomainException
{
    private string $field = 'amount';

    public static function make(string $amount, string $balance, string $field = 'amount'): self
    {
        $exception = new self("رصيد المحفظة ({$balance}) أقل من المبلغ المطلوب ({$amount})");
        $exception->field = $field;

        return $exception;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
