<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * التزامن مع الخزينة — EMPLOYEE-WALLET-DESIGN §٤.
 *
 * **حسابُ «أرصدة محافظ الموظفين» لا يحرّكه إلا المحافظ.** أيُّ بابٍ آخر يفصله عنها، فيقول الدفترُ رقماً
 * والمحافظُ رقماً غيره. وهذه الاختبارات تقف عند كل بابٍ من أبواب شاشة الحسابات.
 */
class EmployeeWalletTreasuryTest extends EmployeeWalletTestCase
{
    public function test_the_payable_opens_itself_as_a_debt_of_the_system(): void
    {
        // Act
        $payable = $this->walletsPayable();

        // Assert
        $this->assertSame('أرصدة محافظ الموظفين', $payable->name);
        $this->assertSame(AccountKind::Payable, $payable->kind);
        $this->assertSame(TreasuryAccount::EMPLOYEE_WALLETS, $payable->system_code);
        $this->assertTrue($payable->isEmployeeWalletsPayable());
    }

    public function test_the_payable_opens_once(): void
    {
        // Arrange
        $treasury = app(TreasuryService::class);

        // Act
        $first = $treasury->employeeWalletsPayable();
        $second = $treasury->employeeWalletsPayable();

        // Assert
        $this->assertSame($first->id, $second->id);
    }

    /**
     * @return array<string, array{array<string, mixed>}>
     */
    public static function handOperations(): array
    {
        return [
            'a transfer into it' => [['type' => 'transfer', 'from' => 'cash', 'to' => 'payable']],
            'a transfer out of it' => [['type' => 'transfer', 'from' => 'payable', 'to' => 'cash']],
            'an expense on it' => [['type' => 'expense', 'from' => 'payable']],
            'its count' => [['type' => 'adjustment', 'to' => 'payable', 'counted_balance' => '5']],
        ];
    }

    /**
     * @param  array<string, mixed>  $operation
     */
    #[DataProvider('handOperations')]
    public function test_the_payable_takes_no_hand_operation(array $operation): void
    {
        // Arrange
        $payable = $this->walletsPayable();
        $cash = $this->defaultCash();
        $accounts = ['cash' => $cash->id, 'payable' => $payable->id];
        $headers = $this->auth([
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
        ]);
        $category = $this->salaryCategory();

        // Act
        $response = $this->send($headers, 'treasury/operations', array_filter([
            'type' => $operation['type'],
            'amount' => '10',
            'from_account_id' => isset($operation['from']) ? $accounts[$operation['from']] : null,
            'to_account_id' => isset($operation['to']) ? $accounts[$operation['to']] : null,
            'category_id' => $operation['type'] === 'expense' ? $category->id : null,
            'counted_balance' => $operation['counted_balance'] ?? null,
            'notes' => 'تجربة',
        ]));

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('0.00', $this->accountBalance($payable));
    }

