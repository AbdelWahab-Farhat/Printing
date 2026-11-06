<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * من يرى ومن يحرّك — EMPLOYEE-WALLET-DESIGN §٦.
 *
 * **السحبُ لمن يملك صلاحيته وحده، ولا أحد يحرّك محفظته بنفسه إلا المدير** (قرار صاحب العمل
 * ٢٠٢٦-١١-٠٥). والموظف يقرأ محفظته هو بلا صلاحية، ولا يرى منها اسم الحساب.
 */
class EmployeeWalletAccessTest extends EmployeeWalletTestCase
{
    // ── كلُّ حركةٍ بصلاحيتها ─────────────────────────────────────────────────────────────

    /**
     * @return array<string, array{string, PermissionName}>
     */
    public static function writesAndTheirGrants(): array
    {
        return [
            'deposit' => ['deposit', PermissionName::DepositToEmployeeWallets],
            'credit' => ['credit', PermissionName::CreditEmployeeWallets],
            'withdrawal' => ['withdraw', PermissionName::WithdrawFromEmployeeWallets],
            'adjustment' => ['adjust', PermissionName::AdjustEmployeeWallets],
        ];
    }

    #[DataProvider('writesAndTheirGrants')]
    public function test_every_write_needs_its_own_grant(string $write, PermissionName $needed): void
    {
        // Arrange — يملك الصلاحيات الأخرى كلها، إلا التي تخصّ هذه الحركة.
        $employee = User::factory()->create();
        $others = array_values(array_filter(self::ALL_GRANTS, fn (PermissionName $p) => $p !== $needed));
        $headers = $this->auth($others);

        // Act
        $response = $this->{$write}($headers, $employee);

        // Assert
        $response->assertForbidden()->assertJsonPath('status', false);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_wallet_is_closed_to_the_unsigned(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $read = $this->getJson("/api/v1/users/{$employee->id}/wallet");
        $write = $this->postJson("/api/v1/users/{$employee->id}/wallet/withdrawals", ['amount' => '1', 'method' => 'cash']);
        $mine = $this->getJson('/api/v1/my-wallet');

        // Assert
        $read->assertUnauthorized();
        $write->assertUnauthorized();
        $mine->assertUnauthorized();
    }

    public function test_reading_a_colleagues_wallet_needs_the_grant(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $wallet = $this->read($this->auth(), "users/{$employee->id}/wallet");
        $entries = $this->read($this->auth(), "users/{$employee->id}/wallet/entries");
        $all = $this->read($this->auth(), 'employee-wallet-entries');

        // Assert
        $wallet->assertForbidden();
        $entries->assertForbidden();
        $all->assertForbidden();
    }

    public function test_a_missing_employee_is_a_404(): void
    {
        // Act
        $read = $this->read($this->manager(), 'users/999999/wallet');
        $write = $this->send($this->manager(), 'users/999999/wallet/deposits', ['amount' => '1', 'method' => 'cash']);

        // Assert
        $read->assertNotFound();
        $write->assertNotFound();
    }

    // ── محفظتك بنفسك ─────────────────────────────────────────────────────────────────────

    #[DataProvider('writesAndTheirGrants')]
    public function test_nobody_moves_their_own_wallet(string $write, PermissionName $needed): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->headersFor($employee, [$needed]);

        // Act
        $response = $this->{$write}($headers, $employee);

        // Assert
        $response->assertForbidden()
            ->assertJsonPath('status', false)
            ->assertJsonPath('message', 'لا تحرّك محفظتك بنفسك — يسجّلها زميلٌ يملك الصلاحية');
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_nobody_reverses_a_row_on_their_own_wallet(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $id = (int) $this->deposit($this->manager(), $employee)->json('data.entry.id');
        $headers = $this->headersFor($employee, [PermissionName::ReverseEmployeeWalletEntries]);

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertForbidden();
        $this->assertSame('100.00', $this->balance($employee));
    }

    public function test_the_administrator_moves_their_own_wallet(): void
    {
        // Arrange
        $admin = $this->admin();
        $headers = $this->headersFor($admin);

        // Act
        $response = $this->deposit($headers, $admin, ['amount' => '100']);

        // Assert
        $response->assertCreated();
        $this->assertSame('100.00', $this->balance($admin));
    }

    public function test_the_wallet_tells_the_app_whether_its_reader_may_move_it(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $reader = User::factory()->create();
        $grants = [PermissionName::ViewEmployeeWallets];
        $colleague = $this->headersFor($reader, $grants);
        $self = $this->headersFor($employee, $grants);

        // Act
        $forColleague = $this->read($colleague, "users/{$employee->id}/wallet");
        $forSelf = $this->read($self, "users/{$employee->id}/wallet");

        // Assert
        $forColleague->assertOk()->assertJsonPath('data.can_move', true);
        $forSelf->assertOk()->assertJsonPath('data.can_move', false);
    }

    public function test_a_row_on_the_readers_own_wallet_offers_no_reversal(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->deposit($this->manager(), $employee)->assertCreated();
        $self = $this->headersFor($employee, [PermissionName::ViewEmployeeWallets, PermissionName::ReverseEmployeeWalletEntries]);
        $colleague = $this->auth([PermissionName::ViewEmployeeWallets, PermissionName::ReverseEmployeeWalletEntries]);

        // Act
        $forSelf = $this->read($self, "users/{$employee->id}/wallet/entries");
        $forColleague = $this->read($colleague, "users/{$employee->id}/wallet/entries");

        // Assert
        $forSelf->assertOk()->assertJsonPath('data.0.can_reverse', false);
        $forColleague->assertOk()->assertJsonPath('data.0.can_reverse', true);
    }

    // ── القراءة ──────────────────────────────────────────────────────────────────────────

    public function test_a_wallet_shows_its_balance_and_newest_rows(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        foreach (range(1, 6) as $ignored) {
            $this->deposit($headers, $employee, ['amount' => '10'])->assertCreated();
        }

        // Act
        $response = $this->read($headers, "users/{$employee->id}/wallet");

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.user_id', $employee->id)
            ->assertJsonPath('data.balance', '60.00')
            ->assertJsonCount(5, 'data.recent');
    }

    public function test_an_employee_with_no_rows_holds_zero(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->read($this->manager(), "users/{$employee->id}/wallet");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.balance', '0.00')
            ->assertJsonCount(0, 'data.recent');
    }

    public function test_the_wage_reaches_only_who_may_read_wages(): void
    {
        // Arrange
        $employee = User::factory()->create(['salary' => '2500.00']);
        $withGrant = $this->auth([PermissionName::ViewEmployeeWallets, PermissionName::ManageUserSalaries]);
        $withoutGrant = $this->auth([PermissionName::ViewEmployeeWallets]);

        // Act
        $with = $this->read($withGrant, "users/{$employee->id}/wallet");
        $without = $this->read($withoutGrant, "users/{$employee->id}/wallet");

        // Assert — الغيابُ «لا يحقّ لك»، وهو غير الصفر.
        $with->assertOk()->assertJsonPath('data.salary', '2500.00');
        $without->assertOk()->assertJsonMissingPath('data.salary');
    }

    public function test_the_statement_is_newest_first_with_the_balance_in_meta(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();
        $newest = $this->withdraw($headers, $employee, ['amount' => '30'])->json('data.entry.id');

        // Act
        $response = $this->read($headers, "users/{$employee->id}/wallet/entries");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.id', $newest)
            ->assertJsonPath('meta.balance', '70.00')
            ->assertJsonPath('meta.total', 2);
    }

    public function test_the_statement_narrows_to_a_type(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee)->assertCreated();
        $this->credit($headers, $employee)->assertCreated();
        $this->adjust($headers, $employee)->assertCreated();
        $this->adjust($headers, $employee, ['direction' => 'debit'])->assertCreated();

        // Act
        $credits = $this->read($headers, "users/{$employee->id}/wallet/entries?type=credit");
        $adjustments = $this->read($headers, "users/{$employee->id}/wallet/entries?type=adjustment");

        // Assert — «تعديل» رقاقةٌ واحدة لنوعين، زيادةً ونقصاً.
        $credits->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.type', 'credit');
        $adjustments->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_the_statement_narrows_to_a_range_of_shop_days(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['occurred_at' => '2026-10-10T12:00:00+02:00'])->assertCreated();
        $this->deposit($headers, $employee, ['occurred_at' => '2026-10-20T12:00:00+02:00'])->assertCreated();

        // Act
        $response = $this->read($headers, "users/{$employee->id}/wallet/entries?from=2026-10-15&to=2026-10-25");

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_an_unknown_type_is_refused_and_an_absurd_page_size_is_capped(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();

        // Act
        $unknown = $this->read($headers, "users/{$employee->id}/wallet/entries?type=gold");
        $capped = $this->read($headers, "users/{$employee->id}/wallet/entries?per_page=9999");

        // Assert
        $unknown->assertUnprocessable()->assertJsonValidationErrors('type');
        $capped->assertOk()->assertJsonPath('meta.per_page', 100);
    }

    public function test_the_transactions_page_lists_every_wallet_and_finds_an_employee(): void
    {
        // Arrange
        $first = User::factory()->create(['name' => 'علي الطرابلسي']);
        $second = User::factory()->create(['name' => 'سالم']);
        $headers = $this->manager();
        $this->deposit($headers, $first)->assertCreated();
        $this->deposit($headers, $second)->assertCreated();

        // Act
        $all = $this->read($headers, 'employee-wallet-entries');
        $byName = $this->read($headers, 'employee-wallet-entries?q='.urlencode('الطرابلسي'));
        $byCode = $this->read($headers, 'employee-wallet-entries?q='.urlencode((string) $second->employee_code));
        $byId = $this->read($headers, "employee-wallet-entries?user_id={$second->id}");

        // Assert
        $all->assertOk()->assertJsonCount(2, 'data');
        $byName->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.user.name', 'علي الطرابلسي');
        $byCode->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.user.id', $second->id);
        $byId->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.user.id', $second->id);
    }

    public function test_the_transactions_page_of_nobody_is_empty(): void
    {
        // Act
        $response = $this->read($this->manager(), 'employee-wallet-entries');

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data')->assertJsonPath('meta.total', 0);
    }

    // ── «محفظتي» ─────────────────────────────────────────────────────────────────────────

    public function test_an_employee_reads_their_own_wallet_with_no_grant(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->deposit($this->manager(), $employee, ['amount' => '100', 'notes' => 'أمانة'])->assertCreated();
        $headers = $this->headersFor($employee);

        // Act
        $wallet = $this->read($headers, 'my-wallet');
        $entries = $this->read($headers, 'my-wallet/entries');

        // Assert
        $wallet->assertOk()->assertJsonPath('data.balance', '100.00');
        $entries->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.type_label', 'إيداع')
            ->assertJsonPath('data.0.direction', 'in')
            ->assertJsonPath('data.0.notes', 'أمانة')
            ->assertJsonPath('meta.balance', '100.00');
    }

    public function test_my_wallet_names_no_account_and_no_colleague(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->deposit($this->manager(), $employee)->assertCreated();

        // Act
        $response = $this->read($this->headersFor($employee), 'my-wallet/entries');

        // Assert
        $response->assertOk()
            ->assertJsonMissingPath('data.0.treasury_account')
            ->assertJsonMissingPath('data.0.recorder')
            ->assertJsonMissingPath('data.0.can_reverse');
    }

    public function test_my_wallet_shows_no_other_employees_rows(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee)->assertCreated();
        $this->deposit($headers, User::factory()->create(), ['amount' => '999'])->assertCreated();

        // Act
        $response = $this->read($this->headersFor($employee), 'my-wallet/entries');

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount', '100.00')
            ->assertJsonPath('meta.balance', '100.00');
    }

    // ── السجل والصلاحيات ─────────────────────────────────────────────────────────────────

    public function test_a_row_has_its_history_behind_the_logs_grant(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $id = (int) $this->deposit($this->manager(), $employee)->json('data.entry.id');

        // Act
        $with = $this->read($this->auth([PermissionName::ViewActivityLogs]), "employee-wallet-entries/{$id}/logs");
        $without = $this->read($this->manager(), "employee-wallet-entries/{$id}/logs");

        // Assert
        $with->assertOk()->assertJsonPath('data.0.event', 'created');
        $without->assertForbidden();
    }

    public function test_the_roles_screen_groups_the_six_grants(): void
    {
        // Arrange
        $expected = 'محافظ الموظفين';

        // Act
        $groups = array_map(fn (PermissionName $p) => $p->group(), self::ALL_GRANTS);

        // Assert
        $this->assertSame(array_fill(0, 6, $expected), $groups);
    }
}
