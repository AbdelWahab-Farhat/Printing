<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\EmployeeWallet\Actions\PostMonthlySalaries;
use App\Domain\EmployeeWallet\DTOs\SalaryRunResult;
use App\Domain\Identity\Models\User;
use Illuminate\Console\Command;

/**
 * Posts last month's salaries into the employee wallets — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * Scheduled daily: the 1st does the work, and every later day of the month catches up anybody a
 * missed run left out. Running it twice writes nothing twice. See {@see PostMonthlySalaries}.
 */
class PostSalariesCommand extends Command
{
    protected $signature = 'employees:post-salaries
                            {--dry-run : Show who would be paid and write nothing}';

    protected $description = 'Posts last month\'s salaries into the employee wallets while «إضافة الرواتب تلقائياً» is on';

    public function handle(PostMonthlySalaries $run): int
    {
        $dryRun = (bool) $this->option('dry-run');
        $result = $run($dryRun);

        if ($result->status === SalaryRunResult::OFF) {
            $this->info('Automatic salaries are off. Nothing to post.');

            return self::SUCCESS;
        }

        if ($result->status === SalaryRunResult::NOT_YET) {
            $this->info('Automatic salaries start on a later month. Nothing to post now.');

            return self::SUCCESS;
        }

        $names = User::query()
            ->whereIn('id', [...array_keys($result->posted), ...$result->skippedManual])
            ->pluck('name', 'id');

        foreach ($result->posted as $id => $amount) {
            $this->info(($dryRun ? 'Would post' : 'Posted')." {$amount} to #{$id} {$names[$id]} ({$result->monthKey}).");
        }

        foreach ($result->skippedManual as $id) {
            $this->line("Skipped #{$id} {$names[$id]}: salary already entered by hand this month.");
        }

        $this->info(sprintf(
            '%s %d salaries for %s, total %s.',
            $dryRun ? 'Would post' : 'Posted',
            count($result->posted),
            $result->monthKey,
            $result->total(),
        ));

        return self::SUCCESS;
    }
}
