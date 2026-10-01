<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The accounts themselves: who sees them, how the default moves, where a payment would land, and
 * the history screen — TREASURY-DESIGN §٥, §٩.
 *
 * Arrange - Act - Assert throughout.
 */
class TreasuryAccountsTest extends TestCase
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
    private function user(array $permissions = []): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    // ── seeing ──────────────────────────────────────────────────────────────────────────

    public function test_the_dashboard_lists_every_account_with_its_balance(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->defaultOf(AccountKind::Bank)->id, 'amount' => '21300',
        ], $headers)->assertCreated();

        // Act
        $response = $this->getJson('/api/v1/treasury/accounts', $headers);

        // Assert
        $response->assertOk()
            ->assertJsonCount(4, 'data.accounts')
            ->assertJsonPath('data.total', '21300.00')
            ->assertJsonPath('data.can_view_all', true);

        $bank = collect($response->json('data.accounts'))->firstWhere('kind', 'bank');
        $this->assertSame('21300.00', $bank['balance']);
    }

    public function test_somebody_without_the_grant_sees_only_the_accounts_in_their_name(): void
    {
        // Arrange
        [$ali, $headers] = $this->user();
        $his = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create(['name' => 'مصرف علي']);

        // Act
        $list = $this->getJson('/api/v1/treasury/accounts', $headers);
        $own = $this->getJson("/api/v1/treasury/accounts/{$his->id}", $headers);
        $ownHistory = $this->getJson("/api/v1/treasury/accounts/{$his->id}/movements", $headers);
        $shop = $this->getJson('/api/v1/treasury/accounts/'.$this->defaultOf(AccountKind::Cash)->id, $headers);

        // Assert
        $list->assertOk()->assertJsonCount(1, 'data.accounts')->assertJsonPath('data.accounts.0.name', 'مصرف علي');
        $own->assertOk();
        $ownHistory->assertOk();
        $shop->assertForbidden();
    }

    public function test_the_history_carries_the_balance_each_movement_left_behind(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);
        $cash = $this->defaultOf(AccountKind::Cash);
        foreach (['100', '250'] as $amount) {
            $this->postJson('/api/v1/treasury/operations', [
                'type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => $amount,
            ], $headers)->assertCreated();
        }
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal', 'from_account_id' => $cash->id, 'amount' => '50', 'notes' => 'سحب',
        ], $headers)->assertCreated();

        // Act
        $response = $this->getJson("/api/v1/treasury/accounts/{$cash->id}/movements", $headers);
        $withdrawalsOnly = $this->getJson("/api/v1/treasury/accounts/{$cash->id}/movements?kind=withdrawal", $headers);

        // Assert — newest first, and a filter does not restart the running sum
        $response->assertOk()
            ->assertJsonPath('data.0.signed_amount', '-50.00')
            ->assertJsonPath('data.0.balance_after', '300.00')
            ->assertJsonPath('data.2.balance_after', '100.00');

        $withdrawalsOnly->assertJsonCount(1, 'data')->assertJsonPath('data.0.balance_after', '300.00');
    }

    public function test_each_history_line_says_whether_this_viewer_may_reverse_it(): void
    {
        // Arrange — افتتاحٌ لا يُعكس، وإيداعٌ يُعكس، وسحبٌ عُكس فلا يُعكس هو ولا عكسُه.
        [, $reverser] = $this->user([
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ReverseTreasuryOperations,
            PermissionName::ManageTreasury,
        ]);
        $cash = $this->defaultOf(AccountKind::Cash);
        $operate = fn (string $url, array $body) => $this->postJson($url, $body, $reverser)
            ->assertCreated()->json('data.id');
        $url = '/api/v1/treasury/operations';
        $operate($url, ['type' => 'opening', 'to_account_id' => $cash->id, 'amount' => '100']);
        $operate($url, ['type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => '50']);
        $withdrawal = $operate($url, [
            'type' => 'withdrawal',
            'from_account_id' => $cash->id,
            'amount' => '20',
            'notes' => 'سحب',
        ]);
        $operate("{$url}/{$withdrawal}/reverse", ['reason' => 'خطأ']);
        [, $reader] = $this->user([PermissionName::ViewTreasury]);
        $history = function (array $headers) use ($cash): array {
            $this->app['auth']->forgetGuards();

            return $this->getJson("/api/v1/treasury/accounts/{$cash->id}/movements", $headers)
                ->assertOk()->json('data.*.is_reversible');
        };

        // Act
        $asReverser = $history($reverser);
        $asReader = $history($reader);

        // Assert — الأحدث أولاً: عكسُ السحب، السحبُ المعكوس، الإيداع، الافتتاح.
        $this->assertSame([false, false, true, false], $asReverser);
        $this->assertSame([false, false, false, false], $asReader);
    }

    public function test_the_account_page_totals_each_kind(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations]);
        $cash = $this->defaultOf(AccountKind::Cash);
        $bank = $this->defaultOf(AccountKind::Bank);
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $cash->id, 'amount' => '500',
        ], $headers);
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer', 'from_account_id' => $cash->id, 'to_account_id' => $bank->id, 'amount' => '200',
        ], $headers);

        // Act
        $response = $this->getJson("/api/v1/treasury/accounts/{$cash->id}", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.account.balance', '300.00')
            ->assertJsonPath('data.totals.total_in', '500.00')
            ->assertJsonPath('data.totals.total_out', '200.00');

        $transfers = collect($response->json('data.totals.by_kind'))->firstWhere('kind', 'transfer');
        $this->assertSame('200.00', $transfers['out']);
    }

    // ── shaping accounts ────────────────────────────────────────────────────────────────

    public function test_making_an_account_the_default_takes_the_title_from_the_old_one(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ManageTreasury]);
        $oldBank = $this->defaultOf(AccountKind::Bank);

        // Act
        $created = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'مصرف الجمهورية',
            'kind' => 'bank',
            'is_default' => true,
        ], $headers);

        // Assert
        $created->assertCreated()->assertJsonPath('data.is_default', true)->assertJsonPath('data.balance', '0.00');
        $this->assertFalse($oldBank->refresh()->is_default);
    }

    public function test_no_change_may_leave_a_method_with_nowhere_to_land(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ManageTreasury]);
        $cash = $this->defaultOf(AccountKind::Cash);
        $nawris = TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();

        // Act
        $unsetDefault = $this->putJson("/api/v1/treasury/accounts/{$cash->id}", ['is_default' => false], $headers);
        $switchOffDefault = $this->putJson("/api/v1/treasury/accounts/{$cash->id}", ['is_active' => false], $headers);
        $switchOffNawris = $this->putJson("/api/v1/treasury/accounts/{$nawris->id}", ['is_active' => false], $headers);
        $custodyDefault = $this->putJson("/api/v1/treasury/accounts/{$nawris->id}", ['is_default' => true], $headers);
        $rename = $this->putJson("/api/v1/treasury/accounts/{$cash->id}", ['name' => 'الخزنة'], $headers);

        // Assert
        $unsetDefault->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $switchOffDefault->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $switchOffNawris->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $custodyDefault->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $rename->assertOk()->assertJsonPath('data.name', 'الخزنة');
    }

    public function test_an_account_still_holding_money_cannot_be_switched_off(): void
    {
        // Arrange — المعطَّل لا يظهر في منتقٍ ولا يستقبل حركة يدوية؛ مالٌ فيه لا يصله أحد.
        [, $headers] = $this->user([
            PermissionName::ManageTreasury,
            PermissionName::RecordTreasuryOperations,
        ]);
        $branch = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();
        $empty = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $branch->id, 'amount' => '250',
        ], $headers)->assertCreated();
        $switchOff = fn (TreasuryAccount $account) => $this->putJson(
            "/api/v1/treasury/accounts/{$account->id}",
            ['is_active' => false],
            $headers,
        );

        // Act
        $holding = $switchOff($branch);
        $nothing = $switchOff($empty);

        // Assert
        $holding->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $this->assertTrue($branch->refresh()->is_active);
        $nothing->assertOk()->assertJsonPath('data.is_active', false);
    }

    public function test_one_request_cannot_make_an_account_the_default_and_switch_it_off(): void
    {
        // Arrange — كان يُعطَّل ثم يُعاد تفعيله صامتاً حين يصير افتراضياً، أو يصطدم بالقيد: 500.
        [, $headers] = $this->user([PermissionName::ManageTreasury]);
        $other = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();
        $bank = $this->defaultOf(AccountKind::Bank);
        $both = ['is_default' => true, 'is_active' => false];

        // Act
        $promote = $this->putJson("/api/v1/treasury/accounts/{$other->id}", $both, $headers);
        $current = $this->putJson("/api/v1/treasury/accounts/{$bank->id}", $both, $headers);

        // Assert
        $promote->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $current->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $this->assertTrue($other->refresh()->is_active);
        $this->assertFalse($other->is_default);
        $this->assertTrue($bank->refresh()->is_default);
        $this->assertTrue($bank->is_active);
    }

    public function test_only_the_manage_grant_shapes_accounts(): void
    {
        // Arrange
        [, $headers] = $this->user([PermissionName::ViewTreasury]);

        // Act
        $response = $this->postJson('/api/v1/treasury/accounts', ['name' => 'x', 'kind' => 'cash'], $headers);

        // Assert
        $response->assertForbidden();
    }

    // ── where a payment would land ──────────────────────────────────────────────────────

    public function test_a_payment_lands_in_the_one_account_its_recorder_holds_or_else_the_default(): void
    {
        // Arrange
        [$ali] = $this->user();
        [$omar] = $this->user();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create(['name' => 'مصرف علي']);
        $treasury = app(TreasuryService::class);

        // Act
        $byAli = $treasury->accountFor('bank_transfer', (int) $ali->id);
        $byOmar = $treasury->accountFor('bank_transfer', (int) $omar->id);
        $aliInCash = $treasury->accountFor('cash', (int) $ali->id);
        $libyana = $treasury->accountFor('libyana', null);

        // Assert
        $this->assertTrue($byAli->is($alisBank));
        $this->assertTrue($byOmar->is($this->defaultOf(AccountKind::Bank)));
        $this->assertTrue($aliInCash->is($this->defaultOf(AccountKind::Cash)));
        $this->assertTrue($libyana->is($this->defaultOf(AccountKind::Wallet)));
    }

    public function test_a_chosen_account_must_fit_the_method_and_money_out_never_leaves_custody(): void
    {
        // Arrange
        [, $headers] = $this->user();
        $nawris = TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();

        // Act
        $options = $this->getJson('/api/v1/treasury/account-options?method=bank_card', $headers);
        $outOfCash = $this->getJson('/api/v1/treasury/account-options?method=cash&purpose=out', $headers);

        // Assert
        $options->assertOk()
            ->assertJsonCount(1, 'data.accounts')
            ->assertJsonPath('data.suggested_id', $this->defaultOf(AccountKind::Bank)->id);
        $this->assertNotContains($nawris->id, collect($outOfCash->json('data.accounts'))->pluck('id')->all());

        $this->expectExceptionMessage('لا يناسب');
        app(TreasuryService::class)->accountFor('bank_transfer', null, $this->defaultOf(AccountKind::Cash)->id);
    }
}
