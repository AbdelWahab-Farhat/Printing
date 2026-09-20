<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriodShare;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The close — where a period's profit becomes somebody's money.
 *
 * The properties that matter, and every one of them is a way to lose money if it is wrong:
 *
 * 1. The net-profit equation is what the design says it is.
 * 2. A landed expense is recorded and **not** subtracted; a manual one is.
 * 3. The distribution sums to the net profit exactly.
 * 4. A losing period writes capital down, capped at what each put in.
 * 5. **A loss in one pool never touches another pool's capital.**
 * 6. Profit becomes withdrawable at the close and not before.
 * 7. An unanswered returned-goods question blocks the close.
 * 8. The next period opens in the same breath.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestmentPeriodCloseTest extends TestCase
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
    private function closer(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
            PermissionName::RecordInvestorMoney->value,
            PermissionName::RecordDealExpenses->value,
            PermissionName::CloseInvestmentPeriods->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** A pool with one open period and the given investors' capital in it. */
    private function pool(array $capitalByInvestor): array
    {
        $pool = InvestorDeal::factory()->pool()->create(['investor_profit_share_percent' => '50.00']);

        $period = InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => now()->startOfMonth()->toDateString(),
            'ends_on' => now()->endOfMonth()->toDateString(),
        ]);

        $service = app(InvestorService::class);
        $investors = [];

        foreach ($capitalByInvestor as $label => $amount) {
            $investor = Investor::factory()->create(['name' => (string) $label]);

            $service->recordWalletEntry(new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ), null);

            $service->recordWalletEntry(new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Allocation,
                amount: $amount,
                investorDealId: (int) $pool->getKey(),
            ), null);

            $investors[$label] = $investor;
        }

        return ['pool' => $pool->refresh(), 'period' => $period->refresh(), 'investors' => $investors];
    }

    private function earn(InvestmentPeriod $period, string $amount, int $sourceId = 1): void
    {
        InvestmentRealizedEarning::factory()->create([
            'investment_period_id' => $period->getKey(),
            'source_type' => AuditSubject::Order->value,
            'source_id' => $sourceId,
            'amount' => $amount,
        ]);
    }

    public function test_the_net_profit_equation_is_what_the_design_says(): void
    {
        // Arrange
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');

        app(InvestorService::class)->recordDealExpense(
            $setup['pool'],
            new DealExpenseData(
                kind: DealExpenseKind::Storage,
                name: 'تخزين',
                amount: '1000.00',
                incurredOn: now()->toDateString(),
            ),
            null,
        );

        // Act
        $figures = app(InvestorService::class)->periodFigures($setup['period']);

        // Assert — margin 10,000 less a 1,000 expense
        $this->assertSame('10000.00', $figures['realized_margin']);
        $this->assertSame('1000.00', $figures['deductible_expenses']);
        $this->assertSame('9000.00', $figures['net_profit']);
    }

    public function test_a_pool_expense_does_not_charge_investors_twice(): void
    {
        // Arrange — the trap: a صفقة wrote `loss` rows for an expense immediately. A صندوق must
        // not, or the investors' cut comes off once now and again when the period divides a net
        // profit that was already reduced by it.
        $setup = $this->pool(['أحمد' => '100000.00']);

        app(InvestorService::class)->recordDealExpense(
            $setup['pool'],
            new DealExpenseData(
                kind: DealExpenseKind::Storage,
                name: 'تخزين',
                amount: '1000.00',
                incurredOn: now()->toDateString(),
            ),
            null,
        );

        // Assert — no loss row was written against anybody
        $this->assertSame(
            0,
            InvestorWalletEntry::query()
                ->where('investor_deal_id', $setup['pool']->getKey())
                ->where('type', WalletEntryType::Loss->value)
                ->count(),
        );
        $this->assertSame(
            '0.00',
            app(InvestorBalances::class)->forDeal((int) $setup['pool']->getKey())['profit'],
        );
    }

    public function test_the_distribution_matches_the_worked_example(): void
    {
        // Arrange — A 120,000 · B 80,000 · C 80,000 · company 70,000; net profit 28,000
        $setup = $this->pool(['أ' => '120000.00', 'ب' => '80000.00', 'ج' => '80000.00']);

        $company = Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);
        $service = app(InvestorService::class);
        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $company->getKey(),
            type: WalletEntryType::Deposit,
            amount: '70000.00',
            method: 'cash',
        ), null);
        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $company->getKey(),
            type: WalletEntryType::Allocation,
            amount: '70000.00',
            investorDealId: (int) $setup['pool']->getKey(),
        ), null);

        $this->earn($setup['period'], '28000.00');

        // Act
        $closed = $service->closePeriod($setup['period'], null);

        // Assert — the table from INVESTMENT-FUND-DESIGN.md §6.3
        $this->assertSame('80.0000', (string) $closed->investor_capital_weight_applied);
        $this->assertSame('28000.00', (string) $closed->net_profit);

        $shares = InvestmentPeriodShare::query()
            ->where('investment_period_id', $closed->getKey())
            ->get()
            ->keyBy('investor_id');

        $this->assertSame('4800.00', (string) $shares[$setup['investors']['أ']->getKey()]->net_share);
        $this->assertSame('3200.00', (string) $shares[$setup['investors']['ب']->getKey()]->net_share);
        $this->assertSame('3200.00', (string) $shares[$setup['investors']['ج']->getKey()]->net_share);
        $this->assertSame('16800.00', (string) $shares[$company->getKey()]->net_share);
    }

    public function test_profit_becomes_withdrawable_only_at_the_close(): void
    {
        // Arrange
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');
        $investorId = (int) $setup['investors']['أحمد']->getKey();

        // Assert — before: nothing of it is his
        $before = app(InvestorBalances::class)->forInvestor($investorId);
        $this->assertSame('0.00', $before['wallet']['profit']);

        // Act
        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Assert — after: half of 10,000, in his wallet and withdrawable
        $after = app(InvestorBalances::class)->forInvestor($investorId);
        $this->assertSame('5000.00', $after['wallet']['profit']);
        $this->assertSame('0.00', $after['deals'][$setup['pool']->getKey()]['profit']);
    }

    public function test_a_losing_period_writes_capital_down_capped_at_what_he_put_in(): void
    {
        // Arrange — 1,000 of capital against a 10,000 loss
        $setup = $this->pool(['أحمد' => '1000.00']);
        $this->earn($setup['period'], '-10000.00');
        $investorId = (int) $setup['investors']['أحمد']->getKey();

        // Act
        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Assert — his capital is gone and no further; the rest is the company's
        $balances = app(InvestorBalances::class)->forInvestor($investorId);
        $this->assertSame('0.00', $balances['deals'][$setup['pool']->getKey()]['capital']);
        $this->assertSame('0.00', $balances['deals'][$setup['pool']->getKey()]['profit']);

        $this->assertSame(
            1,
            InvestorWalletEntry::query()
                ->where('investor_id', $investorId)
                ->where('type', WalletEntryType::LossAbsorbedByCompany->value)
                ->count(),
        );
    }

    public function test_a_loss_in_one_pool_never_touches_another(): void
    {
        // Arrange — the whole reason pools were chosen over one fund
        $investor = Investor::factory()->create();
        $service = app(InvestorService::class);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: '100000.00',
            method: 'cash',
        ), null);

        $paper = InvestorDeal::factory()->pool()->create(['investor_profit_share_percent' => '50.00']);
        $ink = InvestorDeal::factory()->pool()->create(['investor_profit_share_percent' => '50.00']);

        foreach ([$paper, $ink] as $pool) {
            $service->recordWalletEntry(new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Allocation,
                amount: '20000.00',
                investorDealId: (int) $pool->getKey(),
            ), null);
        }

        $inkPeriod = InvestmentPeriod::factory()->create([
            'investor_deal_id' => $ink->getKey(),
            'starts_on' => now()->startOfMonth()->toDateString(),
            'ends_on' => now()->endOfMonth()->toDateString(),
        ]);

        $this->earn($inkPeriod, '-50000.00');

        // Act — the ink pool loses everything
        $service->closePeriod($inkPeriod, null);

        // Assert — his paper capital is untouched
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('0.00', $balances['deals'][$ink->getKey()]['capital']);
        $this->assertSame('20000.00', $balances['deals'][$paper->getKey()]['capital']);
    }

    public function test_an_unanswered_returned_goods_question_blocks_the_close(): void
    {
        // Arrange
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        // Act
        $response = $this->withHeaders($this->closer())
            ->postJson("/api/v1/investment-periods/{$setup['period']->getKey()}/close");

        // Assert — nothing was divided, and the period is still open
        $response->assertStatus(422);
        $this->assertSame(PeriodStatus::Open, $setup['period']->fresh()->status);
        $this->assertSame(0, InvestmentPeriodShare::query()->count());
    }

    public function test_the_next_period_opens_in_the_same_breath(): void
    {
        // Arrange — a sale realized between a close and the next open would have nowhere to land
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');

        // Act
        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Assert
        $open = InvestmentPeriod::query()
            ->where('investor_deal_id', $setup['pool']->getKey())
            ->where('status', PeriodStatus::Open->value)
            ->get();

        $this->assertCount(1, $open);
        $this->assertSame(
            $setup['period']->ends_on->copy()->addDay()->toDateString(),
            $open->first()->starts_on->toDateString(),
        );
    }

    public function test_a_closed_period_cannot_be_closed_again(): void
    {
        // Arrange — running it twice would double every payout
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');

        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Act
        $response = $this->withHeaders($this->closer())
            ->postJson("/api/v1/investment-periods/{$setup['period']->getKey()}/close");

        // Assert
        $response->assertStatus(422);
        $this->assertSame(
            '5000.00',
            app(InvestorBalances::class)
                ->forInvestor((int) $setup['investors']['أحمد']->getKey())['wallet']['profit'],
        );
    }

    public function test_the_snapshot_is_frozen_on_the_period(): void
    {
        // Arrange
        $setup = $this->pool(['أحمد' => '100000.00']);
        $this->earn($setup['period'], '10000.00');

        // Act
        $closed = app(InvestorService::class)->closePeriod($setup['period'], null);

        // Assert — the figures the money was actually divided on, kept where they cannot move
        $this->assertSame(PeriodStatus::Closed, $closed->status);
        $this->assertNotNull($closed->closed_at);
        $this->assertSame('10000.00', (string) $closed->realized_margin);
        $this->assertSame('10000.00', (string) $closed->net_profit);
        $this->assertSame('50.00', (string) $closed->investor_share_percent_applied);
        $this->assertSame('100000.00', (string) $closed->total_investor_capital);
    }
}
