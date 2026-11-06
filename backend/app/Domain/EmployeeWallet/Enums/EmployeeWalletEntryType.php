<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Enums;

/**
 * ما يعنيه سطرٌ واحد من محفظة موظف. المبلغ موجبٌ دائماً، وهذا يقول أيّ اتجاه.
 * Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٣.
 *
 * **«إيداع» و«مستحق» شيئان في الدفاتر وإن كانا زرّاً واحداً على الشاشة**: الأول مالٌ دخل حساباً،
 * والثاني مصروفٌ على الشركة بلا كاش.
 */
enum EmployeeWalletEntryType: string
{
    /** «إيداع» — مالٌ سلّمه الموظف فعلاً ودخل حساباً. */
    case Deposit = 'deposit';

    /** «مستحق» — صارت الشركة مدينةً له: راتبٌ أو مكافأة. مصروفٌ ولا كاش يتحرك. */
    case Credit = 'credit';

    /** «سحب» — مالٌ قبضه الموظف وخرج من حساب. */
    case Withdrawal = 'withdrawal';

    /** «تعديل بالزيادة» — تصحيحٌ باليد بسبب، أو رصيدٌ افتتاحي. */
    case AdjustmentCredit = 'adjustment_credit';

    /** «تعديل بالنقص» — تصحيحٌ باليد بسبب. */
    case AdjustmentDebit = 'adjustment_debit';

    /** «عكس» — سطرٌ ما كان ينبغي أن يُكتب، أُلغي. يتحرك عكس أصله. */
    case Reversal = 'reversal';

    /** ما يقبله فلتر السجل زيادةً على الأنواع: «تعديل» رقاقةٌ واحدة لنوعين. */
    public const ADJUSTMENT_FILTER = 'adjustment';

    public function label(): string
    {
        return match ($this) {
            self::Deposit => 'إيداع',
            self::Credit => 'مستحق',
            self::Withdrawal => 'سحب',
            self::AdjustmentCredit => 'تعديل بالزيادة',
            self::AdjustmentDebit => 'تعديل بالنقص',
            self::Reversal => 'عكس حركة',
        };
    }

    /**
     * أيزيد السطرُ الرصيد. العكسُ لا اتجاه له من نفسه — هو ضدّ ما يعكسه؛ انظر
     * `EmployeeWalletEntry::isCredit()`.
     */
    public function isCredit(): bool
    {
        return match ($this) {
            self::Deposit, self::Credit, self::AdjustmentCredit => true,
            self::Withdrawal, self::AdjustmentDebit, self::Reversal => false,
        };
    }

    /** كلُّ سطرٍ يُعكس من شاشة المحفظة إلا العكس نفسه. */
    public function isReversibleByHand(): bool
    {
        return $this !== self::Reversal;
    }

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }

    /**
     * ما يقبله `?type=` — الأنواع، و«تعديل» للاثنين معاً.
     *
     * @return list<string>
     */
    public static function filterValues(): array
    {
        return [...self::values(), self::ADJUSTMENT_FILTER];
    }
}
