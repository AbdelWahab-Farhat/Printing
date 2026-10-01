<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\ReverseWalletEntry;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Shortage\Models\Shortage;
use App\Domain\Shortage\Models\ShortageSupply;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The company's real money outside customer orders: shortages bought for cash, investors'
 * deposits and withdrawals, and what the fund spends — TREASURY-DESIGN §٧.
 *
 * Arrange - Act - Assert throughout.
 */
class OtherMoneyTreasuryTest extends TestCase
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
     * @param  list<PermissionName>  $permissions
     * @return array{0: User, 1: array<string, string>}
     */
    private function user(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    // ── shortages ───────────────────────────────────────────────────────────────────────

    public function test_a_shortage_bought_for_cash_comes_out_of_the_cash_box_and_goes_back_when_reversed(): void
    {
        // Arrange
        [, $headers] = $this->user([
            PermissionName::ViewShortages,
            PermissionName::RecordShortageSupplies,
            PermissionName::ReverseShortageSupplies,
        ]);
        $shortage = Shortage::factory()->create(['required_quantity' => '30.000']);

        // Act
        $bought = $this->postJson("/api/v1/shortages/{$shortage->id}/supplies", [
            'quantity' => '20', 'amount' => '500', 'method' => 'cash',
        ], $headers);

        // Assert
        $bought->assertCreated();
        $this->assertSame('-500.00', $this->balance($this->defaultOf(AccountKind::Cash)));

        // Act — the entry was typed twice
        $supply = ShortageSupply::query()->sole();
        $this->postJson("/api/v1/shortages/{$shortage->id}/supplies/{$supply->id}/reversal", [
            'reason' => 'مكرر',
        ], $headers)->assertCreated();

        // Assert
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_a_shortage_paid_by_transfer_comes_out_of_the_bank(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ViewShortages, PermissionName::RecordShortageSupplies]);
        $shortage = Shortage::factory()->create(['required_quantity' => '10.000']);

        // Act
        $this->postJson("/api/v1/shortages/{$shortage->id}/supplies", [
            'quantity' => '10', 'amount' => '260', 'method' => 'bank_transfer',
        ], $headers)->assertCreated();

        // Assert
        $this->assertSame('-260.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('supply_purchase', TreasuryMovement::query()->sole()->kind->value);
    }

    // ── investors ───────────────────────────────────────────────────────────────────────

    public function test_an_investor_s_deposit_lands_and_a_withdrawal_leaves_but_an_allocation_moves_nothing(): void
    {
        // Arrange
        [, $headers] = $this->user([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $investor = Investor::factory()->create();
        $bank = $this->defaultOf(AccountKind::Bank);

        // Act
        $this->postJson("/api/v1/investors/{$investor->id}/wallet", [
            'type' => 'deposit', 'amount' => '10000', 'method' => 'bank_transfer',
        ], $headers)->assertCreated();

        // من المصرف الذي فيه المال: السحبُ باليد لا يأخذ ما ليس في الدرج، والخزنةُ هنا فارغة.
        $this->postJson("/api/v1/investors/{$investor->id}/wallet", [
            'type' => 'withdrawal', 'amount' => '1500', 'method' => 'bank_transfer',
        ], $headers)->assertCreated();

        // Assert
        $this->assertSame('8500.00', $this->balance($bank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame(2, TreasuryMovement::query()->count());
    }

    public function test_reversing_an_investor_s_deposit_takes_it_back_out_of_its_account(): void
    {
        // Arrange
        [$user, $headers] = $this->user([PermissionName::ViewInvestors, PermissionName::RecordInvestorMoney]);
        $investor = Investor::factory()->create();
        $this->postJson("/api/v1/investors/{$investor->id}/wallet", [
            'type' => 'deposit', 'amount' => '2000', 'method' => 'cash',
        ], $headers)->assertCreated();
        $deposit = InvestorWalletEntry::query()->where('investor_id', $investor->id)->sole();

        // Act
        app(ReverseWalletEntry::class)($deposit, (int) $user->id, 'إيداع وهمي');

        // Assert
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_a_fund_expense_is_paid_from_the_cash_box_or_the_drawer_named(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::RecordDealExpenses, PermissionName::ViewInvestors]);
        $bank = $this->defaultOf(AccountKind::Bank);

        // Act
        $fromCash = $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping', 'name' => 'نقل', 'amount' => '120', 'incurred_on' => now()->toDateString(),
        ], $headers);

        $fromBank = $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'customs', 'name' => 'جمارك', 'amount' => '300', 'incurred_on' => now()->toDateString(),
            'treasury_account_id' => $bank->id,
        ], $headers);

        // Assert
        $fromCash->assertOk();
        $fromBank->assertOk();
        $this->assertSame('-120.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('-300.00', $this->balance($bank));
    }

    public function test_a_fund_expense_cannot_name_a_deleted_account(): void
    {
        // Arrange — حسابٌ محذوفٌ حذفاً ناعماً لا يظهر في أيّ منتقٍ، ولا يُقبل باسمه مصروف.
        [, $headers] = $this->user([
            PermissionName::RecordDealExpenses,
            PermissionName::ViewInvestors,
        ]);
        $closed = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();
        $closed->delete();

        // Act
        $response = $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'customs',
            'name' => 'جمارك',
            'amount' => '300',
            'incurred_on' => now()->toDateString(),
            'treasury_account_id' => $closed->id,
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame(0, TreasuryMovement::query()->count());
    }
}
