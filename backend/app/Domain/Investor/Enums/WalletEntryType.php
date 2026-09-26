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

    /**
     * A losing deal's shortfall taken out of the capital the investor put **into that deal**.
     *
     * Every amount in this table is positive, so there is no negative release to hand back with.
     * A deal whose share of the losses came to −6,500 against 30,000 of capital returns 23,500,
     * and this row is the 6,500 — visible, named, and touching no other deal's money.
     */
    case CapitalWritedown = 'capital_writedown';

    /**
     * The part of a loss that exceeded what the investor had in the deal.
     *
     * Nothing in the arrangement makes him owe more than he put in, so the remainder is the
     * company's. Written as its own line so it appears on his statement instead of quietly
     * disappearing into a rounding difference.
     */
    case LossAbsorbedByCompany = 'loss_absorbed_by_company';

    /**
     * خسارةٌ بقيت على فترةٍ تُقفَل، تخرج منها إلى التي بعدها — §٠.٨.
     *
     * **الحالُ:** أُفرِج عن ربح سبتمبر وخرج من الجيوب، ثم تُسلَّم آخرُ طلبياته بخسارة. فلا
     * رأسُ المال يُمسّ ولا الشركةُ تتحمّل — «مطالبة على المستثمر نفسه، تُرحّل حتى تُخصم من
     * أرباحه المستقبلية».
     *
     * وهو يسدّ حفرةَ الفترة المنتهية فتُقفَل على صفر، وأخوه يفتحها في التالية.
     */
    case LossCarriedOut = 'loss_carried_out';

    /** نظيرُه في الفترة التي تستقبله: تُستنزل من أوّل ربحٍ يُفرَج عنه فيها. */
    case LossCarriedIn = 'loss_carried_in';

    /** The deal's net profit moving to the wallet at close — where it becomes withdrawable. */
    case ProfitRelease = 'profit_release';

    /** Profit paid out to the investor. */
    case ProfitWithdrawal = 'profit_withdrawal';

    /**
     * ربحٌ يصير رأسَ مالٍ في محفظته — «يمكنه تحويل رصيد الأرباح إلى رأس المال ليقوم بإستعماله».
     *
     * **صفٌّ واحد يحرّك جيبين**، لا سحبٌ ثم إيداع. الثاني يكتب في الخزينة صرفاً وقبضاً لم يقعا،
     * ويقول إن مالاً عبر الطاولة ولم يعبرها شيء: المالُ عندنا منذ البداية، والذي تغيّر أنه صار
     * يعمل بدل أن ينتظر السحب.
     *
     * ولا طريقةَ دفعٍ له لذلك — انظر ذراعه في قيد `_shape`.
     */
    case ProfitCapitalisation = 'profit_capitalisation';

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
            self::CapitalWritedown => 'خصم خسارة من رأس المال',
            self::LossAbsorbedByCompany => 'خسارة تحمّلتها الشركة',
            self::ProfitRelease => 'إتاحة أرباح الصفقة للسحب',
            self::LossCarriedOut => 'ترحيل خسارة إلى الفترة التالية',
            self::LossCarriedIn => 'خسارة مرحَّلة من فترة سابقة',
            self::ProfitWithdrawal => 'سحب أرباح',
            self::ProfitCapitalisation => 'تحويل أرباح إلى رأس مال',
            self::Reversal => 'عكس حركة',
        };
    }

    /**
     * The same row, named for the fund rather than for a deal.
     *
     * The labels above were written when every allocation went into a lorry's deal. Into the
     * fund the same row is a subscription, and «تمويل صفقة» on an investor's statement names
     * something he never did. Only the three types whose wording is about a deal change; a
     * writedown or a carried loss reads the same either way.
     */
    public function fundLabel(): string
    {
        return match ($this) {
            self::Allocation => 'اشتراك في الصندوق',
            self::Release => 'استرداد من الصندوق',
            self::ProfitRelease => 'إتاحة أرباح الفترة للسحب',
            default => $this->label(),
        };
    }

    /**
     * Which statement filter this row answers to.
     *
     * A reversal returns null: it is filed under the row it undoes, which only the row knows.
     */
    public function category(): ?WalletEntryCategory
    {
        return match ($this) {
            self::Deposit, self::Withdrawal => WalletEntryCategory::Capital,
            self::Allocation, self::Release => WalletEntryCategory::Investment,
            self::Profit, self::ProfitRelease, self::ProfitWithdrawal,
            self::ProfitCapitalisation => WalletEntryCategory::Profit,
            self::Loss, self::CapitalWritedown, self::LossAbsorbedByCompany,
            self::LossCarriedOut, self::LossCarriedIn => WalletEntryCategory::Loss,
            self::Reversal => null,
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

    /**
     * How this row moves each of the four buckets, as multipliers on its amount.
     *
     * **One table, read by every balance, every ceiling and every statement row.** Three of the
     * types move two buckets at once — a writedown takes from capital in the deal and gives to
     * profit in it — which is exactly why a single `pot` column on the row would have been a
     * lie: it would have to name one of the two, and the row would then vanish from the
     * statement of whichever it did not name.
     *
     * @return array{capital_wallet: int, capital_deal: int, profit_deal: int, profit_wallet: int}
     */
    public function deltas(): array
    {
        return match ($this) {
            self::Deposit => ['capital_wallet' => 1, 'capital_deal' => 0, 'profit_deal' => 0, 'profit_wallet' => 0],
            self::Withdrawal => ['capital_wallet' => -1, 'capital_deal' => 0, 'profit_deal' => 0, 'profit_wallet' => 0],
            self::Allocation => ['capital_wallet' => -1, 'capital_deal' => 1, 'profit_deal' => 0, 'profit_wallet' => 0],
            self::Release => ['capital_wallet' => 1, 'capital_deal' => -1, 'profit_deal' => 0, 'profit_wallet' => 0],
            self::Profit => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => 1, 'profit_wallet' => 0],
            self::Loss => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => -1, 'profit_wallet' => 0],
            self::CapitalWritedown => ['capital_wallet' => 0, 'capital_deal' => -1, 'profit_deal' => 1, 'profit_wallet' => 0],
            self::LossAbsorbedByCompany => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => 1, 'profit_wallet' => 0],
            self::ProfitRelease => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => -1, 'profit_wallet' => 1],
            // الزوجُ يتعادل في الدفتر كلِّه ويفترق في الفترتين: يسدّ هنا ويفتح هناك.
            self::LossCarriedOut => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => 1, 'profit_wallet' => 0],
            self::LossCarriedIn => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => -1, 'profit_wallet' => 0],
            self::ProfitWithdrawal => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => 0, 'profit_wallet' => -1],
            // الجيبان معاً: يخرج من الأرباح ويدخل رأسَ المال، فيصير قابلاً للاشتراك في الصندوق.
            self::ProfitCapitalisation => ['capital_wallet' => 1, 'capital_deal' => 0, 'profit_deal' => 0, 'profit_wallet' => -1],
            // A reversal has no deltas of its own — it takes the negation of the row it undoes.
            self::Reversal => ['capital_wallet' => 0, 'capital_deal' => 0, 'profit_deal' => 0, 'profit_wallet' => 0],
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
            self::Allocation, self::Release, self::Profit, self::Loss,
            self::CapitalWritedown, self::LossAbsorbedByCompany, self::ProfitRelease,
            self::LossCarriedOut, self::LossCarriedIn => true,
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
            self::Deposit, self::Withdrawal, self::Allocation,
            self::ProfitWithdrawal, self::ProfitCapitalisation => true,
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
