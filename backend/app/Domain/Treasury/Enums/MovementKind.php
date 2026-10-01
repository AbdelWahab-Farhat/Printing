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
        };
    }
}
