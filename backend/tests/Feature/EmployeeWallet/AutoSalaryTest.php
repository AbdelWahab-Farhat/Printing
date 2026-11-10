<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\Actions\PostMonthlySalaries;
use App\Domain\EmployeeWallet\DTOs\SalaryRunResult;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use Carbon\CarbonImmutable;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;

/**
 * Automatic salaries — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * The run on the 1st pays the month just worked, never twice, never before the first 1st after
 * the switch went on.
 */
final class AutoSalaryTest extends EmployeeWalletTestCase
{
    private const ZONE = 'Africa/Tripoli';

    // ── The switch ───────────────────────────────────────────────────────────────────────

    public function test_nothing_is_posted_while_the_switch_is_off(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->at('2026-12-01 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame(SalaryRunResult::OFF, $result->status);
        $this->assertSame(0, EmployeeWalletEntry::query()->where('user_id', $employee->id)->count());
    }

    public function test_turning_the_switch_on_starts_on_the_next_month(): void
    {
        // Arrange
        $this->at('2026-11-20 10:00');

        // Act
        $response = $this->putSettings(['auto_salaries' => true]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.auto_salaries', true)
            ->assertJsonPath('data.auto_salaries_from', '2026-12-01');
    }

    public function test_the_month_of_switching_on_is_read_in_tripoli_time(): void
    {
        // Arrange — 00:30 on 1 Dec in Tripoli is still 30 Nov in UTC, and it is December's switch-on.
        $this->at('2026-12-01 00:30');

        // Act
        $response = $this->putSettings(['auto_salaries' => true]);

        // Assert
        $response->assertOk()->assertJsonPath('data.auto_salaries_from', '2027-01-01');
    }

    public function test_the_start_date_is_never_taken_from_the_request(): void
    {
        // Arrange
        $this->at('2026-11-20 10:00');

        // Act
        $response = $this->putSettings(['auto_salaries' => true, 'auto_salaries_from' => '2026-11-01']);

        // Assert
        $response->assertOk()->assertJsonPath('data.auto_salaries_from', '2026-12-01');
    }

    public function test_turning_it_off_forgets_the_date_and_on_again_counts_afresh(): void
    {
        // Arrange
        $this->at('2026-11-20 10:00');
        $this->putSettings(['auto_salaries' => true])->assertOk();

        // Act
        $off = $this->putSettings(['auto_salaries' => false]);
        $this->at('2026-12-05 10:00');
        $on = $this->putSettings(['auto_salaries' => true]);

        // Assert
        $off->assertJsonPath('data.auto_salaries_from', null);
        $on->assertJsonPath('data.auto_salaries_from', '2027-01-01');
    }

    public function test_saving_another_setting_leaves_the_start_date_alone(): void
    {
        // Arrange
        $this->at('2026-11-20 10:00');
        $this->putSettings(['auto_salaries' => true])->assertOk();
        $this->at('2026-12-10 10:00');

        // Act
        $response = $this->putSettings(['auto_salaries' => true, 'block_overdraft' => false]);

        // Assert
        $response->assertOk()->assertJsonPath('data.auto_salaries_from', '2026-12-01');
    }

    // ── When it posts ────────────────────────────────────────────────────────────────────

    public function test_switching_on_mid_month_pays_nothing_in_that_month(): void
    {
        // Arrange — the owner's rule: deploying and switching on never pays the running month.
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-11-25 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame(SalaryRunResult::NOT_YET, $result->status);
        $this->assertSame(0, EmployeeWalletEntry::query()->where('user_id', $employee->id)->count());
    }

    public function test_the_first_of_the_month_pays_the_month_just_worked(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame('2026-11', $result->monthKey);
        $entry = EmployeeWalletEntry::query()->where('user_id', $employee->id)->sole();
        $this->assertSame(EmployeeWalletEntryType::Credit, $entry->type);
        $this->assertSame('3000.00', (string) $entry->amount);
        $this->assertSame('salary:2026-11', $entry->client_token);
        $this->assertSame('راتب نوفمبر 2026', $entry->notes);
        $this->assertSame($this->salaryCategory()->id, $entry->expense_category_id);
        $this->assertNull($entry->recorded_by);
        $this->assertSame('3000.00', $this->balance($employee));
    }

    public function test_the_salary_is_an_expense_against_the_wallets_payable_and_moves_no_cash(): void
    {
        // Arrange
        $employee = $this->employee('2500');
        $cashBefore = $this->accountBalance($this->defaultCash());
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $operation = TreasuryOperation::query()->sole();
        $this->assertSame($this->salaryCategory()->id, $operation->category_id);
        $this->assertSame((int) $employee->id, (int) $operation->employee_id);
        $this->assertSame('-2500.00', $this->accountBalance($this->walletsPayable()));
        $this->assertSame($cashBefore, $this->accountBalance($this->defaultCash()));
        $this->artisan('wallets:check')->assertExitCode(0);
    }

    public function test_a_missed_first_is_caught_up_later_in_the_month(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-03 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $this->assertSame('salary:2026-11', EmployeeWalletEntry::query()->where('user_id', $employee->id)->sole()->client_token);
    }

    public function test_a_month_is_never_paid_twice(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');
        $this->runSalaries();

        // Act
        $this->at('2026-12-02 08:00');
        $second = $this->runSalaries();
        $this->artisan('employees:post-salaries')->assertExitCode(0);

        // Assert
        $this->assertSame([], $second->posted);
        $this->assertSame(1, EmployeeWalletEntry::query()->where('user_id', $employee->id)->count());
        $this->assertSame('3000.00', $this->balance($employee));
    }

    public function test_a_reversed_salary_is_not_paid_again(): void
    {
        // Arrange — unpaid leave: the manager reverses the month's salary.
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');
        $this->runSalaries();
        $entry = EmployeeWalletEntry::query()->where('user_id', $employee->id)->sole();
        $this->reverse($this->manager(), (int) $entry->id)->assertCreated();

        // Act
        $this->at('2026-12-02 08:00');
        $this->runSalaries();

        // Assert
        $this->assertSame(2, EmployeeWalletEntry::query()->where('user_id', $employee->id)->count());
        $this->assertSame('0.00', $this->balance($employee));
    }

    public function test_the_next_month_is_paid_on_its_own_first(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');
        $this->runSalaries();

        // Act
        $this->at('2027-01-01 08:00');
        $this->runSalaries();

        // Assert
        $this->assertSame(
            ['salary:2026-11', 'salary:2026-12'],
            EmployeeWalletEntry::query()->where('user_id', $employee->id)->orderBy('id')->pluck('client_token')->all(),
        );
        $this->assertSame('6000.00', $this->balance($employee));
    }

    public function test_a_locked_period_does_not_stop_the_run(): void
    {
        // Arrange — the system writes at its own time; the lock guards hand entries.
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');
        $this->lockUntil(Carbon::parse('2026-12-01'));

        // Act
        $this->runSalaries();

        // Assert
        $this->assertSame('3000.00', $this->balance($employee));
    }

    // ── Who is paid ──────────────────────────────────────────────────────────────────────

    public function test_only_active_employees_with_a_salary_and_the_switch_on_are_paid(): void
    {
        // Arrange
        $paid = $this->employee('3000');
        $stopped = $this->employee('3000', ['is_active' => false]);
        $noSalary = $this->employee(null);
        $zero = $this->employee('0');
        $manual = $this->employee('3000', ['auto_salary' => false]);
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame([(int) $paid->id => '3000.00'], $result->posted);
        foreach ([$stopped, $noSalary, $zero, $manual] as $skipped) {
            $this->assertSame(0, EmployeeWalletEntry::query()->where('user_id', $skipped->id)->count());
        }
    }

    public function test_an_employee_added_on_or_after_the_first_is_not_in_that_run(): void
    {
        // Arrange — a December hire did not work November.
        $old = $this->employee('3000', [], '2026-11-30 10:00');
        $new = $this->employee('3000', [], '2026-12-02 10:00');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-03 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame([(int) $old->id], array_keys($result->posted));
        $this->assertSame(0, EmployeeWalletEntry::query()->where('user_id', $new->id)->count());
    }

    public function test_the_full_salary_is_paid_without_prorating(): void
    {
        // Arrange — joined 16 Nov: the owner chose no prorating.
        $employee = $this->employee('3000', [], '2026-11-16 09:00');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $this->assertSame('3000.00', $this->balance($employee));
    }

    // ── Salaries entered by hand ─────────────────────────────────────────────────────────

    public function test_an_employee_paid_by_hand_this_month_is_skipped(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 07:00');
        $this->credit($this->manager(), $employee, ['amount' => '3000'])->assertCreated();
        $this->at('2026-12-01 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame([(int) $employee->id], $result->skippedManual);
        $this->assertSame('3000.00', $this->balance($employee));
    }

    public function test_a_salary_entered_by_hand_last_month_does_not_block_this_run(): void
    {
        // Arrange — October's salary entered by hand on 2 Nov, the old way, before switching on.
        $employee = $this->employee('3000', [], '2026-09-01 09:00');
        $this->at('2026-11-02 10:00');
        $this->credit($this->manager(), $employee, ['amount' => '3000'])->assertCreated();
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $result = $this->runSalaries();

        // Assert
        $this->assertSame([], $result->skippedManual);
        $this->assertSame('6000.00', $this->balance($employee));
    }

    public function test_a_reversed_hand_salary_does_not_block_the_run(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $headers = $this->manager();
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 07:00');
        $id = (int) $this->credit($headers, $employee, ['amount' => '3000'])->assertCreated()->json('data.entry.id');
        $this->reverse($headers, $id)->assertCreated();
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $this->assertSame('3000.00', $this->balance($employee));
    }

    public function test_a_bonus_under_another_category_does_not_block_the_run(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $bonus = ExpenseCategory::query()->create(['name' => 'مكافآت', 'requires_employee' => false, 'is_active' => true, 'sort_order' => 9]);
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 07:00');
        $this->credit($this->manager(), $employee, ['amount' => '200', 'category_id' => $bonus->id])->assertCreated();
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $this->assertSame('3200.00', $this->balance($employee));
    }

    // ── Notifications ────────────────────────────────────────────────────────────────────

    public function test_each_employee_hears_about_their_salary(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::EmployeeWalletMoved->value)->sole();
        $this->assertSame(1, $notification->recipients()->where('user_id', $employee->id)->count());
    }

    public function test_wallet_readers_get_one_summary(): void
    {
        // Arrange
        $reader = User::factory()->create();
        $reader->givePermissionTo(PermissionName::ViewEmployeeWallets->value);
        $this->employee('3000');
        $this->employee('2500.50');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->runSalaries();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::SalariesPosted->value)->sole();
        $this->assertSame(1, $notification->recipients()->where('user_id', $reader->id)->count());
        $rendered = app(NotificationType::SalariesPosted->definition())->render($notification->payload);
        $this->assertSame('أُضيفت رواتب نوفمبر 2026 إلى المحافظ', $rendered->title);
        $this->assertSame('2 موظف · المجموع 5,500.50 د.ل', $rendered->body);
        $this->assertSame('/wallet-transactions?tab=employees', $rendered->route);
    }

    public function test_no_summary_when_nothing_was_posted(): void
    {
        // Arrange
        $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');
        $this->runSalaries();

        // Act
        $this->at('2026-12-02 08:00');
        $this->runSalaries();

        // Assert
        $this->assertSame(1, Notification::query()->where('type', NotificationType::SalariesPosted->value)->count());
    }

    // ── The command ──────────────────────────────────────────────────────────────────────

    public function test_a_dry_run_writes_nothing(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->artisan('employees:post-salaries', ['--dry-run' => true])
            ->expectsOutputToContain('Would post 1 salaries for 2026-11, total 3000.00.')
            ->assertExitCode(0);

        // Assert
        $this->assertSame(0, EmployeeWalletEntry::query()->where('user_id', $employee->id)->count());
        $this->assertSame(0, Notification::query()->count());
    }

    public function test_the_command_posts(): void
    {
        // Arrange
        $employee = $this->employee('3000');
        $this->switchOn('2026-12-01');
        $this->at('2026-12-01 08:00');

        // Act
        $this->artisan('employees:post-salaries')
            ->expectsOutputToContain('Posted 1 salaries for 2026-11, total 3000.00.')
            ->assertExitCode(0);

        // Assert
        $this->assertSame('3000.00', $this->balance($employee));
    }

    // ── The per-employee switch ──────────────────────────────────────────────────────────

    public function test_the_per_employee_switch_needs_the_salary_permission(): void
    {
        // Arrange
        $employee = $this->employee('3000');

        // Act
        $this->app->get('auth')->forgetGuards();
        $response = $this->withHeaders($this->auth([PermissionName::ManageUsers]))
            ->patchJson("/api/v1/users/{$employee->id}/auto-salary", ['auto_salary' => false]);

        // Assert
        $response->assertForbidden();
        $this->assertTrue((bool) $employee->fresh()->auto_salary);
    }

    public function test_the_per_employee_switch_turns_off_and_reads_back(): void
    {
        // Arrange
        $employee = $this->employee('3000');

        // Act
        $this->app->get('auth')->forgetGuards();
        $response = $this->withHeaders($this->auth([PermissionName::ManageUserSalaries]))
            ->patchJson("/api/v1/users/{$employee->id}/auto-salary", ['auto_salary' => false]);

        // Assert
        $response->assertOk()->assertJsonPath('data.auto_salary', false);
        $this->assertFalse((bool) $employee->fresh()->auto_salary);
    }

    public function test_the_switch_is_hidden_from_a_reader_without_the_salary_permission(): void
    {
        // Arrange
        $employee = $this->employee('3000');

        // Act
        $response = $this->read($this->auth([PermissionName::ViewUsers]), "users/{$employee->id}");

        // Assert
        $response->assertOk()->assertJsonMissingPath('data.auto_salary');
    }

    public function test_a_new_account_starts_with_the_switch_on(): void
    {
        // Arrange
        $employee = User::factory()->create(['salary' => '3000']);

        // Act
        $response = $this->read($this->auth([PermissionName::ViewUsers, PermissionName::ManageUserSalaries]), "users/{$employee->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.auto_salary', true);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────────────────

    /**
     * An employee with this salary, whose account was made on 1 Oct unless said otherwise.
     *
     * @param  array<string, mixed>  $attributes
     */
    private function employee(?string $salary, array $attributes = [], string $createdAt = '2026-10-01 09:00'): User
    {
        $user = User::factory()->create(['salary' => $salary, ...$attributes]);
        $user->forceFill(['created_at' => CarbonImmutable::parse($createdAt, self::ZONE)->utc()])->save();

        return $user;
    }

    private function switchOn(string $from): void
    {
        TreasurySetting::current()->forceFill(['auto_salaries' => true, 'auto_salaries_from' => $from])->save();
    }

    /** Tripoli wall-clock time. */
    private function at(string $local): void
    {
        $this->travelTo(CarbonImmutable::parse($local, self::ZONE));
    }

    private function runSalaries(): SalaryRunResult
    {
        return app(PostMonthlySalaries::class)();
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function putSettings(array $payload): TestResponse
    {
        $this->app->get('auth')->forgetGuards();

        return $this->withHeaders($this->auth([
            PermissionName::ViewTreasury,
            PermissionName::ManageTreasury,
        ]))->putJson('/api/v1/treasury/settings', $payload);
    }
}
