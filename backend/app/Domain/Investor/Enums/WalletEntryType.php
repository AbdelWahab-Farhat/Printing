<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

use App\Domain\Investor\Models\InvestorWalletEntry;

/**
 * Every way money moves for an investor — and the direction, which never lives in a sign.
 *
 * The amount on a row is always positive, exactly as in `order_payments`; this enum says what
 * the row *means*, and {@see InvestorWalletEntry::signedAmount()} is the one place a sign is
 * applied. Two pots (capital, profit) and two places (the wallet, a deal) give the whole model:
 *
 * ```
 * capital in wallet = deposit − withdrawal − allocation + release
 * capital in deal D = allocation(D) − release(D)
 * profit in deal D  = profit(D) − loss(D) − profitRelease(D)
 * profit in wallet  = profitRelease − profitWithdrawal
 * ```
 *
 * **Money can only leave from the wallet, and profit only reaches the wallet when a deal
 * closes.** That is not a rule written in an action — it is the only path the types allow, and
 * it is what makes «الربح يأتي تدريجياً ولا يُسحب إلا عند انتهاء الصفقة» impossible to get
 * wrong.
 */
enum WalletEntryType: string
{
    /** The investor handed money to the company. */
    case Deposit = 'deposit';

    /** He took capital back out of the wallet. */
    case Withdrawal = 'withdrawal';

    /** Wallet capital committed to a deal. */
    case Allocation = 'allocation';

    /** That capital coming back to the wallet when the deal closes. */
    case Release = 'release';

    /** A share of one order's profit, earned by a deal. */
    case Profit = 'profit';

    /** A share of one order's loss, borne by a deal. */
    case Loss = 'loss';

    /** The deal's net profit moving to the wallet at close — where it becomes withdrawable. */
    case ProfitRelease = 'profit_release';

    /** Profit paid out to the investor. */
    case ProfitWithdrawal = 'profit_withdrawal';

    /** Undoes one earlier row, carrying its amount verbatim. */
    case Reversal = 'reversal';

    public function label(): string
    {
        return match ($this) {
            self::Deposit => 'إيداع رأس مال',
            self::Withdrawal => 'سحب رأس مال',
            self::Allocation => 'تمويل صفقة',
            self::Release => 'إرجاع رأس المال من الصفقة',
            self::Profit => 'ربح من طلبية',
            self::Loss => 'خسارة من طلبية',
            self::ProfitRelease => 'إتاحة أرباح الصفقة للسحب',
            self::ProfitWithdrawal => 'سحب أرباح',
            self::Reversal => 'عكس حركة',
        };
    }

    /** Whether the row adds to whichever total it belongs to. */
    public function isCredit(): bool
    {
        return match ($this) {
            self::Deposit, self::Release, self::Profit, self::ProfitRelease => true,
            default => false,
        };
    }

    /** Whether real money crossed the counter — the rows that must name a method. */
    public function movedCash(): bool
    {
        return $this === self::Deposit
            || $this === self::Withdrawal
            || $this === self::ProfitWithdrawal;
    }

    /** Whether this row belongs to a deal rather than to the wallet. */
    public function belongsToADeal(): bool
    {
        return match ($this) {
            self::Allocation, self::Release, self::Profit, self::Loss, self::ProfitRelease => true,
            default => false,
        };
    }

    /**
     * Whether a person may record this by hand.
     *
     * `profit` and `loss` are written by the order flow, and `release`/`profit_release` by
     * closing a deal. Offering them on a form would be offering somebody the chance to invent
     * an earning.
     */
    public function isRecordableByHand(): bool
    {
        return match ($this) {
            self::Deposit, self::Withdrawal, self::Allocation, self::ProfitWithdrawal => true,
            default => false,
        };
    }

    /**
     * @return array<int, string>
     */
    public static function recordableValues(): array
    {
        return array_values(array_map(
            fn (self $type) => $type->value,
            array_filter(self::cases(), fn (self $type) => $type->isRecordableByHand()),
        ));
    }
}
