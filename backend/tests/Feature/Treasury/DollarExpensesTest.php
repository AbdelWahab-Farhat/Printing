<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * An expense out of a dollar account — USD-ACCOUNTS.md §٨, phase 5. In dollars as it left, with a
 * rate; «المصاريف» adds its dinars, and says the dollars beside them.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarExpensesTest extends TestCase
{
    use RefreshDatabase;

    /** @var array<string, string> */
    private array $headers;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ReverseTreasuryOperations,
            PermissionName::ManageTreasury,
        ]));

        $this->headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function account(string $currency, string $holding): TreasuryAccount
    {
        $id = $this->postJson('/api/v1/treasury/accounts', [
            'name' => "حساب {$currency}",
            'kind' => 'cash',
            'currency' => $currency,
        ], $this->headers)->assertCreated()->json('data.id');

        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $id,
            'amount' => $holding,
        ], $this->headers)->assertCreated();

        return TreasuryAccount::query()->findOrFail($id);
    }

    /** @param  array<string, mixed>  $extra */
    private function expense(TreasuryAccount $from, string $amount, array $extra = []): TestResponse
    {
        $category = ExpenseCategory::query()->whereNull('code')->where('requires_employee', false)->firstOrFail();

        return $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense',
            'from_account_id' => $from->id,
            'amount' => $amount,
            'category_id' => $category->id,
        ] + $extra, $this->headers);
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account->refresh());
    }

    public function test_a_dollar_expense_leaves_in_dollars_and_keeps_its_dinars(): void
    {
        // Arrange
        $usd = $this->account('USD', '500');

        // Act
        $response = $this->expense($usd, '40', ['rate' => '7.15']);

        // Assert — $40 out of the box; 286 dinars on the operation and on the line.
        $response->assertCreated();
        $this->assertSame('460.00', $this->balance($usd));
        $operation = TreasuryOperation::query()->findOrFail($response->json('data.id'));
        $this->assertSame('40.00', (string) $operation->amount);
        $this->assertSame('286.00', (string) $operation->counter_amount);
        $this->assertSame('7.1500', (string) $operation->rate);
        $this->assertSame('286.00', (string) TreasuryMovement::query()->where('operation_id', $operation->id)->value('dinar_amount'));
    }

    public function test_the_expenses_tab_adds_dinars_and_says_the_dollars_beside_them(): void
    {
        // Arrange — 100 dinars, and $40 at 7.
        $lyd = $this->account('LYD', '1000');
        $usd = $this->account('USD', '500');
        $this->expense($lyd, '100')->assertCreated();
        $this->expense($usd, '40', ['rate' => '7'])->assertCreated();

        // Act
        $response = $this->getJson('/api/v1/treasury/expenses', $this->headers);

        // Assert — 100 + 280, never 100 + 40.
        $response->assertOk()
            ->assertJsonPath('meta.expenses_total', '380.00')
            ->assertJsonPath('meta.expenses_usd_total', '40.00');
        $line = collect($response->json('data'))->firstWhere('account.currency', 'USD');
        $this->assertSame('40.00', $line['amount']);
        $this->assertSame('280.00', $line['dinar_amount']);
    }

    public function test_a_dinar_expense_takes_no_rate(): void
    {
        // Arrange
        $lyd = $this->account('LYD', '1000');

        // Act
        $response = $this->expense($lyd, '100', ['rate' => '7']);

        // Assert
        $response->assertCreated();
        $operation = TreasuryOperation::query()->findOrFail($response->json('data.id'));
        $this->assertNull($operation->counter_amount);
        $this->assertNull(TreasuryMovement::query()->where('operation_id', $operation->id)->value('dinar_amount'));
    }

    public function test_reversing_a_dollar_expense_takes_its_dinars_out_of_the_total(): void
    {
        // Arrange
        $usd = $this->account('USD', '500');
        $id = $this->expense($usd, '40', ['rate' => '7'])->json('data.id');

        // Act
        $this->postJson("/api/v1/treasury/operations/{$id}/reverse", ['reason' => 'سُجّل خطأً'], $this->headers)
            ->assertSuccessful();

        // Assert
        $this->assertSame('500.00', $this->balance($usd));
        $this->getJson('/api/v1/treasury/expenses', $this->headers)
            ->assertJsonPath('meta.expenses_total', '0.00')
            ->assertJsonPath('meta.expenses_usd_total', '0.00');
        $this->assertSame('280.00', (string) TreasuryMovement::query()->whereNotNull('reverses_movement_id')->value('dinar_amount'));
    }

    public function test_a_dollar_expense_cannot_overdraw_its_drawer(): void
    {
        // Arrange
        $usd = $this->account('USD', '30');

        // Act
        $response = $this->expense($usd, '40', ['rate' => '7']);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('30.00', $this->balance($usd));
    }
}
