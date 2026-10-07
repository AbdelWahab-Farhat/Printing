<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Enums;

/**
 * Why money moved. The direction says which way; this says what for.
 *
 * **A reversal keeps its original's kind** and flips the direction, so every total per kind is
 * already net — «إجمالي الإيداعات» subtracts a reversed deposit without anybody remembering to.
 */
enum MovementKind: string
{
    case Opening = 'opening';
    case Payment = 'payment';
    case Refund = 'refund';
    case Deposit = 'deposit';
    case Withdrawal = 'withdrawal';
    case Expense = 'expense';
    case Transfer = 'transfer';
    case Adjustment = 'adjustment';
    case Settlement = 'settlement';
    case VendorPayment = 'vendor_payment';
    case InvestorDeposit = 'investor_deposit';
    case InvestorWithdrawal = 'investor_withdrawal';
    case SupplyPurchase = 'supply_purchase';

    /** A purchase order's total, owed to its vendor from the moment it is raised — §٢٠. */
    case Purchase = 'purchase';

    /** «خصم من المورد»: the vendor knocked something off what is owed. No money moved. */
    case VendorCredit = 'vendor_credit';

    /**
     * What a customer paid beyond their order, owed back to them — `out` on «مبالغ زائدة
     * للزبائن» when the payment is taken, `in` when a refund hands it back. The cash itself is
     * the payment's own movement into the drawer; this is the debt that came with it.
     */
    case CustomerExcess = 'customer_excess';

    /** «اعتبار الزائد إيراداً»: the excess is the shop's now, and comes off «علينا». No money moved. */
    case ExcessKept = 'excess_kept';

    public function label(): string
    {
        return match ($this) {
            self::Opening => 'رصيد افتتاحي',
            self::Payment => 'دفعة زبون',
            self::Refund => 'ردّ مبلغ لزبون',
            self::Deposit => 'إيداع',
            self::Withdrawal => 'سحب',
            self::Expense => 'مصروف',
            self::Transfer => 'تحويل',
            self::Adjustment => 'جرد الحساب',
            self::Settlement => 'تسوية طلبية',
            self::VendorPayment => 'دفعة لمورد',
            self::InvestorDeposit => 'إيداع مستثمر',
            self::InvestorWithdrawal => 'سحب مستثمر',
            self::SupplyPurchase => 'شراء نواقص',
            self::Purchase => 'أمر شراء',
            self::VendorCredit => 'خصم من المورد',
            self::CustomerExcess => 'زائد لزبون',
            self::ExcessKept => 'زائد اعتُبر إيراداً',
        };
    }
}
