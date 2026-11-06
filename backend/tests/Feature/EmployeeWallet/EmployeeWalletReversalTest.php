<?php

declare(strict_types=1);

namespace Tests\Feature\EmployeeWallet;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\TreasuryOperation;

/**
 * العكس — كلُّ حركةٍ تُصحَّح بسطرٍ يشير إلى أصلها، والخزينةُ تعكس ما كتبته معها.
 */
class EmployeeWalletReversalTest extends EmployeeWalletTestCase
{
    public function test_reversing_a_deposit_takes_everything_back(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee, ['amount' => '100'])->json('data.entry.id');

        // Act
        $response = $this->reverse($headers, $id, 'كُتبت لموظفٍ آخر');

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم عكس الحركة')
            ->assertJsonPath('data.entry.type', 'reversal')
            ->assertJsonPath('data.entry.direction', 'out')
            ->assertJsonPath('data.entry.reverses_entry_id', $id)
            ->assertJsonPath('data.balance', '0.00');
        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('0.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_reversing_a_credit_takes_the_expense_back(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->credit($headers, $employee, ['amount' => '2000'])->json('data.entry.id');

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertCreated()->assertJsonPath('data.balance', '0.00');
        $this->assertSame('0.00', $this->accountBalance($this->walletsPayable()));
        $original = TreasuryOperation::query()->whereNull('reverses_operation_id')->firstOrFail();
        $this->assertTrue($original->isReversed());
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_reversed_credit_leaves_the_expenses_total(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->credit($headers, $employee, ['amount' => '2000'])->json('data.entry.id');
        $this->reverse($headers, $id)->assertCreated();
        $viewer = $this->auth([PermissionName::ViewTreasury]);

        // Act
        $response = $this->read($viewer, 'treasury/expenses');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.is_reversed', true)
            ->assertJsonPath('meta.expenses_total', '0.00');
    }

    public function test_reversing_a_withdrawal_gives_the_money_back(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();
        $id = (int) $this->withdraw($headers, $employee, ['amount' => '60'])->json('data.entry.id');

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.entry.direction', 'in')
            ->assertJsonPath('data.balance', '100.00');
        $this->assertSame('100.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('-100.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_reversing_an_adjustment_puts_the_debt_back(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $this->adjust($headers, $employee, ['amount' => '40'])->assertCreated();
        $id = (int) $this->adjust($headers, $employee, ['direction' => 'debit', 'amount' => '15'])->json('data.entry.id');

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertCreated()->assertJsonPath('data.balance', '40.00');
        $this->assertSame('-40.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_row_whose_money_left_cannot_be_reversed(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee, ['amount' => '100'])->json('data.entry.id');
        $this->withdraw($headers, $employee, ['amount' => '70'])->assertCreated();

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('status', false);
        $this->assertSame('30.00', $this->balance($employee));
        $this->assertSame(0, EmployeeWalletEntry::query()->where('type', EmployeeWalletEntryType::Reversal->value)->count());
    }

    public function test_a_row_is_reversed_once(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee, ['amount' => '100'])->json('data.entry.id');
        $this->deposit($headers, $employee, ['amount' => '100'])->assertCreated();
        $this->reverse($headers, $id)->assertCreated();

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('100.00', $this->balance($employee));
    }

    public function test_a_reversal_is_not_reversed(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee)->json('data.entry.id');
        $reversal = (int) $this->reverse($headers, $id)->json('data.entry.id');

        // Act
        $response = $this->reverse($headers, $reversal);

        // Assert
        $response->assertUnprocessable();
    }

    public function test_a_reversal_needs_a_reason(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee)->json('data.entry.id');

        // Act
        $response = $this->send($headers, "employee-wallet-entries/{$id}/reverse");

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('reason');
    }

    public function test_a_row_says_it_was_reversed_and_by_what(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $headers = $this->manager();
        $id = (int) $this->deposit($headers, $employee)->json('data.entry.id');
        $this->reverse($headers, $id, 'كُتبت لموظفٍ آخر')->assertCreated();

        // Act
        $response = $this->read($headers, "users/{$employee->id}/wallet/entries");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.1.id', $id)
            ->assertJsonPath('data.1.is_reversed', true)
            ->assertJsonPath('data.1.can_reverse', false)
            ->assertJsonPath('data.1.reversal.reason', 'كُتبت لموظفٍ آخر');
    }

    public function test_reversing_needs_its_own_grant(): void
    {
        // Arrange
        $employee = User::factory()->create();
        $id = (int) $this->deposit($this->manager(), $employee)->json('data.entry.id');
        $headers = $this->auth([PermissionName::ViewEmployeeWallets, PermissionName::DepositToEmployeeWallets]);

        // Act
        $response = $this->reverse($headers, $id);

        // Assert
        $response->assertForbidden();
        $this->assertSame('100.00', $this->balance($employee));
    }

    public function test_a_row_that_does_not_exist_is_a_404(): void
    {
        // Act
        $response = $this->reverse($this->manager(), 999999);

        // Assert
        $response->assertNotFound()->assertJsonPath('status', false);
    }
}
