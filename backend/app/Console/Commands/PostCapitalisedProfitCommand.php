<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Actions\RecordCashEntry;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorWalletEntry;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * أرباحٌ حُوِّلت إلى رأس مالٍ قبل 2026-10-21 ولم تخرج من نقد الصندوق.
 *
 * كلُّ صفِّ `profit_capitalisation` لم يُعكس وليس له صفُّ {@see CashEntryType::ProfitCapitalised}
 * يُكتب له، **بتاريخ اليوم** — كما في `investment:cover-company-expense-shares`: الفتراتُ المغلقة
 * على أرقامها المعلنة، والنقدُ يصحّ من يوم الإصلاح. تجربةٌ ما لم يُمرَّر `--apply`، وإعادتُه لا
 * تكتب شيئاً مرّتين.
 */
class PostCapitalisedProfitCommand extends Command
{
    protected $signature = 'investment:post-capitalised-profit
                            {--apply : يكتب فعلاً؛ بدونه يعرض ما سيُكتب ولا يكتب شيئاً}';

    protected $description = 'يُخرج من نقد الصندوق كلَّ ربحٍ حُوِّل إلى رأس مالٍ قبل أن يُكتب له صفُّه';

    public function handle(RecordCashEntry $cash): int
    {
        $apply = (bool) $this->option('apply');

        $posted = InvestmentCashEntry::query()
            ->where('type', CashEntryType::ProfitCapitalised->value)
            ->where('source_type', AuditSubject::InvestorWalletEntry->value)
            ->pluck('source_id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        $entries = InvestorWalletEntry::query()
            ->with('investor')
            ->where('type', WalletEntryType::ProfitCapitalisation->value)
            ->whereNotIn('id', $posted)
            ->orderBy('id')
            ->get()
            ->reject(fn (InvestorWalletEntry $entry): bool => $entry->isReversed())
            ->values();

        $rows = [];
        $total = '0';

        foreach ($entries as $entry) {
            $rows[] = [$entry->id, $entry->occurred_at?->toDateString(), $entry->investor?->name, (string) $entry->amount];
            $total = bcadd($total, (string) $entry->amount, 2);
        }

        $this->info($apply ? 'خرج من نقد الصندوق:' : 'تجربة — لم يُكتب شيء. هذا ما سيُكتب بـ --apply:');
        $this->table(['#', 'التاريخ', 'المستثمر', 'المبلغ'], $rows);
        $this->line('المجموع: '.$total.' د.ل في '.count($rows).' تحويل');

        if ($apply && $rows !== []) {
            DB::transaction(function () use ($entries, $cash): void {
                foreach ($entries as $entry) {
                    $cash(
                        type: CashEntryType::ProfitCapitalised,
                        amount: (string) $entry->amount,
                        sourceType: AuditSubject::InvestorWalletEntry->value,
                        sourceId: (int) $entry->getKey(),
                        notes: 'تصحيح: تحويل أرباح إلى رأس مال سُجِّل قبل أن يخرج من نقد الصندوق',
                    );
                }
            });
        }

        return self::SUCCESS;
    }
}
