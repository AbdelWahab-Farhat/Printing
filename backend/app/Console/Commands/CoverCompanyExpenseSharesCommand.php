<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Actions\RecordFundExpense;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * نصيبُ الشركة من مصاريف الصندوق المسجَّلة قبل 2026-10-05 — CONTINUOUS-FUND-DESIGN §١٠، الخيار ب.
 *
 * كلُّ مصروفٍ على الصندوق لم يُعكس وليس له صفُّ {@see CashEntryType::ExpenseCoveredByCompany}
 * يُكتب له، **بتاريخ اليوم**: الشركةُ تدفعه يومَ الإصلاح، والفتراتُ المغلقة على أرقامها المعلنة.
 * تجربةٌ ما لم يُمرَّر `--apply`، وإعادتُه لا تكتب شيئاً مرّتين.
 */
class CoverCompanyExpenseSharesCommand extends Command
{
    protected $signature = 'investment:cover-company-expense-shares
                            {--apply : يكتب فعلاً؛ بدونه يعرض ما سيُكتب ولا يكتب شيئاً}';

    protected $description = 'يُدخل نقدَ الصندوق نصيبَ الشركة من كل مصروفٍ على الصندوق سُجِّل قبل أن تتحمّله الشركة';

    public function handle(FundDeal $fund, RecordFundExpense $record): int
    {
        $apply = (bool) $this->option('apply');
        $fundId = $fund->idOrNull();

        if ($fundId === null) {
            $this->info('لا صندوق بعد — لا شيء يُكتب.');

            return self::SUCCESS;
        }

        $covered = InvestmentCashEntry::query()
            ->where('type', CashEntryType::ExpenseCoveredByCompany->value)
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->pluck('source_id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $expenses = InvestorDealExpense::query()
            ->where('investor_deal_id', $fundId)
            ->where('is_landed', false)
            ->whereNull('reverses_expense_id')
            ->whereNotIn('id', $covered)
            ->orderBy('id')
            ->get()
            ->reject(fn (InvestorDealExpense $expense): bool => $expense->isReversed());

        $rows = [];
        $total = '0';

        foreach ($expenses as $expense) {
            $share = $record->companysShareOf($expense);

            if (bccomp($share, '0', 2) <= 0) {
                continue;
            }

            $rows[] = [$expense->id, $expense->incurred_on?->toDateString(), $expense->name, (string) $expense->amount, $share];
            $total = bcadd($total, $share, 2);
        }

        $this->info($apply ? 'كُتب نصيبُ الشركة:' : 'تجربة — لم يُكتب شيء. هذا ما سيُكتب بـ --apply:');
        $this->table(['#', 'التاريخ', 'المصروف', 'المبلغ', 'على الشركة'], $rows);
        $this->line('المجموع: '.$total.' د.ل في '.count($rows).' مصروف');

        if ($apply && $rows !== []) {
            DB::transaction(function () use ($expenses, $record): void {
                foreach ($expenses as $expense) {
                    $record->coverTheCompanysShare($expense, null, now());
                }
            });
        }

        return self::SUCCESS;
    }
}
