<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * البابُ الذي تقرأ منه اللوحةُ الصندوقَ وتفتح منه فترة.
 *
 * الشريحة ١د من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestmentFundEndpointTest extends TestCase
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
     * @return array<string, string>
     */
    private function headersFor(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_a_fund_with_no_period_says_so_rather_than_inventing_one(): void
    {
        // Arrange — صندوقٌ لم تُفتح فيه فترةٌ بعد.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period', null)
            ->assertJsonPath('data.valuation.total', '0.00');
    }

    public function test_the_value_arrives_broken_into_its_parts(): void
    {
        // Arrange — المجموعُ وحده ادّعاء؛ من يقرأ رقماً يحتاج أن يعرف من أين جاء.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1400.000',
            'unit_cost' => '10.000',
        ]);

        DB::table('investment_cash_entries')->insert([
            'type' => 'deposit', 'amount' => '12000.00',
            'source_type' => 'investor_wallet_entry', 'source_id' => 1, 'source_sequence' => 1,
            'occurred_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.valuation.cash', '12000.00')
            ->assertJsonPath('data.valuation.stock_on_shelf', '14000.00')
            ->assertJsonPath('data.valuation.total', '26000.00');
    }

    public function test_opening_a_period_needs_the_authority_that_moves_investors_money(): void
    {
        // Arrange — القراءةُ وحدها لا تكفي: فتحُ فترةٍ يقرّر بأيّ نسبٍ يُقسَّم ربحُ شهر.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert
        $response->assertForbidden();
    }

    public function test_the_first_period_opens_on_what_the_fund_already_holds(): void
    {
        // Arrange — وهذا هو «لا تصفير»: الفترةُ تبدأ على رصيدٍ لا على صفر.
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1400.000',
            'unit_cost' => '10.000',
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.opening_stock_cost', '14000.00')
            ->assertJsonPath('data.investor_profit_share_percent', '50.00');

        $this->assertDatabaseCount('investment_periods', 1);
    }

    public function test_a_second_period_is_refused_while_the_first_runs(): void
    {
        // Arrange
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert — رسالةٌ تُقرأ، لا خطأُ فهرسٍ بخمسمئة.
        $response->assertStatus(422);
        $this->assertStringContainsString('ما زالت مفتوحة', $response->json('message'));
        $this->assertDatabaseCount('investment_periods', 1);
    }

    public function test_closing_from_the_screen_releases_the_profit(): void
    {
        // Arrange — فترةٌ انتهت نافذتُها، وربحٌ متراكم.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close');

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'closed');
        $this->assertStringContainsString('رأسُ المال والبضاعة في مكانهما', $response->json('message'));
    }

    public function test_an_early_close_without_a_reason_is_refused_with_words(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close');

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('ما زالت تستقبل', $response->json('message'));
    }

    public function test_a_one_word_reason_is_not_a_reason(): void
    {
        // Arrange — التجاوزُ يُكتب كاملاً ليُقرأ بعد سنة، لا كلمةً تمرّ.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close', [
            'override_reason' => 'خلاص',
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('override_reason');
    }

    /** إيداعٌ نقديّ على الطاولة — ما يملأ المحفظة قبل أن يُشترك به. */
    private function fundWallet(array $headers, int $investorId, string $amount): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/investors/{$investorId}/wallet", [
            'type' => 'deposit',
            'amount' => $amount,
            'method' => 'cash',
        ])->assertSuccessful();
    }

    public function test_a_deposit_from_the_screen_buys_units_and_says_what_it_bought(): void
    {
        // Arrange — الشريحتان ٣ و٤ من الشاشة: بابٌ واحد يكتب في ثلاثة دفاتر.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id,
            'amount' => '5000',
        ]);

        // Assert — الوحداتُ بسعر الافتتاح، والحبسُ سنةٌ من يومه.
        $response->assertOk()
            ->assertJsonPath('data.units', '5000.000000')
            ->assertJsonPath('data.unit_price', '1.000000')
            ->assertJsonPath('data.locked_until', '2027-09-01');

        $this->assertDatabaseHas('investment_cash_entries', ['type' => 'deposit', 'amount' => '5000.00']);
    }

    public function test_the_dashboard_carries_the_unit_price_and_who_holds_what(): void
    {
        // Arrange — الشاشةُ تحتاج السعرَ قبل أن تقبض، والنسبَ ليقرأها الشركاء.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        $big = Investor::factory()->create();
        $small = Investor::factory()->create();

        foreach ([[$big, '3000'], [$small, '1000']] as [$investor, $amount]) {
            $this->fundWallet($headers, (int) $investor->id, $amount);
            $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
                'investor_id' => $investor->id, 'amount' => $amount,
            ])->assertOk();
        }

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.units_outstanding', '4000.000000')
            ->assertJsonPath('data.investors.0.investor_id', $big->id)
            ->assertJsonPath('data.investors.0.share_percent', '75.000000')
            ->assertJsonPath('data.investors.1.share_percent', '25.000000')
            ->assertJsonPath('data.valuation.cash', '4000.00');
    }

    public function test_a_withdrawal_needs_the_lock_to_have_run_out(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id, 'amount' => '5000',
        ])->assertOk();

        // Act
        Carbon::setTestNow('2026-12-01 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/withdrawals', [
            'investor_id' => $investor->id, 'amount' => '1000',
        ]);

        // Assert — رسالةٌ تقول متى، لا «ممنوع» وحدها.
        $response->assertStatus(422);
        $this->assertStringContainsString('محبوس', $response->json('message'));
        $this->assertStringContainsString('2027-09-01', $response->json('message'));
    }

    public function test_reversing_a_deposit_takes_its_units_and_its_cash_with_it(): void
    {
        // Arrange — الشريحة ٠ب. وإبطالُ الإيداع بلا إبطال وحداته يترك رجلاً استُرجع مالُه
        // وبقيت نسبتُه تقاسم ربحاً لا يموّله.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id, 'amount' => '5000',
        ])->assertOk();

        $entryId = (int) DB::table('investor_wallet_entries')->where('type', 'allocation')->value('id');

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/investors/{$investor->id}/wallet/{$entryId}/reversal");

        // Assert — الدفاتر الثلاثة رجعت معاً.
        $response->assertOk();
        $this->assertSame('0.000000', app(FundUnits::class)->outstanding());
        $this->assertSame('0.00', app(FundCash::class)());

        // ورأسُ ماله في محفظته كما كان قبل الاشتراك — لم يضِع ولم يُضاعَف. وهذا هو الفرق الذي
        // صنعه `allocation` بدل `deposit`: الإبطالُ يعيده إلى حيث كان، لا يمحوه.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('5000.00', $balances['wallet']['capital']);
        $this->assertSame('0.00', $balances['deals'][app(FundDeal::class)()->id]['capital']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
