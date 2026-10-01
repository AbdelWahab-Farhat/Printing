<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «علينا» opened by hand — a loan from the owner, rent due — TREASURY-DESIGN §٢٠.
 *
 * The balance of a payable runs below zero: −500 is 500 owed. Arrange - Act - Assert throughout.
 */
class PayableAccountTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @return array<string, string>
     */
    private function owner(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ManageTreasury,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function payable(array $headers, string $name = 'قرض المالك'): TreasuryAccount
    {
        $id = $this->postJson('/api/v1/treasury/accounts', ['name' => $name, 'kind' => 'payable'], $headers)
            ->assertCreated()
            ->json('data.id');

        return TreasuryAccount::query()->findOrFail($id);
    }

    private function cashBox(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', AccountKind::Cash->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $body
     */
    private function operation(array $headers, array $body): TestResponse
    {
        return $this->postJson('/api/v1/treasury/operations', $body, $headers);
    }

    public function test_a_payable_opens_as_a_debt_below_zero(): void
    {
        // Arrange
        $headers = $this->owner();
        $loan = $this->payable($headers);

        // Act
        $response = $this->operation($headers, ['type' => 'opening', 'to_account_id' => $loan->id, 'amount' => '1000']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.from_account_id', $loan->id)
            ->assertJsonPath('data.to_account_id', null);
        $this->assertSame('-1000.00', $this->balance($loan));
        $this->operation($headers, ['type' => 'opening', 'to_account_id' => $loan->id, 'amount' => '5'])
            ->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
    }

    public function test_borrowing_brings_cash_in_and_repaying_more_than_is_owed_is_refused(): void
    {
        // Arrange
        $headers = $this->owner();
        $loan = $this->payable($headers);

        // Act — borrow 1,000 into the cash box, then repay 400, then try 700
        $borrow = $this->operation($headers, [
            'type' => 'transfer', 'from_account_id' => $loan->id, 'to_account_id' => $this->cashBox()->id, 'amount' => '1000',
        ]);
        $repay = $this->operation($headers, [
            'type' => 'transfer', 'from_account_id' => $this->cashBox()->id, 'to_account_id' => $loan->id, 'amount' => '400',
        ]);
        $tooMuch = $this->operation($headers, [
            'type' => 'transfer', 'from_account_id' => $this->cashBox()->id, 'to_account_id' => $loan->id, 'amount' => '700',
        ]);

        // Assert
        $borrow->assertCreated();
        $repay->assertCreated();
        $tooMuch->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('-600.00', $this->balance($loan));
        $this->assertSame('600.00', $this->balance($this->cashBox()));
    }

    public function test_an_expense_bought_on_credit_deepens_the_debt_without_any_money(): void
    {
        // Arrange
        $headers = $this->owner();
        $landlord = $this->payable($headers, 'المؤجر');
        $rent = ExpenseCategory::query()->where('name', 'إيجار')->firstOrFail();

        // Act
        $response = $this->operation($headers, [
            'type' => 'expense', 'from_account_id' => $landlord->id, 'amount' => '2500', 'category_id' => $rent->id,
        ]);

        // Assert — refused by no overdraft guard: a debt has no money to run out of
        $response->assertCreated();
        $this->assertSame('-2500.00', $this->balance($landlord));
    }

    public function test_a_payable_takes_no_deposit_and_no_withdrawal(): void
    {
        // Arrange
        $headers = $this->owner();
        $loan = $this->payable($headers);

        // Act
        $deposit = $this->operation($headers, ['type' => 'deposit', 'to_account_id' => $loan->id, 'amount' => '10']);
        $withdrawal = $this->operation($headers, [
            'type' => 'withdrawal', 'from_account_id' => $loan->id, 'amount' => '10', 'notes' => 'تجربة',
        ]);

        // Assert
        $deposit->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $withdrawal->assertUnprocessable()->assertJsonValidationErrors('from_account_id');
    }

    public function test_a_count_on_a_payable_is_said_as_what_is_owed(): void
    {
        // Arrange — owed 500
        $headers = $this->owner();
        $loan = $this->payable($headers);
        $this->operation($headers, ['type' => 'opening', 'to_account_id' => $loan->id, 'amount' => '500'])->assertCreated();

        // Act — the statement says 300 is owed
        $response = $this->operation($headers, [
            'type' => 'adjustment', 'to_account_id' => $loan->id, 'counted_balance' => '300', 'notes' => 'كشف المالك',
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.amount', '200.00')
            ->assertJsonPath('data.to_account_id', $loan->id);
        $this->assertSame('-300.00', $this->balance($loan));
    }

    public function test_a_payable_cannot_be_a_default_and_no_payment_is_offered_it(): void
    {
        // Arrange
        $headers = $this->owner();
        $this->payable($headers);

        // Act
        $default = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'دين', 'kind' => 'payable', 'is_default' => true,
        ], $headers);
        $options = $this->getJson('/api/v1/treasury/account-options?method=cash', $headers);

        // Assert
        $default->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $options->assertOk();
        $this->assertNotContains('payable', array_column($options->json('data.accounts'), 'kind'));
    }

    public function test_what_is_owed_is_kept_out_of_the_money_and_off_the_company_s_own(): void
    {
        // Arrange — 1,000 borrowed into the cash box
        $headers = $this->owner();
        $loan = $this->payable($headers);
        $this->operation($headers, [
            'type' => 'transfer', 'from_account_id' => $loan->id, 'to_account_id' => $this->cashBox()->id, 'amount' => '1000',
        ])->assertCreated();

        // Act
        $accounts = $this->getJson('/api/v1/treasury/accounts', $headers);
        $ownership = $this->getJson('/api/v1/treasury/ownership', $headers);

        // Assert — the drawer holds 1,000 and none of it is the company's
        $accounts->assertOk()
            ->assertJsonPath('data.total', '1000.00')
            ->assertJsonPath('data.payables_total', '1000.00');
        $ownership->assertOk()
            ->assertJsonPath('data.total_held', '1000.00')
            ->assertJsonPath('data.payables_total', '1000.00')
            ->assertJsonPath('data.company_own', '0.00');
    }
}
