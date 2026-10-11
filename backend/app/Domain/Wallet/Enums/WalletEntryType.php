<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Enums;

/**
 * What one row of a customer's wallet means. The amount is always positive; this says which way.
 *
 * **There is no withdrawal.** Money comes in by a top-up, a refund handed back into the wallet, or
 * a hand correction, and leaves only to pay an order — the owner's decision of 2026-10-11.
 * Docs/payments/CUSTOMER-WALLET.md §٤.
 */
enum WalletEntryType: string
{
    /** «شحن» — money arrived: at the counter today, through EzonePay later. */
    case Topup = 'topup';

    /** «دفع طلبية» — paid an order out of the wallet. */
    case OrderPayment = 'order_payment';

    /** «ردّ إلى المحفظة» — money handed back on an order, into the wallet. */
    case OrderRefund = 'order_refund';

    /** «تعديل بالزيادة» — a balance corrected upward by hand, with a reason. */
    case AdjustmentCredit = 'adjustment_credit';

    /** «تعديل بالنقص» — a balance corrected downward by hand, with a reason. */
    case AdjustmentDebit = 'adjustment_debit';

    /** «عكس» — a row that should never have been written, undone. Moves the opposite way. */
    case Reversal = 'reversal';

    public function label(): string
    {
        return match ($this) {
            self::Topup => 'شحن المحفظة',
            self::OrderPayment => 'دفع طلبية',
            self::OrderRefund => 'ردّ إلى المحفظة',
            self::AdjustmentCredit => 'تعديل بالزيادة',
            self::AdjustmentDebit => 'تعديل بالنقص',
            self::Reversal => 'عكس حركة',
        };
    }

    /**
     * Whether the row adds to the balance. A reversal has no direction of its own — it is the
     * opposite of the row it undoes; see `CustomerWalletEntry::isCredit()`.
     */
    public function isCredit(): bool
    {
        return match ($this) {
            self::Topup, self::OrderRefund, self::AdjustmentCredit => true,
            self::OrderPayment, self::AdjustmentDebit, self::Reversal => false,
        };
    }

    /**
     * Whether a person may undo this row from the wallet screen. A payment from the wallet and a
     * refund into it belong to the order's ledger and are undone there; a reversal is never
     * reversed.
     */
    public function isReversibleByHand(): bool
    {
        return match ($this) {
            self::Topup, self::AdjustmentCredit, self::AdjustmentDebit => true,
            self::OrderPayment, self::OrderRefund, self::Reversal => false,
        };
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
