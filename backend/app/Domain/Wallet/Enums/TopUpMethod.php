<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Enums;

/**
 * How money reached a wallet.
 *
 * The four a counter takes — the same values as the order payment methods, so the treasury files
 * them in the same accounts (`AccountKind::forMethod()`). Its own enum rather than the Order one:
 * the wallet never reaches into the order context, and EzonePay adds a fifth here that an order
 * payment never carries.
 */
enum TopUpMethod: string
{
    case Cash = 'cash';
    case BankTransfer = 'bank_transfer';
    case BankCard = 'bank_card';
    case Libyana = 'libyana';

    public function label(): string
    {
        return match ($this) {
            self::Cash => 'كاش',
            self::BankTransfer => 'حوالة',
            self::BankCard => 'بطاقة مصرفية',
            self::Libyana => 'ليبيانا',
        };
    }

    /** A transfer's only proof is the paper the customer sends — the order payments' rule. */
    public function requiresReceipt(): bool
    {
        return $this === self::BankTransfer;
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $method) => $method->value, self::cases());
    }
}
