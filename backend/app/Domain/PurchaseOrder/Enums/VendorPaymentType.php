<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Enums;

enum VendorPaymentType: string
{
    case Payment = 'payment';
    case Reversal = 'reversal';
    case OpeningDebt = 'opening_debt';

    public function label(): string
    {
        return match ($this) {
            self::Payment => 'دفعة',
            self::Reversal => 'إلغاء قيد',
            self::OpeningDebt => 'دَين افتتاحي',
        };
    }

    /** What this row does to the amount still owed: a payment lowers it, a debt raises it. */
    public function owedSign(): int
    {
        return match ($this) {
            self::Payment => -1,
            self::OpeningDebt => 1,
            // A reversal undoes whichever row it names; the summary reads that row's sign.
            self::Reversal => 0,
        };
    }
}
