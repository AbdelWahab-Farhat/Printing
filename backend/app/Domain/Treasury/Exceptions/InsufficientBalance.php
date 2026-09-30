<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Money asked to leave an account that does not hold it.
 *
 * Only ever thrown at a person's hand — a withdrawal, an expense, a transfer, a vendor payment.
 * Automatic movements (a reversal, a refund) are never refused for it: TREASURY-DESIGN §١٢.
 */
final class InsufficientBalance extends DomainException
{
    public function __construct(string $message, private readonly string $field)
    {
        parent::__construct($message);
    }

    public static function make(string $account, string $balance, string $amount, string $field = 'amount'): self
    {
        return new self("رصيد «{$account}» ({$balance}) لا يكفي لـ {$amount}", $field);
    }

    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
