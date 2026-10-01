<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Carrier\Support\CarrierAccount;
use App\Domain\Order\Actions\ImportOldPaymentsIntoTreasury;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Console\Command;

/**
 * The payments from before the treasury, into its accounts on their own dates — TREASURY-DESIGN
 * §١٧. Dry unless `--apply`; once only; refused after any opening balance.
 */
class ImportOldPaymentsIntoTreasuryCommand extends Command
{
    protected $signature = 'treasury:import-old-payments
                            {--apply : يكتب فعلاً؛ بدونه يعرض ما سيُكتب ولا يكتب شيئاً}';

    protected $description = 'يُدخل مدفوعات الطلبيات القديمة إلى الحسابات بتواريخها، وتسوياتِ النورس القديمة';

    public function handle(ImportOldPaymentsIntoTreasury $import, CarrierAccount $carrier, TreasuryService $treasury): int
    {
        $apply = (bool) $this->option('apply');

        // Said in one line rather than a stack trace. The Action refuses the same thing anyway.
        if ($treasury->hasAnyOpening()) {
            $this->error('سُجِّل رصيد افتتاحي لحساب واحد على الأقل — المدفوعات القديمة داخلةٌ فيه، واستيرادها الآن يحسبها مرتين.');
            $this->line('الاستيراد يسبق الافتتاح: شغّله قبل أي رصيد افتتاحي، ثم «جرد الحساب» لكل حساب.');

            return self::FAILURE;
        }

        // This layer names the carrier's system user; Order may not know Carrier. Looked up, not
        // created: a dry run writes nothing, and no carrier user means no Nawris payments.
        $report = $import($apply, $carrier->existingId());

        $this->info($apply ? 'كُتب الاستيراد:' : 'تجربة — لم يُكتب شيء. هذا ما سيُكتب بـ --apply:');

        $this->table(
            ['الحساب', 'الحركات', 'داخل', 'خارج'],
            array_map(
                fn (string $name, array $row) => [$name, $row['rows'], $row['in'], $row['out']],
                array_keys($report['accounts']),
                $report['accounts'],
            ),
        );

        $this->line("تسويات نورس قديمة: {$report['settlements']} بمجموع {$report['settled']} (من النورس إلى المصرف)");
        $this->line("مُتخطّى لأنه مُسجَّل من قبل: {$report['skipped']}");

        if (! $apply) {
            $this->warn('بعد --apply: سجّل «جرد الحساب» لكل حساب بالرصيد المعدود فعلاً، بدل الرصيد الافتتاحي.');
        }

        return self::SUCCESS;
    }
}
