<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Enums;

/**
 * What a person did by hand on the treasury screen — or, for `settlement`, what «تم التسوية» did.
 *
 * Each maps onto one movement kind; a transfer and a settlement write two movements under the
 * one operation, which is what lets a transfer be found again as a single transfer.
 */
enum OperationType: string
{
    case Opening = 'opening';
    case Deposit = 'deposit';
    case Withdrawal = 'withdrawal';
    case Expense = 'expense';
    case Transfer = 'transfer';
    case Adjustment = 'adjustment';
    case Settlement = 'settlement';

    public function label(): string
    {
        return match ($this) {
            self::Opening => 'رصيد افتتاحي',
            self::Deposit => 'إيداع',
            self::Withdrawal => 'سحب',
            self::Expense => 'مصروف',
            self::Transfer => 'تحويل',
            self::Adjustment => 'جرد الحساب',
            self::Settlement => 'تسوية طلبية',
        };
    }

    public function movementKind(): MovementKind
    {
        return match ($this) {
            self::Opening => MovementKind::Opening,
            self::Deposit => MovementKind::Deposit,
            self::Withdrawal => MovementKind::Withdrawal,
            self::Expense => MovementKind::Expense,
            self::Transfer => MovementKind::Transfer,
            self::Adjustment => MovementKind::Adjustment,
            self::Settlement => MovementKind::Settlement,
        };
    }

    /**
     * The types a person records on the treasury screen. A settlement is written by «تم التسوية».
     *
     * @return list<self>
     */
    public static function recordable(): array
    {
        return [self::Opening, self::Deposit, self::Withdrawal, self::Expense, self::Transfer, self::Adjustment];
    }

    /** Whether the reason is mandatory — money leaving by hand, and a count that disagreed. */
    public function requiresNotes(): bool
    {
        return $this === self::Withdrawal || $this === self::Adjustment;
    }

    /**
     * Whether it can be undone by a reversing operation.
     *
     * An opening cannot: a wrong count is corrected by «جرد الحساب», which says so in the ledger.
     * A settlement is undone by un-settling the order, not from this screen.
     */
    public function isReversibleByHand(): bool
    {
        return $this !== self::Opening && $this !== self::Settlement;
    }
}
