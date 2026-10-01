<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\PurchaseOrder\Actions\PostVendorPayables;
use Illuminate\Console\Command;

/**
 * What was owed and paid to vendors before «علينا», onto their payables — TREASURY-DESIGN §٢٠.
 * Dry unless `--apply`; safe to run again.
 */
class PostVendorPayablesCommand extends Command
{
    protected $signature = 'treasury:post-vendor-payables
                            {--apply : يكتب فعلاً؛ بدونه يعرض ما سيُكتب ولا يكتب شيئاً}';

    protected $description = 'يُرحّل ديون أوامر الشراء ودفعات الموردين وديونهم الافتتاحية إلى حساب «علينا» لكل مورد';

    public function handle(PostVendorPayables $post): int
    {
        $apply = (bool) $this->option('apply');

        $report = $post($apply);

        $this->info($apply ? 'كُتب الترحيل:' : 'تجربة — لم يُكتب شيء. هذا ما سيُكتب بـ --apply:');

        $this->line("أوامر شراء رُحِّل دينها: {$report['orders']}");
        $this->line("دفعات وديون افتتاحية وخصومات رُحِّلت: {$report['rows']}");
        $this->line("مُتخطّى لأنه مُرحَّل من قبل: {$report['skipped']}");
        $this->line("دفعات على أوامر قبل النظام أُزيلت من «علينا»: {$report['unwound']}");

        $this->table(
            ['المورد', 'المستحق (الأوامر والدفعات)', 'رصيد «علينا»', 'متطابق'],
            array_map(
                fn (array $row) => [$row['vendor'], $row['owed'], $row['payable'], $row['matches'] ? 'نعم' : 'لا'],
                $report['vendors'],
            ),
        );

        $advances = array_filter($report['vendors'], fn (array $row) => bccomp($row['owed'], '0', 2) < 0);

        if ($advances !== []) {
            $this->warn('موردون دُفع لهم أكثر من المستحق (مقدّم) — راجعهم: '.implode('، ', array_column($advances, 'vendor')));
        }

        return self::SUCCESS;
    }
}
