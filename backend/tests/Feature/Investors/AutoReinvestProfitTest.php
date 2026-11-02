<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\ReinvestProfit;
use App\Domain\Investor\Actions\ReverseWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\SubscriptionWindowIsClosed;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «إعادة استثمار الأرباح تلقائياً» — زرٌّ لكلّ مستثمر، وكنسٌ كلَّ ساعةٍ داخل النافذة.
 *
 * {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} §١٤.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class AutoReinvestProfitTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    // ─────────────────────────── the sweep ───────────────────────────

    public function test_the_sweep_puts_his_withdrawable_profit_back_into_the_fund(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');
        $this->assertSame('11000.00', app(FundCash::class)());

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert — الربحُ صار وحداتٍ بسعر اليوم، ولم يبقَ منه في المحفظة شيء.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $after['wallet']['profit']);
        $this->assertSame('0.00', $after['wallet']['capital']);
        $this->assertSame('11000.000000', app(FundUnits::class)->heldBy((int) $investor->id));

        // ونقدُ الصندوق خرج بالأولى وعاد بالثانية، فلم يتحرّك السعر.
        $this->assertSame('11000.00', app(FundCash::class)());
        $this->assertSame('1.000000', app(UnitPrice::class)());

        // وكشفُه يقول إن النظام فعلها.
        foreach ([WalletEntryType::ProfitCapitalisation, WalletEntryType::Allocation] as $type) {
            $row = InvestorWalletEntry::query()
                ->where('investor_id', $investor->id)
                ->where('type', $type)
                ->latest('id')
                ->firstOrFail();
            $this->assertSame(ReinvestProfit::NOTE, $row->notes);
            $this->assertNull($row->recorded_by);
        }
    }

    public function test_reinvested_profit_carries_the_normal_lock_of_its_own(): void
    {
        // Arrange — قرارُ المالك (١أ): كالطريق اليدويّ تماماً، لكلّ إعادةٍ مؤقّتُها.
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $units = InvestmentUnit::query()
            ->where('investor_id', $investor->id)
            ->where('amount', '1000.00')
            ->sole();
        $this->assertSame('2027-10-02', $units->locked_until->toDateString());
    }

    public function test_outside_the_window_the_profit_waits_and_stays_withdrawable(): void
    {
        // Arrange — طلبيةٌ متأخّرة تُفرج عن ربحها يوم ٢٠، ونافذةُ أكتوبر أُغلقت في السابع.
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->releaseProfitFromTheFund($investor, '500.00');

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('500.00', $after['wallet']['profit']);
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'type' => WalletEntryType::ProfitCapitalisation->value,
        ]);
    }

    public function test_it_reaches_the_profit_that_waited_once_the_next_window_opens(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->releaseProfitFromTheFund($investor, '500.00');
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Act — تُقفَل أكتوبر وتُفتح نوفمبر، ثم الكنسة.
        Carbon::setTestNow('2026-11-01 01:00:00');
        $this->artisan('investment:roll-periods')->assertSuccessful();
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $after['wallet']['profit']);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::ProfitCapitalisation->value,
            'amount' => '500.00',
        ]);
    }

    public function test_an_investor_whose_switch_is_off_is_left_alone(): void
    {
        // Arrange — القرار ٥: مُطفأ للجميع.
        $investor = $this->anInvestorInTheFund(autoReinvest: false);
        $this->releaseProfitFromTheFund($investor, '1000.00');

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $this->assertSame(
            '1000.00',
            app(InvestorBalances::class)->forInvestor((int) $investor->id)['wallet']['profit'],
        );
    }

    public function test_a_stopped_investor_is_left_alone_even_with_his_switch_on(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');
        $investor->forceFill(['is_active' => false])->save();

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $this->assertSame(
            '1000.00',
            app(InvestorBalances::class)->forInvestor((int) $investor->id)['wallet']['profit'],
        );
    }

    public function test_running_the_sweep_twice_reinvests_once(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');

        // Act
        $this->artisan('investment:reinvest-profit')->assertSuccessful();
        $this->artisan('investment:reinvest-profit')->assertSuccessful();

        // Assert
        $this->assertSame(1, InvestorWalletEntry::query()
            ->where('type', WalletEntryType::ProfitCapitalisation)
            ->count());
        $this->assertSame('11000.000000', app(FundUnits::class)->heldBy((int) $investor->id));
    }

    public function test_the_dry_run_writes_nothing(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');

        // Act
        $this->artisan('investment:reinvest-profit', ['--dry-run' => true])->assertSuccessful();

        // Assert
        $this->assertSame(
            '1000.00',
            app(InvestorBalances::class)->forInvestor((int) $investor->id)['wallet']['profit'],
        );
    }

    public function test_a_refused_subscription_takes_the_capitalisation_back_with_it(): void
    {
        // Arrange — النافذةُ ترفض الخطوة الثانية؛ لا يجوز أن تبقى الأولى وحدها.
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->releaseProfitFromTheFund($investor, '500.00');

        // Act
        try {
            app(ReinvestProfit::class)((int) $investor->id, null);
            $this->fail('the closed window should have refused the subscription');
        } catch (SubscriptionWindowIsClosed) {
            // Expected.
        }

        // Assert
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('500.00', $after['wallet']['profit']);
        $this->assertSame('0.00', $after['wallet']['capital']);
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'type' => WalletEntryType::ProfitCapitalisation->value,
        ]);
    }

    public function test_reversing_the_subscription_and_the_capitalisation_gives_the_profit_back(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);
        $this->releaseProfitFromTheFund($investor, '1000.00');
        $result = app(ReinvestProfit::class)((int) $investor->id, null);

        // Act — كعكس أيّ اشتراكٍ يدويّ: الاشتراكُ أولاً ثم التحويل.
        app(ReverseWalletEntry::class)($result['wallet_entry'], null);
        app(ReverseWalletEntry::class)($result['capitalisation'], null);

        // Assert
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('1000.00', $after['wallet']['profit']);
        $this->assertSame('10000.000000', app(FundUnits::class)->heldBy((int) $investor->id));
        $this->assertSame('11000.00', app(FundCash::class)());
        $this->assertSame('1.000000', app(UnitPrice::class)());
    }

    public function test_nothing_is_written_when_there_is_no_profit_to_reinvest(): void
    {
        // Arrange
        $investor = $this->anInvestorInTheFund(autoReinvest: true);

        // Act
        $result = app(ReinvestProfit::class)((int) $investor->id, null);

        // Assert
        $this->assertNull($result);
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'type' => WalletEntryType::ProfitCapitalisation->value,
        ]);
    }

    // ─────────────────────────── the switch ───────────────────────────

    public function test_turning_the_switch_on_stamps_when_and_off_clears_it(): void
    {
        // Arrange
        Carbon::setTestNow('2026-11-02 10:00:00');
        $investor = Investor::factory()->create();
        $headers = $this->auth(PermissionName::ManageInvestors);

        // Act
        $on = $this->withHeaders($headers)
            ->patchJson("/api/v1/investors/{$investor->id}/auto-reinvest", ['enabled' => true]);

        // Assert
        $on->assertOk()
            ->assertJsonPath('data.auto_reinvest_profit', true)
            ->assertJsonPath('message', 'سيُعاد استثمار أرباحه تلقائياً');
        $this->assertSame('2026-11-02 10:00:00', $investor->fresh()->auto_reinvest_since->toDateTimeString());

        // Act — تشغيلُه وهو مُشغَّل لا يُعيد الختم.
        Carbon::setTestNow('2026-11-05 10:00:00');
        $this->withHeaders($headers)
            ->patchJson("/api/v1/investors/{$investor->id}/auto-reinvest", ['enabled' => true])
            ->assertOk();
        $this->assertSame('2026-11-02 10:00:00', $investor->fresh()->auto_reinvest_since->toDateTimeString());

        // Act
        $off = $this->withHeaders($headers)
            ->patchJson("/api/v1/investors/{$investor->id}/auto-reinvest", ['enabled' => false]);

        // Assert
        $off->assertOk()
            ->assertJsonPath('data.auto_reinvest_profit', false)
            ->assertJsonPath('data.auto_reinvest_since', null);
        $this->assertFalse($investor->fresh()->auto_reinvest_profit);
    }

    public function test_a_new_investor_starts_with_the_switch_off(): void
    {
        // Arrange / Act
        $investor = Investor::factory()->create();

        // Assert
        $this->assertFalse($investor->fresh()->auto_reinvest_profit);
        $this->assertNull($investor->fresh()->auto_reinvest_since);
    }

    public function test_the_switch_needs_the_manage_permission(): void
    {
        // Arrange
        $investor = Investor::factory()->create();
        $headers = $this->auth(PermissionName::ViewInvestors);

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/investors/{$investor->id}/auto-reinvest", ['enabled' => true]);

        // Assert
        $response->assertForbidden();
        $this->assertFalse($investor->fresh()->auto_reinvest_profit);
    }

    public function test_the_switch_refuses_a_missing_flag(): void
    {
        // Arrange
        $investor = Investor::factory()->create();
        $headers = $this->auth(PermissionName::ManageInvestors);

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/investors/{$investor->id}/auto-reinvest", []);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['enabled']);
    }

    // ─────────────────────────── helpers ───────────────────────────

    /**
     * مستثمرٌ في الصندوق بعشرة آلاف، يومَ ٢ أكتوبر ونافذةُ أكتوبر مفتوحة.
     *
     * سبتمبر أوّلُ فترةٍ فتُقبل في أيّ يوم، فيُقفل ثم تُفتح أكتوبر — التي نافذتُها ١–٧.
     */
    private function anInvestorInTheFund(bool $autoReinvest): Investor
    {
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);

        $investor = Investor::factory()->create();
        $investor->forceFill([
            'auto_reinvest_profit' => $autoReinvest,
            'auto_reinvest_since' => $autoReinvest ? now() : null,
        ])->save();

        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: '10000.00',
                method: 'cash',
            ),
            null,
        );
        app(DepositToFund::class)(investorId: (int) $investor->id, amount: '10000.00', actorId: null);

        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: null);
        app(OpenInvestmentPeriod::class)(actorId: null);

        return $investor;
    }

    /** ربحٌ من بيع بضاعة الصندوق أُفرج عنه في محفظته — كما في FundUnitsTest. */
    private function releaseProfitFromTheFund(Investor $investor, string $amount): void
    {
        InvestmentCashEntry::factory()->create(['amount' => $amount]);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => app(FundDeal::class)()->id,
            'type' => WalletEntryType::ProfitRelease->value,
            'amount' => $amount,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /**
     * @return array<string, string>
     */
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
