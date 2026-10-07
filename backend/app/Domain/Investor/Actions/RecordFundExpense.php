<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use DateTimeInterface;
use Illuminate\Support\Facades\DB;

/**
 * مصروفٌ على الصندوق — شحنٌ أو جماركُ أو أجرةُ مخزن، بلا صفقةٍ يسمّيها.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٥.
 *
 * **ولا جدولَ جديداً له.** `investor_deal_expenses` يسمّي صفقةً، والصندوقُ صفقةٌ —
 * {@see FundDeal} — فالمصروفُ يُكتب عليه كما يُكتب على غيره، ويمرّ بـ{@see RecordDealExpense}
 * نفسِه: يُحمَّل على المستثمرين بنسب فترته، ويُختم بها، ويصحَّح بعكسٍ إن تغيّر. جدولٌ ثانٍ كان
 * سيعني تعريفين لـ«ما الذي يأكل من ربح الشهر».
 *
 * **والزائدُ عليه هنا صفٌّ في الخزينة**: المصروفُ مالٌ خرج فعلاً، فلو لم يُسجَّل لبقي في سقف
 * الشراء مالٌ أُنفق — ويُشترى به مرّةً ثانية.
 *
 * **وصفٌّ ثانٍ يُدخل نصيبَ الشركة منه** — {@see coverTheCompanysShare()}. بدونه كان النقدُ ينقص
 * بالمصروف كلِّه والمحافظُ بنصيب الشركاء وحده، فيقع نصيبُ الشركة على الشركاء من طريق سعر الوحدة.
 */
final class RecordFundExpense
{
    public function __construct(
        private readonly FundDeal $fund,
        private readonly RecordDealExpense $record,
        private readonly RecordCashEntry $cash,
    ) {}

    public function __invoke(DealExpenseData $data, ?int $actorId): InvestorDealExpense
    {
        return DB::transaction(function () use ($data, $actorId): InvestorDealExpense {
            $expense = ($this->record)(($this->fund)(), $data, $actorId);

            ($this->cash)(
                type: CashEntryType::Expense,
                amount: (string) $expense->amount,
                sourceType: AuditSubject::InvestorDealExpense->value,
                sourceId: (int) $expense->getKey(),
                actorId: $actorId,
                occurredAt: InvestorDealExpense::momentFor($expense->incurred_on, $expense->created_at),
            );

            $this->coverTheCompanysShare($expense, $actorId);

            return $expense;
        });
    }

    /**
     * نصيبُ الشركة من المصروف يدخل نقدَ الصندوق من مالها — §١٠، الخيار ب.
     *
     * **الباقي بعد ما كُتب على الشركاء فعلاً، لا حسابٌ ثانٍ للنسبة.** صفوفُ `loss` التي كتبها
     * {@see RecordDealExpense} قبل سطرين هي ما نقص من محافظهم، فما عداها على الشركة — بقرشه، فلا
     * يفترق النقدُ عن الدفتر بفرق تقريب. وصندوقٌ بلا شركاء في فترة المصروف تحمّلته الشركةُ كلَّه.
     *
     * **التسلسل ٢ على المصدر نفسِه**: صفُّ المصروف الأوّل، وهذا ثانيه — فعكسُ المصروف يُبطلهما
     * معاً ({@see ReverseDealExpense::returnTheFundCash()})، ونداءٌ مكرّر لا يكتبه مرّتين.
     */
    public function coverTheCompanysShare(
        InvestorDealExpense $expense,
        ?int $actorId,
        ?DateTimeInterface $on = null,
    ): void {
        $companys = $this->companysShareOf($expense);

        if (bccomp($companys, '0', 2) <= 0) {
            return;
        }

        ($this->cash)(
            type: CashEntryType::ExpenseCoveredByCompany,
            amount: $companys,
            sourceType: AuditSubject::InvestorDealExpense->value,
            sourceId: (int) $expense->getKey(),
            actorId: $actorId,
            occurredAt: $on ?? InvestorDealExpense::momentFor($expense->incurred_on, $expense->created_at),
            sourceSequence: 2,
        );
    }

    /** ما على الشركة من المصروف: مبلغُه ناقصاً ما كُتب على الشركاء منه ولم يُعكس. */
    public function companysShareOf(InvestorDealExpense $expense): string
    {
        $charged = InvestorWalletEntry::query()
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->where('source_id', $expense->getKey())
            ->where('type', WalletEntryType::Loss->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        return Money::round(bcsub((string) $expense->amount, (string) $charged, 8));
    }
}
