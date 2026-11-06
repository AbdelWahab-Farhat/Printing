<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletEntryIsImmutable;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use Illuminate\Http\UploadedFile;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * الحركات: الإيداع والمستحق والسحب والتعديل — EMPLOYEE-WALLET-DESIGN §٣.
 *
 * **ما يُلزَم به كلُّ اختبار**: أن تتحرك المحفظة والخزينة معاً، وأن يبقى حساب «أرصدة محافظ الموظفين»
 * سالبَ مجموع المحافظ — وهو ما يثبته `wallets:check`.
 */
class EmployeeWalletMoneyTest extends EmployeeWalletTestCase
{
    // ── الإيداع ──────────────────────────────────────────────────────────────────────────

    public function test_a_cash_deposit_fills_the_wallet_the_drawer_and_the_debt(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $cash = $this->defaultCash();

        // Act
        $response = $this->deposit($this->manager(), $employee, ['amount' => '150']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('message', 'تم الإيداع')
            ->assertJsonPath('data.entry.type', 'deposit')
            ->assertJsonPath('data.entry.type_label', 'إيداع')
            ->assertJsonPath('data.entry.direction', 'in')
            ->assertJsonPath('data.entry.amount', '150.00')
            ->assertJsonPath('data.entry.method', 'cash')
            ->assertJsonPath('data.entry.treasury_account.id', $cash->id)
            ->assertJsonPath('data.balance', '150.00');
        $this->assertSame('150.00', $this->balance($employee));
        $this->assertSame('150.00', $this->accountBalance($cash));
        $this->assertSame('-150.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_deposit_names_itself_in_the_account_ledger(): void
    {
        // Arrange
        $employee = User::factory()->create(['name' => 'علي الطرابلسي']);

        // Act
        $this->deposit($this->manager(), $employee)->assertCreated();

        // Assert
        $movement = TreasuryMovement::query()->where('account_id', $this->defaultCash()->id)->firstOrFail();
        $this->assertSame(MovementKind::EmployeeWalletDeposit, $movement->kind);
        $this->assertSame('إيداع محفظة موظف', $movement->kind->label());
        $this->assertStringContainsString('علي الطرابلسي', (string) $movement->notes);
    }

    public function test_a_deposit_lands_in_the_account_the_person_chose(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $office = TreasuryAccount::factory()->create(['kind' => AccountKind::Cash, 'is_default' => false]);

        // Act
        $response = $this->deposit($this->manager(), $employee, ['treasury_account_id' => $office->id]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.entry.treasury_account.id', $office->id);
        $this->assertSame('100.00', $this->accountBalance($office));
        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
    }

    public function test_a_deposit_by_transfer_needs_its_receipt(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();

        // Act
        $without = $this->deposit($headers, $employee, ['method' => 'bank_transfer']);
        $with = $this->deposit($headers, $employee, [
            'method' => 'bank_transfer',
            'receipt' => UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf'),
        ]);

        // Assert
        $without->assertUnprocessable()->assertJsonValidationErrors('receipt');
        $with->assertCreated()->assertJsonPath('data.entry.has_receipt', true);
    }

    public function test_a_deposit_may_not_land_in_an_account_of_another_kind(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->deposit($this->manager(), $employee, [
            'method' => 'libyana',
            'treasury_account_id' => $this->defaultCash()->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame('0.00', $this->balance($employee));
    }

    public function test_a_deposit_inside_the_locked_period_is_refused(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->lockUntil(now()->subDay());

        // Act
        $response = $this->deposit($this->manager(), $employee, ['occurred_at' => now()->subDays(3)->toIso8601String()]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    public function test_a_deposit_before_the_last_count_of_its_account_is_refused(): void
    {
        // Arrange — جُرد الدرج اليوم، فلا يُكتب فيه شيءٌ بتاريخٍ قبله.
        $employee = User::factory()->create();
        $cash = $this->defaultCash();
        $counter = $this->auth([PermissionName::AdjustTreasuryBalances]);
        $this->send($counter, 'treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $cash->id,
            'counted_balance' => '500',
            'notes' => 'جرد الدرج',
        ])->assertCreated();

        // Act
        $response = $this->deposit($this->manager(), $employee, ['occurred_at' => now()->subDays(3)->toIso8601String()]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('0.00', $this->balance($employee));
    }

    /**
     * @return array<string, array{array<string, mixed>, string}>
     */
    public static function badDeposits(): array
    {
        return [
            'no amount' => [['amount' => null], 'amount'],
            'zero' => [['amount' => '0'], 'amount'],
            'negative' => [['amount' => '-5'], 'amount'],
            'three places' => [['amount' => '1.234'], 'amount'],
            'too much' => [['amount' => '99999999999'], 'amount'],
            'no method' => [['method' => null], 'method'],
            'unknown method' => [['method' => 'gold'], 'method'],
            'online is not typed by hand' => [['method' => 'online'], 'method'],
            'the future' => [['occurred_at' => '2099-01-01'], 'occurred_at'],
            'long reference' => [['reference' => str_repeat('م', 101)], 'reference'],
            'long notes' => [['notes' => str_repeat('م', 1001)], 'notes'],
            'long token' => [['client_token' => str_repeat('a', 65)], 'client_token'],
            'no such account' => [['treasury_account_id' => 999999], 'treasury_account_id'],
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    #[DataProvider('badDeposits')]
    public function test_a_malformed_deposit_is_refused(array $payload, string $field): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->deposit($this->manager(), $employee, $payload);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('status', false)
            ->assertJsonValidationErrors($field);
        $this->assertSame(0, EmployeeWalletEntry::query()->count());
    }

    // ── المستحق ──────────────────────────────────────────────────────────────────────────

    public function test_a_credit_is_an_expense_on_the_debt_and_moves_no_cash(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $cash = $this->defaultCash();

        // Act
        $response = $this->credit($this->manager(), $employee, ['amount' => '2000', 'notes' => 'راتب نوفمبر']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم تسجيل المستحق')
            ->assertJsonPath('data.entry.type', 'credit')
            ->assertJsonPath('data.entry.direction', 'in')
            ->assertJsonPath('data.entry.category.name', 'رواتب')
            ->assertJsonPath('data.balance', '2000.00');
        $this->assertSame('2000.00', $this->balance($employee));
        $this->assertSame('0.00', $this->accountBalance($cash));
        $this->assertSame('-2000.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_credit_lists_in_the_expenses_tab_with_its_category_and_employee(): void
    {
        // Arrange
        $employee = User::factory()->create(['name' => 'سالم']);
        $this->credit($this->manager(), $employee, ['amount' => '2000'])->assertCreated();
        $viewer = $this->auth([PermissionName::ViewTreasury]);

        // Act
        $response = $this->read($viewer, 'treasury/expenses');

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount', '2000.00')
            ->assertJsonPath('data.0.category.name', 'رواتب')
            ->assertJsonPath('data.0.employee.name', 'سالم')
            ->assertJsonPath('data.0.is_reversible', false)
            ->assertJsonPath('meta.expenses_total', '2000.00');
    }

    public function test_a_credit_takes_any_category_people_added(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $bonus = ExpenseCategory::factory()->create(['name' => 'مكافآت']);

        // Act
        $response = $this->credit($this->manager(), $employee, ['category_id' => $bonus->id]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.entry.category.name', 'مكافآت');
    }

    /**
     * @return array<string, array{string}>
     */
    public static function categoriesTheSystemOwns(): array
    {
        return [
            'an advance stays an expense from a drawer' => [ExpenseCategory::ADVANCE],
            'what the carrier kept' => [ExpenseCategory::CARRIER_FEE],
            'what EzonePay kept' => [ExpenseCategory::ONLINE_PAYMENT_FEE],
        ];
    }

    #[DataProvider('categoriesTheSystemOwns')]
    public function test_a_credit_refuses_a_category_the_system_owns(string $code): void
    {
        // Arrange
        $employee = User::factory()->create();
        $category = ExpenseCategory::query()->where('code', $code)->firstOrFail();

        // Act
        $response = $this->credit($this->manager(), $employee, ['category_id' => $category->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('category_id');
        $this->assertSame('0.00', $this->balance($employee));
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    public function test_a_credit_refuses_a_switched_off_category(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $category = ExpenseCategory::factory()->create(['is_active' => false]);

        // Act
        $response = $this->credit($this->manager(), $employee, ['category_id' => $category->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('category_id');
    }

    public function test_a_credit_needs_a_category(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->credit($this->manager(), $employee, ['category_id' => null]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('category_id');
    }

    public function test_a_credit_inside_the_locked_period_is_refused(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->lockUntil(now()->subDay());

        // Act
        $response = $this->credit($this->manager(), $employee, ['occurred_at' => now()->subDays(3)->toIso8601String()]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('0.00', $this->balance($employee));
    }

    public function test_the_salaries_category_is_found_by_its_code(): void
    {
        // Arrange — الرمزُ ما يعتمد عليه الكود، لا اسمٌ يُعاد كتابته.

        // Act
        $category = $this->salaryCategory();

        // Assert
        $this->assertSame('رواتب', $category->name);
        $this->assertTrue($category->isSystem());
    }

    // ── السحب ────────────────────────────────────────────────────────────────────────────

    public function test_a_cash_withdrawal_takes_from_the_wallet_the_drawer_and_the_debt(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '300'])->assertCreated();
        $cash = $this->defaultCash();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '120']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم السحب')
            ->assertJsonPath('data.entry.type', 'withdrawal')
            ->assertJsonPath('data.entry.direction', 'out')
            ->assertJsonPath('data.entry.treasury_account.id', $cash->id)
            ->assertJsonPath('data.balance', '180.00');
        $this->assertSame('180.00', $this->balance($employee));
        $this->assertSame('180.00', $this->accountBalance($cash));
        $this->assertSame('-180.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_salary_then_a_withdrawal_reads_the_way_the_plan_says(): void
    {
        // Arrange — المثال في EMPLOYEE-WALLET-DESIGN §٣، والدرجُ ممتلئٌ من إيداع زميل.
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, User::factory()->create(), ['amount' => '500'])->assertCreated();
        $this->credit($headers, $employee, ['amount' => '2000'])->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '500']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.balance', '1500.00');
        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('-2000.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    /**
     * @return array<string, array{string, AccountKind, bool}>
     */
    public static function withdrawalMethods(): array
    {
        return [
            'cash' => ['cash', AccountKind::Cash, false],
            'transfer' => ['bank_transfer', AccountKind::Bank, true],
            'card' => ['bank_card', AccountKind::Bank, false],
            'libyana' => ['libyana', AccountKind::Wallet, false],
        ];
    }

    #[DataProvider('withdrawalMethods')]
    public function test_every_counter_method_pays_a_withdrawal(string $method, AccountKind $kind, bool $needsReceipt): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        TreasurySetting::current()->forceFill(['block_overdraft' => false])->save();
        $this->credit($headers, $employee, ['amount' => '100'])->assertCreated();
        $receipt = $needsReceipt ? ['receipt' => UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf')] : [];

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '40', 'method' => $method, ...$receipt]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.entry.method', $method)
            ->assertJsonPath('data.entry.treasury_account.id', $this->defaultOf($kind)->id)
            ->assertJsonPath('data.balance', '60.00');
    }

    public function test_a_withdrawal_by_transfer_needs_its_receipt(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->credit($headers, $employee)->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['method' => 'bank_transfer']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('receipt');
        $this->assertSame('2000.00', $this->balance($employee));
    }

    public function test_a_withdrawal_never_exceeds_the_wallet(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100.01']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('100.00', $this->balance($employee));
        $this->assertSame('100.00', $this->accountBalance($this->defaultCash()));
    }

    public function test_the_whole_balance_may_be_withdrawn(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.balance', '0.00');
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_withdrawal_is_refused_when_the_account_lacks_the_money(): void
    {
        // Arrange — في المحفظة ٢٠٠٠ مستحقة، والدرجُ فارغ.
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->credit($headers, $employee)->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('2000.00', $this->balance($employee));
        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
    }

    public function test_the_refusal_keeps_the_drawer_balance_from_who_may_not_read_it(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, User::factory()->create(), ['amount' => '30'])->assertCreated();
        $this->credit($headers, $employee)->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100']);

        // Assert
        $response->assertUnprocessable();
        $this->assertStringNotContainsString('30.00', (string) $response->json('errors.amount.0'));
    }

    public function test_the_owner_may_switch_the_overdraft_block_off(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        TreasurySetting::current()->forceFill(['block_overdraft' => false])->save();
        $this->credit($headers, $employee, ['amount' => '100'])->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100']);

        // Assert
        $response->assertCreated();
        $this->assertSame('-100.00', $this->accountBalance($this->defaultCash()));
    }

    public function test_a_withdrawal_inside_the_locked_period_is_refused(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();
        $this->lockUntil(now()->subDay());

        // Act
        $response = $this->withdraw($headers, $employee, ['occurred_at' => now()->subDays(3)->toIso8601String()]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $this->assertSame('100.00', $this->balance($employee));
    }

    public function test_a_withdrawal_may_not_leave_from_custody(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->credit($headers, $employee)->assertCreated();
        $custody = TreasuryAccount::factory()->create(['kind' => AccountKind::Custody, 'is_default' => false]);

        // Act
        $response = $this->withdraw($headers, $employee, ['treasury_account_id' => $custody->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame('2000.00', $this->balance($employee));
    }

    public function test_a_stopped_employee_still_gets_their_money(): void
    {
        // Arrange — إيقاف الحساب لا يمسّ الرصيد، ويبقى صرفه ممكناً.
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();
        $employee->update(['is_active' => false]);

        // Act
        $response = $this->withdraw($headers, $employee, ['amount' => '100']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.balance', '0.00');
        $this->artisan('wallets:check')->assertSuccessful();
    }

    // ── التعديل ──────────────────────────────────────────────────────────────────────────

    public function test_an_adjustment_moves_the_debt_and_no_money(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->adjust($this->manager(), $employee, ['amount' => '75', 'reason' => 'رصيد افتتاحي']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم تعديل الرصيد')
            ->assertJsonPath('data.entry.type', 'adjustment_credit')
            ->assertJsonPath('data.entry.direction', 'in')
            ->assertJsonPath('data.entry.notes', 'رصيد افتتاحي')
            ->assertJsonPath('data.balance', '75.00');
        $this->assertSame('-75.00', $this->accountBalance($this->walletsPayable()));
        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_debit_adjustment_takes_the_debt_back(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->adjust($headers, $employee, ['amount' => '75'])->assertCreated();

        // Act
        $response = $this->adjust($headers, $employee, ['direction' => 'debit', 'amount' => '25']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.entry.type', 'adjustment_debit')
            ->assertJsonPath('data.entry.direction', 'out')
            ->assertJsonPath('data.balance', '50.00');
        $this->assertSame('-50.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_debit_adjustment_never_takes_the_wallet_below_zero(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->adjust($headers, $employee, ['amount' => '10'])->assertCreated();

        // Act
        $response = $this->adjust($headers, $employee, ['direction' => 'debit', 'amount' => '10.01']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('10.00', $this->balance($employee));
    }

    /**
     * @return array<string, array{array<string, mixed>, string}>
     */
    public static function badAdjustments(): array
    {
        return [
            'no reason' => [['reason' => null], 'reason'],
            'long reason' => [['reason' => str_repeat('م', 1001)], 'reason'],
            'no direction' => [['direction' => null], 'direction'],
            'unknown direction' => [['direction' => 'sideways'], 'direction'],
            'zero' => [['amount' => '0'], 'amount'],
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    #[DataProvider('badAdjustments')]
    public function test_a_malformed_adjustment_is_refused(array $payload, string $field): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $response = $this->adjust($this->manager(), $employee, $payload);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors($field);
    }

    // ── الضغطة المكررة ───────────────────────────────────────────────────────────────────

    /**
     * @return array<string, array{string}>
     */
    public static function everyWrite(): array
    {
        return [
            'deposit' => ['deposit'],
            'credit' => ['credit'],
            'withdrawal' => ['withdraw'],
            'adjustment' => ['adjust'],
        ];
    }

    #[DataProvider('everyWrite')]
    public function test_a_retry_with_the_same_token_writes_nothing(string $write): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '500'])->assertCreated();
        $rowsBefore = EmployeeWalletEntry::query()->count();
        $payload = ['client_token' => '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d'];
        $first = $this->{$write}($headers, $employee, $payload)->assertCreated();
        $balanceAfterFirst = $this->balance($employee);

        // Act
        $second = $this->{$write}($headers, $employee, $payload);

        // Assert
        $second->assertOk()
            ->assertJsonPath('message', 'هذه الحركة مسجَّلة من قبل')
            ->assertJsonPath('data.entry.id', $first->json('data.entry.id'));
        $this->assertSame($rowsBefore + 1, EmployeeWalletEntry::query()->count());
        $this->assertSame($balanceAfterFirst, $this->balance($employee));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_token_spent_on_another_kind_of_row_is_refused(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $payload = ['client_token' => '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d'];
        $this->deposit($headers, $employee, ['amount' => '500', ...$payload])->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, $payload);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('client_token');
        $this->assertSame('500.00', $this->balance($employee));
    }

    public function test_the_same_token_on_another_wallet_is_another_request(): void
    {
        // Arrange
        $headers = $this->manager();
        $payload = ['client_token' => '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d'];
        $this->deposit($headers, User::factory()->create(), $payload)->assertCreated();
        $other = User::factory()->create();

        // Act
        $response = $this->deposit($headers, $other, $payload);

        // Assert
        $response->assertCreated();
        $this->assertSame('100.00', $this->balance($other));
    }

    // ── السطر نفسه ───────────────────────────────────────────────────────────────────────

    public function test_a_row_cannot_be_edited(): void
    {
        // Arrange
        $entry = EmployeeWalletEntry::factory()->create();

        // Act
        $edit = fn () => $entry->forceFill(['amount' => '1.00'])->save();

        // Assert
        $this->assertThrows($edit, EmployeeWalletEntryIsImmutable::class);
    }

    public function test_a_row_cannot_be_deleted(): void
    {
        // Arrange
        $entry = EmployeeWalletEntry::factory()->create();

        // Act
        $delete = fn () => $entry->delete();

        // Assert
        $this->assertThrows($delete, EmployeeWalletEntryIsImmutable::class);
        $this->assertSame(1, EmployeeWalletEntry::query()->count());
    }

    public function test_the_columns_a_person_must_not_choose_are_never_fillable(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $intruder = User::factory()->create();

        // Act
        $response = $this->deposit($this->manager(), $employee, [
            'user_id' => $intruder->id,
            'type' => EmployeeWalletEntryType::Credit->value,
            'recorded_by' => $intruder->id,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.entry.user_id', $employee->id);
        $entry = EmployeeWalletEntry::query()->firstOrFail();
        $this->assertSame(EmployeeWalletEntryType::Deposit, $entry->type);
        $this->assertNotSame($intruder->id, $entry->recorded_by);
    }

    // ── الإشعار ──────────────────────────────────────────────────────────────────────────

    public function test_the_employee_hears_about_a_move_on_their_wallet(): void
    {
        // Arrange
        $employee = User::factory()->create();

        // Act
        $this->deposit($this->manager(), $employee, ['amount' => '150'])->assertCreated();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::EmployeeWalletMoved->value)->firstOrFail();
        $this->assertSame((int) $employee->id, (int) $notification->payload['employee_id']);
        $this->assertSame(1, $notification->recipients()->where('user_id', $employee->id)->count());
    }

    public function test_a_retry_tells_the_employee_nothing_new(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $payload = ['client_token' => '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d'];
        $this->deposit($headers, $employee, $payload)->assertCreated();

        // Act
        $this->deposit($headers, $employee, $payload)->assertOk();

        // Assert
        $this->assertSame(1, Notification::query()->where('type', NotificationType::EmployeeWalletMoved->value)->count());
    }

    public function test_the_notification_never_carries_the_amount(): void
    {
        // Arrange — الدفعُ يُقرأ على شاشةٍ مقفلة.
        $employee = User::factory()->create();

        // Act
        $this->deposit($this->manager(), $employee, ['amount' => '1234'])->assertCreated();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::EmployeeWalletMoved->value)->firstOrFail();
        $rendered = app(NotificationType::EmployeeWalletMoved->definition())->render($notification->payload);
        $this->assertStringNotContainsString('1234', $rendered->title.$rendered->body);
        $this->assertSame('/my-wallet', $rendered->route);
    }
}