    public function test_a_wallet_expense_is_never_typed_by_hand(): void
    {
        // Arrange
        $headers = $this->auth([PermissionName::RecordTreasuryOperations]);

        // Act
        $response = $this->send($headers, 'treasury/operations', [
            'type' => OperationType::WalletExpense->value,
            'amount' => '10',
            'from_account_id' => $this->walletsPayable()->id,
            'category_id' => $this->salaryCategory()->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('type');
    }

    public function test_the_treasury_cannot_reverse_a_credit_by_hand(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->credit($this->manager(), $employee, ['amount' => '2000'])->assertCreated();
        $operation = TreasuryOperation::query()->firstOrFail();
        $headers = $this->auth([PermissionName::ViewTreasury, PermissionName::ReverseTreasuryOperations]);

        // Act
        $response = $this->send($headers, "treasury/operations/{$operation->id}/reverse", ['reason' => 'تجربة']);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('2000.00', $this->balance($employee));
        $this->assertSame('-2000.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_credit_operation_says_it_cannot_be_reversed_here(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $this->credit($this->manager(), $employee)->assertCreated();
        $headers = $this->auth([PermissionName::ViewTreasury, PermissionName::ReverseTreasuryOperations]);

        // Act
        $response = $this->read($headers, 'treasury/operations');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.type', OperationType::WalletExpense->value)
            ->assertJsonPath('data.0.is_reversible', false);
    }

    public function test_the_payable_is_no_place_for_a_purchase_cost(): void
    {
        // Arrange
        $payable = $this->walletsPayable();
        $treasury = app(TreasuryService::class);

        // Act
        $charge = fn () => $treasury->expenseAccount((int) $payable->id);

        // Assert
        $this->assertThrows($charge, AccountDoesNotFitMethod::class);
    }

    public function test_the_customer_wallets_payable_is_no_place_for_a_purchase_cost_either(): void
    {
        // Arrange — الثغرة الأولى في EMPLOYEE-WALLET-DESIGN §٤.
        $treasury = app(TreasuryService::class);
        $payable = $treasury->customerWalletsPayable();

        // Act
        $charge = fn () => $treasury->expenseAccount((int) $payable->id);

        // Assert
        $this->assertThrows($charge, AccountDoesNotFitMethod::class);
    }

    public function test_nobody_picks_the_payable_on_a_payment_form(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->credit($headers, $employee)->assertCreated();

        // Act
        $response = $this->withdraw($headers, $employee, ['treasury_account_id' => $this->walletsPayable()->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
    }

    public function test_the_payable_cannot_be_switched_off(): void
    {
        // Arrange
        $payable = $this->walletsPayable();
        $headers = $this->auth([PermissionName::ViewTreasury, PermissionName::ManageTreasury]);
        $this->app->get('auth')->forgetGuards();

        // Act
        $response = $this->withHeaders($headers)->putJson("/api/v1/treasury/accounts/{$payable->id}", [
            'name' => (string) $payable->name,
            'is_active' => false,
        ]);

        // Assert
        $response->assertUnprocessable();
        $this->assertTrue($payable->refresh()->is_active);
    }

    public function test_what_the_company_owes_its_employees_comes_off_its_own_money(): void
    {
        // Arrange — سلّم الموظف ٣٠٠ كاشاً، وله ٢٠٠ مستحقة.
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '300'])->assertCreated();
        $this->credit($headers, $employee, ['amount' => '200'])->assertCreated();
        $viewer = $this->auth([PermissionName::ViewTreasury]);

        // Act
        $response = $this->read($viewer, 'treasury/ownership');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.total_held', '300.00')
            ->assertJsonPath('data.payables_total', '500.00')
            ->assertJsonPath('data.company_own', '-200.00');
    }

    public function test_the_expense_categories_open_for_whoever_may_credit(): void
    {
        // Arrange
        $headers = $this->auth([PermissionName::CreditEmployeeWallets]);
        $stranger = $this->auth([PermissionName::ViewEmployeeWallets]);

        // Act
        $allowed = $this->read($headers, 'treasury/expense-categories?active_only=1');
        $refused = $this->read($stranger, 'treasury/expense-categories');

        // Assert
        $allowed->assertOk();
        $codes = array_column($allowed->json('data'), 'code');
        $this->assertContains('salary', $codes);
        $refused->assertForbidden();
    }

    // ── wallets:check ────────────────────────────────────────────────────────────────────

    public function test_the_check_finds_a_gap_between_the_wallets_and_their_payable(): void
    {
        // Arrange — حركةٌ على الحساب لا سطر محفظة خلفها.
        $employee = User::factory()->create();
        $this->deposit($this->manager(), $employee)->assertCreated();
        app(TreasuryService::class)->post(new MovementData(
            accountId: (int) $this->walletsPayable()->id,
            direction: MovementDirection::Out,
            kind: MovementKind::EmployeeWalletAdjustment,
            amount: '5.00',
            occurredAt: now(),
            sourceType: 'employee_wallet_entry',
            sourceId: 999999,
        ));

        // Act
        $check = $this->artisan('wallets:check');

        // Assert
        $check->assertFailed();
    }

    public function test_the_check_finds_a_wallet_below_zero(): void
    {
        // Arrange — لا طريق يصنع هذا، والأمر موجودٌ ليكتشفه إن صُنع.
        $employee = User::factory()->create();
        EmployeeWalletEntry::factory()->for($employee, 'employee')->debit()->create(['amount' => '5.00']);
        app(TreasuryService::class)->post(new MovementData(
            accountId: (int) $this->walletsPayable()->id,
            direction: MovementDirection::In,
            kind: MovementKind::EmployeeWalletAdjustment,
            amount: '5.00',
            occurredAt: now(),
            sourceType: 'employee_wallet_entry',
            sourceId: 999998,
        ));

        // Act
        $check = $this->artisan('wallets:check');

        // Assert
        $check->assertFailed();
    }

    public function test_the_check_still_watches_the_customer_wallets_on_its_own(): void
    {
        // Arrange — محافظ الموظفين سليمة، وحساب محافظ الزبائن ناقص.
        $this->deposit($this->manager(), User::factory()->create())->assertCreated();
        $treasury = app(TreasuryService::class);
        $treasury->post(new MovementData(
            accountId: (int) $treasury->customerWalletsPayable()->id,
            direction: MovementDirection::Out,
            kind: MovementKind::WalletAdjustment,
            amount: '5.00',
            occurredAt: now(),
            sourceType: 'customer_wallet_entry',
            sourceId: 999999,
        ));

        // Act
        $check = $this->artisan('wallets:check');

        // Assert
        $check->assertFailed();
    }

    public function test_a_reversal_by_the_wallet_passes_where_a_hand_one_stops(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->credit($headers, $employee)->json('data.entry.id');
        $operation = TreasuryOperation::query()->firstOrFail();
        $treasury = app(TreasuryService::class);

        // Act
        $byHand = fn () => $treasury->reverseOperation($operation, 'تجربة', null);
        $byWallet = $this->reverse($headers, $id);

        // Assert
        $this->assertThrows($byHand, OperationRefused::class);
        $byWallet->assertCreated();
    }
}
