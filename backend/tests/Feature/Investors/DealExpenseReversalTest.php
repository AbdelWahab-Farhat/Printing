<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealShare;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundCashLedger;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * عكسُ مصروف الصفقة أو الصندوق — المالُ المسجَّل خطأً يُصحَّح بصفٍّ عكسيّ، لا يبقى ولا يُمحى.
 *
 * **مصروفٌ واحد يكتب في ثلاثة دفاتر، فعكسُه يعكسها الثلاثة:**
 *
 * ```
 * الخزينة         ←  حركةٌ معاكسة على الحساب الذي دفع، لا على افتراضيّ اليوم
 * محافظُ الشركاء  ←  ما حُمِّلوه يرجع إليهم — في فترة المصروف ما دامت تقبل القيد، وإلا في المفتوحة
 * نقدُ الصندوق     ←  ما خرج منه يعود إليه (مصروفُ الصندوق وحده)
 * ```
 *
 * والزوجُ — الأصلُ وعكسُه — يسقط من كل مجموعٍ للمصاريف: تكلفةُ الصفقة وربحُها، نقدُ الصندوق
 * وقيمتُه، ومصاريفُ الفترة يوم تُقفَل. ولا يُعكس العكسُ، ولا يُعكس الأصلُ مرّتين.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class DealExpenseReversalTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    /**
     * @return array<string, string>
     */
    private function bookkeeper(bool $mayReverse = true): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, array_filter([
            PermissionName::ViewInvestors,
            PermissionName::RecordDealExpenses,
            PermissionName::RecordInvestorMoney,
            $mayReverse ? PermissionName::ReverseInvestorMoney : null,
        ])));

        // الحارسُ يحفظ أوّلَ مستخدمٍ يحلّه في الاختبار؛ والثاني يُقرأ من رأسه هو.
        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()
            ->where('kind', $kind->value)
            ->where('is_default', true)
            ->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * صفقةٌ مفتوحة بشريكٍ واحد يملك حصّة المستثمرين كلَّها، ونصيبُهم نصفُ الربح.
     *
     * @return array{0: InvestorDeal, 1: Investor}
     */
    private function dealWithPartner(): array
    {
        $deal = InvestorDeal::factory()->open()->create([
            'investor_profit_share_percent' => '50.00',
        ]);
        $partner = Investor::factory()->create();
        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->id,
            'investor_id' => $partner->id,
            'share_percent' => '100.0000',
        ]);

        return [$deal, $partner];
    }

    /** شريكٌ بوحداتٍ في الصندوق — مالٌ نقدٌ على الطاولة ثم اشتراكٌ به. */
    private function fundPartner(string $amount): Investor
    {
        $investor = Investor::factory()->create();

        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        app(DepositToFund::class)(investorId: (int) $investor->id, amount: $amount, actorId: null);

        return $investor;
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function dealExpense(
        array $headers,
        InvestorDeal $deal,
        string $amount,
        array $extra = [],
    ): int {
        return (int) $this->postJson("/api/v1/investor-deals/{$deal->id}/expenses", [
            'kind' => 'customs',
            'name' => 'جمرك',
            'amount' => $amount,
            'incurred_on' => now()->toDateString(),
            ...$extra,
        ], $headers)->assertOk()->json('data.id');
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function fundExpense(array $headers, string $amount): int
    {
        return (int) $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => 'شحن',
            'amount' => $amount,
            'incurred_on' => now()->toDateString(),
        ], $headers)->assertOk()->json('data.id');
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function reverse(array $headers, string $url): TestResponse
    {
        return $this->postJson($url, ['reason' => 'فاتورة مكرّرة'], $headers);
    }

    private function onDeal(InvestorDeal $deal, int $expense): string
    {
        return "/api/v1/investor-deals/{$deal->id}/expenses/{$expense}/reverse";
    }

    private function onFund(int $expense): string
    {
        return "/api/v1/investment/expenses/{$expense}/reverse";
    }

    /** ربحُ الشريك في الصفقة — والخسارةُ تُنقصه، فمصروفٌ حُمِّل له يظهر هنا سالباً. */
    private function profitOf(Investor $partner, InvestorDeal $deal): string
    {
        $share = app(InvestorBalances::class)->forShare((int) $partner->id, (int) $deal->id);

        return $share['profit'];
    }

    // ── الصفقة ──────────────────────────────────────────────────────────────────────────

    public function test_reversing_a_deal_expense_returns_the_money_and_the_charge(): void
    {
        // Arrange — جمركٌ ١٠٠٠ دُفع من «مصرف الجمهورية» لا من الافتراضي، فحُمِّل الشريكُ ٥٠٠.
        $headers = $this->bookkeeper();
        [$deal, $partner] = $this->dealWithPartner();
        $jumhuria = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();
        $expense = $this->dealExpense($headers, $deal, '1000', [
            'treasury_account_id' => $jumhuria->id,
        ]);

        // Act
        $response = $this->reverse($headers, $this->onDeal($deal, $expense));

        // Assert — العكسُ صفٌّ يشير إلى أصله، والمالُ عاد إلى الحساب الذي دفع.
        $response->assertCreated()
            ->assertJsonPath('data.is_reversal', true)
            ->assertJsonPath('data.is_reversed', false)
            ->assertJsonPath('data.reverses_expense_id', $expense)
            ->assertJsonPath('data.amount', '1000.00')
            ->assertJsonPath('data.treasury_account_id', $jumhuria->id);
        $this->assertTrue(InvestorDealExpense::query()->findOrFail($expense)->isReversed());
        $this->assertSame('0.00', $this->balance($jumhuria));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('0.00', $this->profitOf($partner, $deal));
        $this->assertSame('0.00', app(InvestorBalances::class)->forDeal((int) $deal->id)['profit']);
    }

    public function test_the_partners_statement_nets_the_pair_to_nothing(): void
    {
        // Arrange
        $headers = $this->bookkeeper();
        [$deal, $partner] = $this->dealWithPartner();
        $expense = $this->dealExpense($headers, $deal, '1000');
        $this->reverse($headers, $this->onDeal($deal, $expense))->assertCreated();

        // Act
        $statement = $this->getJson("/api/v1/investors/{$partner->id}/statement", $headers);

        // Assert — سطران: الخسارةُ وعكسُها، ومجموعُهما صفر.
        $statement->assertOk()->assertJsonCount(2, 'data');
        $total = array_reduce(
            $statement->json('data.*.signed_amount'),
            fn (string $sum, string $line) => bcadd($sum, $line, 2),
            '0.00',
        );
        $this->assertSame('0.00', $total);
    }

    public function test_an_expense_is_reversed_once_and_a_reversal_never(): void
    {
        // Arrange
        $headers = $this->bookkeeper();
        [$deal] = $this->dealWithPartner();
        $expense = $this->dealExpense($headers, $deal, '300');
        $reversal = (int) $this->reverse($headers, $this->onDeal($deal, $expense))
            ->assertCreated()->json('data.id');

        // Act
        $twice = $this->reverse($headers, $this->onDeal($deal, $expense));
        $ofTheReversal = $this->reverse($headers, $this->onDeal($deal, $reversal));

        // Assert
        $twice->assertUnprocessable();
        $ofTheReversal->assertUnprocessable();
        $reversals = InvestorDealExpense::query()->whereNotNull('reverses_expense_id')->count();
        $this->assertSame(1, $reversals);
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_reversing_takes_a_reason_and_the_money_reverse_grant(): void
    {
        // Arrange
        $headers = $this->bookkeeper();
        [$deal] = $this->dealWithPartner();
        $expense = $this->dealExpense($headers, $deal, '300');
        $url = $this->onDeal($deal, $expense);
        $recorder = $this->bookkeeper(mayReverse: false);

        // Act
        $this->app['auth']->forgetGuards();
        $withoutReason = $this->postJson($url, [], $headers);
        $this->app['auth']->forgetGuards();
        $withoutGrant = $this->reverse($recorder, $url);

        // Assert
        $withoutReason->assertUnprocessable()->assertJsonValidationErrors('reason');
        $withoutGrant->assertForbidden();
        $this->assertFalse(InvestorDealExpense::query()->findOrFail($expense)->isReversed());
    }

    public function test_an_expense_is_reversed_only_under_its_own_deal(): void
    {
        // Arrange
        $headers = $this->bookkeeper();
        [$deal] = $this->dealWithPartner();
        [$other] = $this->dealWithPartner();
        $expense = $this->dealExpense($headers, $deal, '300');

        // Act
        $underAnother = $this->reverse($headers, $this->onDeal($other, $expense));
        $underTheFund = $this->reverse($headers, $this->onFund($expense));

        // Assert
        $underAnother->assertNotFound();
        $underTheFund->assertNotFound();
    }

    public function test_a_closed_deal_takes_no_reversal(): void
    {
        // Arrange — الصفقةُ المغلقة سُوّيت حساباتُ شركائها، فلا تقبل حركةً مالية جديدة.
        $headers = $this->bookkeeper();
        [$deal] = $this->dealWithPartner();
        $expense = $this->dealExpense($headers, $deal, '300');
        $deal->forceFill(['status' => DealStatus::Closed])->save();

        // Act
        $response = $this->reverse($headers, $this->onDeal($deal, $expense));

        // Assert
        $response->assertUnprocessable();
        $this->assertFalse(InvestorDealExpense::query()->findOrFail($expense)->isReversed());
    }

    public function test_an_expense_from_before_the_treasury_is_returned_to_the_cash_box(): void
    {
        // Arrange — صفٌّ قديم بلا حساب: احتُسب مالُه في الرصيد الافتتاحي، فعكسُه يعود إلى الخزنة.
        $headers = $this->bookkeeper();
        [$deal] = $this->dealWithPartner();
        $old = InvestorDealExpense::factory()->create([
            'investor_deal_id' => $deal->id,
            'amount' => '250.00',
        ]);

        // Act
        $response = $this->reverse($headers, $this->onDeal($deal, (int) $old->id));

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.treasury_account_id', $this->defaultOf(AccountKind::Cash)->id);
        $this->assertSame('250.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── الصندوق ─────────────────────────────────────────────────────────────────────────

    public function test_reversing_a_fund_expense_puts_its_cash_back_in_the_fund(): void
    {
        // Arrange — شريكٌ بعشرة آلاف، ومصروفُ شحنٍ ٤٠٠ خرج من الخزنة ومن نقد الصندوق.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $partner = $this->fundPartner('10000.00');
        $valueBefore = app(FundValuation::class)()['total'];
        $headers = $this->bookkeeper();
        $expense = $this->fundExpense($headers, '400');
        $fund = app(FundDeal::class)();

        // Act
        $response = $this->reverse($headers, $this->onFund($expense));

        // Assert — النقدُ والقيمةُ كما كانا، ولا سطرَ للمصروف في سجلّ نقد الصندوق.
        $response->assertCreated()->assertJsonPath('data.reverses_expense_id', $expense);
        $this->assertSame('10000.00', app(FundCash::class)());
        $this->assertSame($valueBefore, app(FundValuation::class)()['total']);
        $this->assertSame('10000.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('0.00', $this->profitOf($partner, $fund));
        $ledgerTypes = array_column(app(FundCashLedger::class)->page(1)['rows'], 'type');
        $this->assertNotContains('expense', $ledgerTypes);
    }

    public function test_a_reversed_pair_drops_out_of_the_periods_expenses(): void
    {
        // Arrange — في سبتمبر مصروفان: ٤٠٠ عُكس، و١٠٠ بقي.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $this->fundPartner('10000.00');
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $reversed = $this->fundExpense($headers, '400');
        $this->reverse($headers, $this->onFund($reversed))->assertCreated();
        $this->fundExpense($headers, '100');

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = app(CloseInvestmentPeriod::class)(actorId: null);

        // Assert
        $this->assertSame('100.00', (string) $period->expenses_amount);
    }

    public function test_a_correction_after_its_period_closed_lands_in_the_open_one(): void
    {
        // Arrange — مصروفُ سبتمبر، وأُقفل سبتمبر، وفُتح أكتوبر — ثم ظهر أن الفاتورة مكرّرة.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);
        $this->fundPartner('10000.00');
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $expense = $this->fundExpense($headers, '400');
        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null);
        $october = app(OpenInvestmentPeriod::class)(actorId: null);

        // Act
        $response = $this->reverse($headers, $this->onFund($expense));

        // Assert — سبتمبر أُعلنت أرقامُه فلا يدخله صفّ، والتصحيحُ يقع على أكتوبر.
        $response->assertCreated();
        $periods = InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Reversal->value)
            ->whereHas('reversedEntry', fn ($q) => $q->where('type', WalletEntryType::Loss->value))
            ->pluck('investment_period_id')
            ->unique()
            ->values()
            ->all();
        $this->assertSame([(int) $october->id], array_map('intval', $periods));
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
    }
}
