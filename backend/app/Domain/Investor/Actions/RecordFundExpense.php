<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Support\FundDeal;
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
                occurredAt: $expense->incurred_on,
            );

            return $expense;
        });
    }
}
