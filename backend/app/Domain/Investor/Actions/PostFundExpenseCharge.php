<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\FundExpenseCharge;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\ProfitShareForEntry;
use App\Domain\Investor\Support\Money;

/**
 * يكتب جزءاً من مصروفٍ على البضاعة على من يحمله — أو يردّه إليه.
 *
 * المواصفة: Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٤–٤.٦.
 *
 * **الطريقُ نفسُه الذي يسلكه كل مصروف صندوق**، مصدرُه الصفُّ لا المصروف: نصيبُ الشركاء
 * بـ{@see InvestorDeal::investorsCutOf()} بنسبة **فترة الصفّ**، ثم {@see PostDealShare} يقسمه
 * بوحداتها ويختم به صفوفَه؛ والباقي على الشركة نقداً — كما يفعل
 * {@see RecordFundExpense::coverTheCompanysShare()}.
 *
 * **والإشارةُ تقرّر الاتجاه.** موجبٌ يُكتب خسارةً على الشركاء، وتُدخل الشركةُ نصيبَها نقدَ الصندوق
 * (`ExpenseCoveredByCompany`). سالبٌ — ردٌّ لما حمله الفرقُ في تكلفة بضاعةٍ بِيعت ثم عُكس المصروف —
 * يُكتب ربحاً لهم، وتأخذ الشركةُ نصيبَها منه (`CompanyPayout`): كان سيصلها في ربح الطلبية لولا
 * أنّ تكلفتها حملت المصروف.
 *
 * يُنادى والصندوقُ مقفول — شرطُ {@see PostDealShare}.
 */
final class PostFundExpenseCharge
{
    public function __construct(
        private readonly PostDealShare $postShare,
        private readonly ProfitShareForEntry $profitShare,
        private readonly PeriodForEntry $periodFor,
        private readonly RecordCashEntry $cash,
    ) {}

    /** يكتب ما على الصفّ — وقد خُتم بفترته يومَ كُتب ({@see PeriodForEntry::forCharge()}). */
    public function post(InvestorDeal $fund, FundExpenseCharge $charge, ?int $actorId): void
    {
        $amount = (string) $charge->amount;
        $isCredit = bccomp($amount, '0', 2) < 0;
        $magnitude = $isCredit ? substr($amount, 1) : $amount;

        if (bccomp($magnitude, '0', 2) === 0) {
            return;
        }

        $investorsCut = $fund->investorsCutOf(
            $magnitude,
            $this->profitShare->bySource($fund, AuditSubject::FundExpenseCharge->value, (int) $charge->getKey()),
        );

        if (bccomp($investorsCut, '0', 2) > 0) {
            ($this->postShare)(
                $fund,
                $isCredit ? $investorsCut : '-'.$investorsCut,
                AuditSubject::FundExpenseCharge->value,
                (int) $charge->getKey(),
                'تصحيح حصة مصروف على البضاعة',
            );
        }

        // **ما كُتب فعلاً لا حسابٌ ثانٍ للنسبة** — بقرشه، فلا يفترق النقدُ عن الدفتر بفرق تقريب.
        $companys = Money::round(bcsub($magnitude, $this->writtenOn($charge, $isCredit), 8));

        if (bccomp($companys, '0', 2) <= 0) {
            return;
        }

        ($this->cash)(
            type: $isCredit ? CashEntryType::CompanyPayout : CashEntryType::ExpenseCoveredByCompany,
            amount: $companys,
            sourceType: AuditSubject::FundExpenseCharge->value,
            sourceId: (int) $charge->getKey(),
            actorId: $actorId,
        );
    }

    /**
     * يردّ الصفَّ: صفوفُ المحافظ تُعكس، ونقدُ الشركة يعود، ويُكتب صفٌّ معاكسٌ يشير إليه.
     *
     * الردُّ يقع حيث وقع أصلُه ما دامت فترتُه تقبل القيد، وإلا فعلى المفتوحة —
     * {@see PeriodForEntry::floorOf()}، القاعدةُ نفسُها التي يعكس بها {@see PostDealShare}.
     */
    public function reverse(InvestorDeal $fund, FundExpenseCharge $charge, string $reason, ?int $actorId): FundExpenseCharge
    {
        ($this->postShare)(
            $fund,
            '0.00',
            AuditSubject::FundExpenseCharge->value,
            (int) $charge->getKey(),
            $reason,
        );

        $standing = InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->where('source_id', $charge->getKey())
            ->whereDoesntHave('reversedBy')
            ->get();

        foreach ($standing as $entry) {
            $this->cash->reverse($entry, $actorId, $reason);
        }

        $reversal = new FundExpenseCharge;
        $reversal->investor_deal_expense_id = $charge->investor_deal_expense_id;
        $reversal->kind = $charge->kind;
        $reversal->stock_batch_id = $charge->stock_batch_id;
        $reversal->stock_movement_id = $charge->stock_movement_id;
        $reversal->order_id = $charge->order_id;
        $reversal->quantity = (string) $charge->quantity;
        $reversal->unit_amount = $charge->unit_amount === null ? null : (string) $charge->unit_amount;
        $reversal->amount = bcmul((string) $charge->amount, '-1', 2);
        $reversal->charged_on = now()->toDateString();
        $reversal->investment_period_id = $this->periodFor->floorOf(
            $charge->investment_period_id === null ? null : (int) $charge->investment_period_id,
        );
        $reversal->reverses_charge_id = $charge->getKey();
        $reversal->save();

        return $reversal;
    }

    /** ما كُتب على المحافظ من هذا الصفّ ولم يُعكس — خسارةً أو ربحاً بحسب إشارته. */
    private function writtenOn(FundExpenseCharge $charge, bool $isCredit): string
    {
        return (string) InvestorWalletEntry::query()
            ->where('source_type', AuditSubject::FundExpenseCharge->value)
            ->where('source_id', $charge->getKey())
            ->where('type', ($isCredit ? WalletEntryType::Profit : WalletEntryType::Loss)->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');
    }
}
