<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Actions;

use App\Domain\EmployeeWallet\DTOs\SalaryRunResult;
use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Events\SalariesPosted;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Support\SalaryMonth;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\TreasuryService;
use Carbon\CarbonImmutable;

/**
 * The monthly salary run — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * On the 1st it posts each employee's salary into their wallet for the month just worked, as a
 * «مستحق» under «رواتب». It runs daily, so a missed 1st is caught up later in the same month;
 * the month key in the client token is what stops a second payment.
 *
 * Who is paid: active, with a salary above zero, with «راتب تلقائي» on, and whose account existed
 * before the 1st (a hire from this month did not work last month). Full salary, no prorating.
 *
 * Skipped: an employee whose salary was already entered by hand this posting month (a «رواتب»
 * credit that is not an automatic one and not reversed). Only this month, so a salary for the
 * previous month entered by hand at the start of it does not block the run.
 *
 * Nothing is posted while the switch is off, nor before `auto_salaries_from`: turning the switch
 * on never pays the month already running.
 */
final class PostMonthlySalaries
{
    public function __construct(
        private readonly EmployeeWalletService $wallets,
        private readonly TreasuryService $treasury,
    ) {}

    public function __invoke(bool $dryRun = false): SalaryRunResult
    {
        $settings = $this->treasury->settings();

        if (! $settings->auto_salaries) {
            return new SalaryRunResult(SalaryRunResult::OFF);
        }

        $postingMonth = SalaryMonth::postingMonth(CarbonImmutable::now());
        $workMonth = SalaryMonth::workMonth($postingMonth);
        $monthKey = SalaryMonth::key($workMonth);
        $monthLabel = SalaryMonth::label($workMonth);

        $from = $settings->auto_salaries_from?->toDateString();

        if ($from === null || $postingMonth->toDateString() < $from) {
            return new SalaryRunResult(SalaryRunResult::NOT_YET, $monthKey, $monthLabel);
        }

        $postingStart = $postingMonth->utc();
        $token = EmployeeWalletService::salaryToken($monthKey);
        $categoryId = (int) $this->treasury->categoryWithCode(ExpenseCategory::SALARY)->getKey();

        $alreadyPaid = EmployeeWalletEntry::query()
            ->where('client_token', $token)
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        $enteredByHand = EmployeeWalletEntry::query()
            ->where('type', EmployeeWalletEntryType::Credit->value)
            ->where('expense_category_id', $categoryId)
            ->where('occurred_at', '>=', $postingStart)
            ->where(fn ($q) => $q
                ->whereNull('client_token')
                ->orWhere('client_token', 'not like', EmployeeWalletService::SALARY_TOKEN_PREFIX.'%'))
            ->whereDoesntHave('reversal')
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->all();

        $employees = User::query()
            ->where('is_active', true)
            ->where('auto_salary', true)
            ->whereNotNull('salary')
            ->where('salary', '>', 0)
            ->where('created_at', '<', $postingStart)
            ->whereNotIn('id', $alreadyPaid)
            ->orderBy('id')
            ->get(['id', 'name', 'salary']);

        $posted = [];
        $skippedManual = [];

        foreach ($employees as $employee) {
            $id = (int) $employee->getKey();

            if (in_array($id, $enteredByHand, true)) {
                $skippedManual[] = $id;

                continue;
            }

            $amount = (string) $employee->salary;

            if ($dryRun) {
                $posted[$id] = $amount;

                continue;
            }

            // No catch here (the app renders exceptions at its boundary): a failure stops this
            // run, and tomorrow's picks up where it stopped, because paid months are skipped.
            $entry = $this->wallets->paySalary($id, $amount, $monthKey, "راتب {$monthLabel}");

            // A concurrent run may have written it first; only a new line counts as posted here.
            if ($entry->wasRecentlyCreated) {
                $posted[$id] = $amount;
            }
        }

        $result = new SalaryRunResult(SalaryRunResult::RAN, $monthKey, $monthLabel, $posted, $skippedManual);

        if (! $dryRun && $posted !== []) {
            SalariesPosted::dispatch($monthKey, $monthLabel, count($posted), $result->total(), count($skippedManual));
        }

        return $result;
    }
}
