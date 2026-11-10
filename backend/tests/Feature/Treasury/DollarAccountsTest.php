<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Actions\PostMovement;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use InvalidArgumentException;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Dollar accounts and «صرف عملة» — USD-ACCOUNTS.md §٣, phase 1.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarAccountsTest extends TestCase
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
     * @return array{0: User, 1: array<string, string>}
     */
    private function owner(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ReverseTreasuryOperations,
            PermissionName::ManageTreasury,
        ]));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function cashBox(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function dollarAccount(array $headers, string $kind = 'cash', array $extra = []): TreasuryAccount
    {
        $id = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'خزنة الدولار',
            'kind' => $kind,
            'currency' => 'USD',
        ] + $extra, $headers)->assertCreated()->json('data.id');

        return TreasuryAccount::query()->findOrFail($id);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function deposit(array $headers, TreasuryAccount $account, string $amount): void
    {
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $account->id,
            'amount' => $amount,
        ], $headers)->assertCreated();
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $figures
     */
    private function exchange(array $headers, TreasuryAccount $from, TreasuryAccount $to, array $figures): TestResponse
    {
        return $this->postJson('/api/v1/treasury/operations', [
            'type' => 'exchange',
            'from_account_id' => $from->id,
            'to_account_id' => $to->id,
        ] + $figures, $headers);
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    // ── the account ─────────────────────────────────────────────────────────────────────

    public function test_a_cash_box_or_a_bank_can_be_opened_in_dollars(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $cash = $this->dollarAccount($headers);
        $bank = $this->dollarAccount($headers, 'bank');

        // Assert
        $this->assertSame(Currency::Usd, $cash->currency);
        $this->assertSame(Currency::Usd, $bank->currency);
        $this->getJson("/api/v1/treasury/accounts/{$cash->id}", $headers)->assertJsonPath('data.account.currency', 'USD');
    }

    public function test_an_account_opened_without_a_currency_is_in_dinars(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $id = $this->postJson('/api/v1/treasury/accounts', ['name' => 'مصرف ثانٍ', 'kind' => 'bank'], $headers)
            ->assertCreated()->json('data.id');

        // Assert
        $this->assertSame(Currency::Lyd, TreasuryAccount::query()->findOrFail($id)->currency);
    }

    public function test_dollars_cannot_sit_in_libyana_custody_or_a_payable(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act / Assert
        foreach (['wallet', 'custody', 'payable'] as $kind) {
            $this->postJson('/api/v1/treasury/accounts', ['name' => "دولار {$kind}", 'kind' => $kind, 'currency' => 'USD'], $headers)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('currency');
        }
    }

    public function test_a_dollar_account_is_never_a_default_nor_a_branch_s_box(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $asDefault = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'دولار', 'kind' => 'cash', 'currency' => 'USD', 'is_default' => true,
        ], $headers);
        $existing = $this->dollarAccount($headers);
        $madeDefault = $this->putJson("/api/v1/treasury/accounts/{$existing->id}", ['is_default' => true], $headers);

        // Assert
        $asDefault->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $madeDefault->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $this->assertFalse($existing->fresh()->is_default);
    }

    public function test_the_table_refuses_a_dollar_wallet_however_it_is_written(): void
    {
        // Arrange
        $wallet = TreasuryAccount::query()->where('kind', 'wallet')->where('is_default', false)->first()
            ?? TreasuryAccount::factory()->create(['kind' => 'wallet']);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('treasury_accounts')->where('id', $wallet->id)->update(['currency' => 'USD']);
    }

    public function test_the_currency_changes_only_before_the_account_has_moved(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $mistake = $this->dollarAccount($headers);
        $used = $this->dollarAccount($headers, 'bank');
        $this->deposit($headers, $used, '100');

        // Act
        $fixed = $this->putJson("/api/v1/treasury/accounts/{$mistake->id}", ['currency' => 'LYD'], $headers);
        $refused = $this->putJson("/api/v1/treasury/accounts/{$used->id}", ['currency' => 'LYD'], $headers);

        // Assert
        $fixed->assertOk()->assertJsonPath('data.currency', 'LYD');
        $refused->assertUnprocessable()->assertJsonValidationErrors('currency');
        $this->assertSame(Currency::Usd, $used->fresh()->currency);
    }

    // ── what a person does to it by hand ────────────────────────────────────────────────

    public function test_a_dollar_account_takes_a_deposit_a_withdrawal_and_a_count_in_dollars(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);

        // Act
        $this->deposit($headers, $usd, '1000');
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal', 'from_account_id' => $usd->id, 'amount' => '200', 'notes' => 'سفر',
        ], $headers)->assertCreated();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment', 'to_account_id' => $usd->id, 'counted_balance' => '790', 'notes' => 'عدّ',
        ], $headers)->assertCreated();

        // Assert
        $this->assertSame('790.00', $this->balance($usd));
    }

    public function test_a_transfer_between_currencies_is_refused_and_points_to_the_exchange(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '5000');

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer', 'from_account_id' => $this->cashBox()->id, 'to_account_id' => $usd->id, 'amount' => '1000',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $this->assertSame('0.00', $this->balance($usd));
    }

    public function test_a_transfer_between_two_dollar_accounts_moves_dollars(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $box = $this->dollarAccount($headers);
        $bank = $this->dollarAccount($headers, 'bank');
        $this->deposit($headers, $box, '500');

        // Act
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer', 'from_account_id' => $box->id, 'to_account_id' => $bank->id, 'amount' => '300',
        ], $headers)->assertCreated();

        // Assert
        $this->assertSame('200.00', $this->balance($box));
        $this->assertSame('300.00', $this->balance($bank));
    }

    public function test_an_expense_from_dollars_asks_for_its_rate(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $usd, '500');
        $category = ExpenseCategory::query()->whereNull('code')->where('requires_employee', false)->firstOrFail();

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'expense', 'from_account_id' => $usd->id, 'amount' => '50', 'category_id' => $category->id,
        ], $headers);

        // Assert — «المصاريف» adds dinars, so a dollar expense needs the rate it is counted at.
        $response->assertUnprocessable()->assertJsonValidationErrors('rate');
        $this->assertSame('500.00', $this->balance($usd));
    }

    // ── «صرف عملة» ───────────────────────────────────────────────────────────────────────

    public function test_buying_dollars_with_both_amounts_works_out_the_rate(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.amount', '7150.00')
            ->assertJsonPath('data.counter_amount', '1000.00')
            ->assertJsonPath('data.rate', '7.1500');
        $this->assertSame('2850.00', $this->balance($this->cashBox()));
        $this->assertSame('1000.00', $this->balance($usd));
    }

    public function test_dinars_and_a_rate_work_out_the_dollars(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7300', 'rate' => '7.3']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.counter_amount', '1000.00');
        $this->assertSame('1000.00', $this->balance($usd));
    }

    public function test_dollars_and_a_rate_work_out_the_dinars_and_the_rate_is_kept_as_typed(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $usd, ['counter_amount' => '333', 'rate' => '7.1537']);

        // Assert — 333 × 7.1537 = 2382.1821, rounded to the dirham
        $response->assertCreated()
            ->assertJsonPath('data.amount', '2382.18')
            ->assertJsonPath('data.rate', '7.1537');
        $this->assertSame('7617.82', $this->balance($this->cashBox()));
    }

    public function test_selling_dollars_turns_the_figures_around(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $usd, '500');

        // Act — $200 out, at 7.2 dinars each
        $response = $this->exchange($headers, $usd, $this->cashBox(), ['amount' => '200', 'rate' => '7.2']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.counter_amount', '1440.00');
        $this->assertSame('300.00', $this->balance($usd));
        $this->assertSame('1440.00', $this->balance($this->cashBox()));
    }

    public function test_three_figures_that_disagree_or_a_single_one_are_refused(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $disagree = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000', 'rate' => '7.5']);
        $alone = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150']);

        // Assert
        $disagree->assertUnprocessable()->assertJsonValidationErrors('counter_amount');
        $alone->assertUnprocessable()->assertJsonValidationErrors('counter_amount');
        $this->assertSame(0, TreasuryOperation::query()->where('type', 'exchange')->count());
    }

    public function test_three_figures_agree_when_the_rate_was_rounded_from_the_two_amounts(): void
    {
        // Arrange — 7000 / 977 = 7.16479…, which the app sends rounded
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7000', 'counter_amount' => '977', 'rate' => '7.1648']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.amount', '7000.00')->assertJsonPath('data.counter_amount', '977.00');
    }

    public function test_an_exchange_between_two_dinar_accounts_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $bank = TreasuryAccount::query()->where('kind', 'bank')->where('is_default', true)->firstOrFail();
        $this->deposit($headers, $this->cashBox(), '1000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $bank, ['amount' => '700', 'counter_amount' => '100']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
    }

    public function test_an_exchange_cannot_spend_dinars_the_box_does_not_hold(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '1000');

        // Act
        $response = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000']);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('0.00', $this->balance($usd));
    }

    public function test_reversing_an_exchange_puts_both_currencies_back(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');
        $id = $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000'])->json('data.id');

        // Act
        $reversal = $this->postJson("/api/v1/treasury/operations/{$id}/reverse", ['reason' => 'خطأ'], $headers);

        // Assert
        $reversal->assertCreated()->assertJsonPath('data.counter_amount', '1000.00');
        $this->assertSame('10000.00', $this->balance($this->cashBox()));
        $this->assertSame('0.00', $this->balance($usd));
    }

    public function test_each_side_of_an_exchange_is_written_in_its_own_currency_in_the_ledger(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');

        // Act
        $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000'])->assertCreated();

        // Assert
        $this->getJson("/api/v1/treasury/accounts/{$usd->id}/movements?kind=exchange", $headers)
            ->assertJsonPath('data.0.amount', '1000.00')
            ->assertJsonPath('data.0.kind', 'exchange');
        $this->getJson("/api/v1/treasury/accounts/{$this->cashBox()->id}/movements?kind=exchange", $headers)
            ->assertJsonPath('data.0.amount', '7150.00');
    }

    // ── no dinar path reaches a dollar account ──────────────────────────────────────────

    public function test_no_payment_form_offers_a_dollar_account(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $usdBank = $this->dollarAccount($headers, 'bank');

        // Act
        $cash = $this->getJson('/api/v1/treasury/account-options?method=cash', $headers)->json('data.accounts');
        $bank = $this->getJson('/api/v1/treasury/account-options?method=bank_transfer&purpose=out', $headers)->json('data.accounts');
        $pickable = app(TreasuryService::class)->pickableAccounts();

        // Assert
        $this->assertNotContains($usd->id, array_column($cash, 'id'));
        $this->assertNotContains($usdBank->id, array_column($bank, 'id'));
        $this->assertNotContains((string) $usd->id, array_column($pickable, 'value'));
    }

    public function test_a_dollar_account_sent_by_hand_for_dinars_is_refused(): void
    {
        // Arrange
        [$user, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);

        // Assert
        $this->expectException(AccountDoesNotFitMethod::class);

        // Act
        app(TreasuryService::class)->accountFor('cash', (int) $user->id, (int) $usd->id, incoming: true);
    }

    public function test_a_person_s_only_account_in_dollars_is_not_where_their_dinars_land(): void
    {
        // Arrange
        [$user, $headers] = $this->owner();
        $this->dollarAccount($headers, 'cash', ['holder_user_id' => $user->id]);

        // Act
        $landed = app(TreasuryService::class)->accountFor('cash', (int) $user->id, null, incoming: true);

        // Assert
        $this->assertTrue($landed->is($this->cashBox()));
    }

    public function test_a_drawer_picked_for_a_cost_or_a_deal_cannot_be_dollars(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $treasury = app(TreasuryService::class);

        // Act / Assert
        foreach ([fn () => $treasury->spendableAccount((int) $usd->id), fn () => $treasury->expenseAccount((int) $usd->id)] as $pick) {
            try {
                $pick();
                $this->fail('A dollar account was accepted for dinars.');
            } catch (AccountDoesNotFitMethod) {
                $this->addToAssertionCount(1);
            }
        }
    }

    public function test_custody_cannot_settle_into_dollars_nor_a_kind_collect_into_them(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);

        // Act
        $settles = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'عهدة مندوب', 'kind' => 'custody', 'settles_into_account_id' => $usd->id,
        ], $headers);
        $collects = $this->putJson('/api/v1/treasury/settings', [
            'collect_cash' => true, 'collect_cash_into_id' => $usd->id,
        ], $headers);

        // Assert
        $settles->assertUnprocessable();
        $collects->assertUnprocessable()->assertJsonValidationErrors('collect_cash_into_id');
    }

    public function test_the_ledger_refuses_a_customer_payment_written_onto_dollars(): void
    {
        // Arrange — a caller that forgot to refuse it
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);

        // Assert
        $this->expectException(InvalidArgumentException::class);

        // Act
        app(PostMovement::class)(new MovementData(
            accountId: (int) $usd->id,
            direction: MovementDirection::In,
            kind: MovementKind::Payment,
            amount: '500',
            occurredAt: now(),
            sourceType: 'order_payment',
            sourceId: 1,
        ));
    }

    // ── «سعر النظام» and the totals ──────────────────────────────────────────────────────

    public function test_the_owner_writes_the_system_rate_and_can_clear_it(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $set = $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7.15'], $headers);
        $cleared = $this->putJson('/api/v1/treasury/settings', ['usd_rate' => null], $headers);
        $refused = $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '0'], $headers);

        // Assert
        $set->assertOk()->assertJsonPath('data.usd_rate', '7.1500');
        $cleared->assertOk()->assertJsonPath('data.usd_rate', null);
        $refused->assertUnprocessable()->assertJsonValidationErrors('usd_rate');
    }

    public function test_dollars_count_in_the_totals_at_the_system_rate(): void
    {
        // Arrange — 10,000 dinars, of which 7,150 bought $1,000
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $this->cashBox(), '10000');
        $this->exchange($headers, $this->cashBox(), $usd, ['amount' => '7150', 'counter_amount' => '1000'])->assertCreated();
        $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7.2'], $headers)->assertOk();

        // Act
        $response = $this->getJson('/api/v1/treasury/ownership', $headers);

        // Assert — 2,850 + 1,000 × 7.2
        $response->assertOk()
            ->assertJsonPath('data.usd_held', '1000.00')
            ->assertJsonPath('data.usd_rate', '7.2000')
            ->assertJsonPath('data.usd_held_in_lyd', '7200.00')
            ->assertJsonPath('data.total_held', '10050.00')
            ->assertJsonPath('data.company_own', '10050.00');
    }

    public function test_the_accounts_list_total_counts_dollars_at_the_rate_and_never_as_dinars(): void
    {
        // Arrange — 500 dinars and $100
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $usd, '100');
        $this->deposit($headers, $this->cashBox(), '500');

        // Act
        $unvalued = $this->getJson('/api/v1/treasury/accounts', $headers);
        $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7'], $headers)->assertOk();
        $valued = $this->getJson('/api/v1/treasury/accounts', $headers);

        // Assert
        $unvalued->assertOk()
            ->assertJsonPath('data.total', '500.00')
            ->assertJsonPath('data.usd_total', '100.00')
            ->assertJsonPath('data.usd_total_in_lyd', null);
        $valued->assertOk()
            ->assertJsonPath('data.total', '1200.00')
            ->assertJsonPath('data.usd_rate', '7.0000')
            ->assertJsonPath('data.usd_total_in_lyd', '700.00');
    }

    public function test_without_a_system_rate_dollars_stay_out_of_the_dinar_totals(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $usd = $this->dollarAccount($headers);
        $this->deposit($headers, $usd, '1000');
        $this->deposit($headers, $this->cashBox(), '500');

        // Act
        $response = $this->getJson('/api/v1/treasury/ownership', $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.usd_held', '1000.00')
            ->assertJsonPath('data.usd_rate', null)
            ->assertJsonPath('data.usd_held_in_lyd', null)
            ->assertJsonPath('data.total_held', '500.00');
    }
}
