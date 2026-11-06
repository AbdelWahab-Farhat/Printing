<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Enums;

/**
 * كيف دخل المال المحفظة أو خرج منها — طرق المكتب الأربع في الاتجاهين (قرار صاحب العمل ٢٠٢٦-١١-٠٥).
 *
 * قيمُ طرق الدفع نفسها، فتنزل في الحسابات نفسها (`AccountKind::forMethod()`). وتعدادٌ خاصٌّ بهذا
 * السياق لأنه لا يستورد سياقاً آخر، كما تفعل `TopUpMethod` في محفظة الزبون.
 */
enum EmployeeWalletMethod: string
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

    /** دليلُ الحوالة الوحيد ورقتُها — في الاتجاهين. */
    public function requiresReceipt(): bool
    {
        return $this === self::BankTransfer;
    }
}
