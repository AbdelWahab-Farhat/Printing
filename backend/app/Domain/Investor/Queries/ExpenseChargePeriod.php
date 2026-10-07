<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorWalletEntry;

/**
 * الفترةُ التي حُمِّل فيها المصروف — وهي التي يُسأل عنها «أيُعكس بعد؟».
 *
 * **من صفوف التحميل نفسِها، لا من تاريخ المصروف.** مصروفٌ مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعدها
 * حُمِّل على المفتوحة يومَ سُجِّل ({@see PeriodForEntry})، فتصحيحُه ما دامت تلك مفتوحة لا يمسّ
 * أرقاماً أُعلنت. والسؤالُ بتاريخه كان يمنع تصحيح خطأٍ لم يُعلَن بعد.
 *
 * ومصروفٌ لا صفوفَ له — صندوقٌ بلا شركاء يومَها — فترتُه التي تسع يومَه، إلا أن يكون كُتب
 * بعد إقفالها فالتي كانت مفتوحةً يومَ كُتب.
 */
final class ExpenseChargePeriod
{
    public function of(InvestorDealExpense $expense): ?InvestmentPeriod
    {
        $stamped = InvestorWalletEntry::query()
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->where('source_id', $expense->getKey())
            ->where('type', WalletEntryType::Loss->value)
            ->whereNotNull('investment_period_id')
            ->orderBy('id')
            ->value('investment_period_id');

        if ($stamped !== null) {
            return InvestmentPeriod::query()->find($stamped);
        }

        if ($expense->incurred_on === null) {
            return null;
        }

        $covering = InvestmentPeriod::covering($expense->incurred_on);

        if ($covering !== null
            && $covering->status === PeriodStatus::Closed
            && $covering->closed_at !== null
            && $expense->created_at !== null
            && $expense->created_at->gte($covering->closed_at)) {
            return InvestmentPeriod::covering($expense->created_at);
        }

        return $covering;
    }

    /** أأُقفلت الفترةُ التي حُمِّل فيها — فأرقامُها أُعلنت ولا يُعكس فيها شيء؟ */
    public function isClosed(InvestorDealExpense $expense): bool
    {
        return $this->of($expense)?->status === PeriodStatus::Closed;
    }
}
