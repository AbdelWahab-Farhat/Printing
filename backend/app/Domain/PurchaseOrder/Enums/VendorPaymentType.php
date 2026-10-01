<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Enums;

enum VendorPaymentType: string
{
    case Payment = 'payment';
    case Reversal = 'reversal';
    case OpeningDebt = 'opening_debt';

    /** «خصم من المورد» — the vendor knocked something off what is owed: a short delivery, a discount. */
    case Credit = 'credit';

    public function label(): string
    {
        return match ($this) {
            self::Payment => 'دفعة',
            self::Reversal => 'إلغاء قيد',
            self::OpeningDebt => 'دَين افتتاحي',
            self::Credit => 'خصم من المورد',
        };
    }

    /** Whether money left a drawer — a payment alone. A debt and a credit only change what is owed. */
    public function movesMoney(): bool
    {
        return $this === self::Payment;
    }

    /** What this row does to the amount still owed: a payment or a credit lowers it, a debt raises it. */
    public function owedSign(): int
    {
        return match ($this) {
            self::Payment, self::Credit => -1,
            self::OpeningDebt => 1,
            // A reversal undoes whichever row it names; the summary reads that row's sign.
            self::Reversal => 0,
        };
    }
}
