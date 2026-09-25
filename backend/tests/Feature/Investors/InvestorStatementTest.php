<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\ReverseWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * سجلُّ حركات المستثمر — كلُّ ما جرى لماله، بفلاتره، من شاشة الموظّف ومن بوابته هو.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestorStatementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    public function test_a_fund_subscription_is_named_for_the_fund_and_carries_its_units(): void
    {
        // Arrange — «تمويل صفقة» على اشتراكٍ في الصندوق يسمّي شيئاً لم يفعله.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);

        $investor = Investor::factory()->create();
        $this->deposit($investor, '1000.00');
        app(DepositToFund::class)(investorId: (int) $investor->id, amount: '1000.00', actorId: null);

        // Act
        $response = $this->withHeaders($this->reader())
            ->getJson("/api/v1/investors/{$investor->id}/statement");

        // Assert — newest first: the subscription, then the deposit that paid for it.
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.type', 'allocation')
            ->assertJsonPath('data.0.type_label', 'اشتراك في الصندوق')
            ->assertJsonPath('data.0.category', 'investment')
            ->assertJsonPath('data.0.deal.is_fund', true)
            ->assertJsonPath('data.0.fund_units.units', '1000.000000')
            ->assertJsonPath('data.0.fund_units.unit_price', '1.000000')
            ->assertJsonPath('data.1.type', 'deposit')
            ->assertJsonPath('data.1.category', 'capital')
            ->assertJsonPath('data.1.fund_units', null);
    }

    public function test_a_category_keeps_the_reversal_of_what_it_matches(): void
    {
        // Arrange — a deposit, its undo, and a profit payout that is not capital. Filtering on
        // the row's own type would show the deposit and hide the row that took it back.
        $investor = Investor::factory()->create();
        $deposit = $this->deposit($investor, '500.00');
        app(ReverseWalletEntry::class)($deposit, null, 'خطأ في المبلغ');
        $this->deposit($investor, '300.00');

        // Act
        $response = $this->withHeaders($this->reader())
            ->getJson("/api/v1/investors/{$investor->id}/statement?category=capital");

        // Assert
        $response->assertOk()->assertJsonCount(3, 'data');

        $reversal = collect($response->json('data'))->firstWhere('type', 'reversal');
        $this->assertSame('capital', $reversal['category']);
        $this->assertSame('عكس حركة: إيداع رأس مال', $reversal['type_label']);

        $original = collect($response->json('data'))->firstWhere('id', $deposit->id);
        $this->assertTrue($original['is_reversed']);
        $this->assertFalse($original['can_be_reversed']);
    }

    public function test_a_category_leaves_out_every_other_family(): void
    {
        // Arrange
        $investor = Investor::factory()->create();
        $this->deposit($investor, '500.00');

        // Act
        $response = $this->withHeaders($this->reader())
            ->getJson("/api/v1/investors/{$investor->id}/statement?category=profit");

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_the_date_range_counts_the_whole_of_its_last_day(): void
    {
        // Arrange — one row before the range, one late on its last day, one after it.
        $investor = Investor::factory()->create();
        $this->deposit($investor, '100.00', '2026-08-31 23:00:00');
        $inside = $this->deposit($investor, '200.00', '2026-09-10 22:30:00');
        $this->deposit($investor, '300.00', '2026-09-11 00:10:00');

        // Act
        $response = $this->withHeaders($this->reader())
            ->getJson("/api/v1/investors/{$investor->id}/statement?from=2026-09-01&to=2026-09-10");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $inside->id);
    }

    public function test_a_filter_that_cannot_be_read_is_refused_rather_than_answered_empty(): void
    {
        // Arrange
        $investor = Investor::factory()->create();

        // Act
        $response = $this->withHeaders($this->reader())
            ->getJson("/api/v1/investors/{$investor->id}/statement?category=bonus&from=2026-09-10&to=2026-09-01");

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['category', 'to']);
    }

    public function test_the_portal_reads_the_same_list_filtered_and_only_his_own(): void
    {
        // Arrange
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestorPortal->value);
        $mine = Investor::factory()->create(['user_id' => $user->id]);
        $this->deposit($mine, '400.00');
        $this->withdraw($mine, '100.00');

        $theirs = Investor::factory()->create();
        $this->deposit($theirs, '900.00');

        // Act
        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken,
        ])->getJson('/api/v1/investor-portal/statement?category=capital');

        // Assert — his two rows, and nothing of the other man's 900.
        $response->assertOk()->assertJsonCount(2, 'data');
        $this->assertEqualsCanonicalizing(
            ['400.00', '100.00'],
            collect($response->json('data'))->pluck('amount')->all(),
        );
    }

    /**
     * @return array<string, string>
     */
    private function reader(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestors->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function deposit(Investor $investor, string $amount, ?string $at = null): InvestorWalletEntry
    {
        return app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
                occurredAt: $at === null ? null : CarbonImmutable::parse($at),
            ),
            null,
        );
    }

    private function withdraw(Investor $investor, string $amount): void
    {
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Withdrawal,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );
    }
}
