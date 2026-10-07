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
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealShare;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «المصاريف» في شاشة الفترة — ما خرج من الصندوق في أيامها، وما تحمّله المستثمرون منه.
 *
 * ```
 * expenses     ←  مصاريفُ الصندوق المؤرّخةُ في نافذتها — ومجموعُ المعدود منها = expenses_amount المجمّد
 * corrections  ←  ما وقع على محافظ المستثمرين فيها من مصاريف فتراتٍ أُقفلت
 * ```
 *
 * شريكان بستّة آلاف وأربعة، ونصيبُ المستثمرين نصفُ الربح: مصروفُ ٤٠٠ يحمّلهم ٢٠٠ — ١٢٠ و٨٠.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PeriodExpensesTest extends TestCase
{
    use RefreshDatabase;

    private Investor $big;

    private Investor $small;

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
    private function bookkeeper(bool $mayView = true): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, array_filter([
            $mayView ? PermissionName::ViewInvestors : null,
            PermissionName::RecordDealExpenses,
            PermissionName::ReverseInvestorMoney,
        ])));

        $this->app['auth']->forgetGuards();

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** شريكٌ بوحداتٍ في الصندوق — مالٌ نقدٌ على الطاولة ثم اشتراكٌ به. */
    private function fundPartner(string $name, string $amount): Investor
    {
        $investor = Investor::factory()->create(['name' => $name]);

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

    /** سبتمبر مفتوح، وفيه الشريكان. */
    private function september(): InvestmentPeriod
    {
        Carbon::setTestNow('2026-09-01 09:00:00');
        $period = app(OpenInvestmentPeriod::class)(actorId: null);
        $this->big = $this->fundPartner('سالم', '6000.00');
        $this->small = $this->fundPartner('خالد', '4000.00');

        return $period;
    }

    /** يُقفل سبتمبر ويفتح أكتوبر. */
    private function october(): InvestmentPeriod
    {
        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null);

        return app(OpenInvestmentPeriod::class)(actorId: null);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function fundExpense(array $headers, string $amount, ?string $on = null, string $name = 'شحن'): int
    {
        return (int) $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => $name,
            'amount' => $amount,
            'incurred_on' => $on ?? now()->toDateString(),
        ], $headers)->assertOk()->json('data.id');
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function reverse(array $headers, int $expense): void
    {
        $this->postJson("/api/v1/investment/expenses/{$expense}/reverse", ['reason' => 'فاتورة مكرّرة'], $headers)
            ->assertCreated();
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function expensesOf(array $headers, InvestmentPeriod $period): TestResponse
    {
        return $this->getJson("/api/v1/investment/periods/{$period->id}/expenses", $headers);
    }

    public function test_it_lists_the_funds_expenses_and_what_each_investor_bore(): void
    {
        // Arrange — ٤٠٠ شحنٌ و١٠٠ نقلٌ على الصندوق.
        $period = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $shipping = $this->fundExpense($headers, '400');
        Carbon::setTestNow('2026-09-12 09:00:00');
        $this->fundExpense($headers, '100', name: 'نقل');

        // Act
        $response = $this->expensesOf($headers, $period);

        // Assert — الأحدثُ أولاً، والمستثمرون بنسبهم: ٦٠٪ و٤٠٪ من النصف.
        $response->assertOk()
            ->assertJsonPath('data.period.code', $period->code)
            ->assertJsonCount(2, 'data.expenses')
            ->assertJsonPath('data.expenses.0.name', 'نقل')
            ->assertJsonPath('data.expenses.1.id', $shipping)
            ->assertJsonPath('data.expenses.1.amount', '400.00')
            ->assertJsonPath('data.expenses.1.kind_label', 'شحن')
            ->assertJsonPath('data.expenses.1.counted', true)
            ->assertJsonPath('data.expenses.1.can_reverse', true)
            ->assertJsonPath('data.expenses.1.investors_amount', '200.00')
            ->assertJsonPath('data.expenses.1.investors.0.name', 'سالم')
            ->assertJsonPath('data.expenses.1.investors.0.amount', '120.00')
            ->assertJsonPath('data.expenses.1.investors.1.amount', '80.00')
            ->assertJsonPath('data.corrections', [])
            ->assertJsonPath('data.totals.expenses_total', '500.00')
            ->assertJsonPath('data.totals.investors_total', '250.00')
            ->assertJsonPath('data.totals.frozen_total', null);
    }

    public function test_an_old_deals_expense_is_not_the_funds(): void
    {
        // Arrange — صفقةٌ قديمة مفتوحة تدفع جماركها في سبتمبر نفسه.
        $period = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $deal = InvestorDeal::factory()->open()->create(['investor_profit_share_percent' => '50.00']);
        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->id,
            'investor_id' => Investor::factory()->create()->id,
            'share_percent' => '100.0000',
        ]);
        $this->postJson("/api/v1/investor-deals/{$deal->id}/expenses", [
            'kind' => 'customs',
            'name' => 'جمرك',
            'amount' => '1000',
            'incurred_on' => now()->toDateString(),
        ], $headers)->assertOk();
        $this->fundExpense($headers, '300');

        // Act
        $response = $this->expensesOf($headers, $period);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.expenses')
            ->assertJsonPath('data.expenses.0.amount', '300.00')
            ->assertJsonPath('data.totals.expenses_total', '300.00')
            ->assertJsonPath('data.totals.investors_total', '150.00');
    }

    public function test_an_expense_reversed_inside_its_open_period_is_not_counted(): void
    {
        // Arrange
        $period = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $expense = $this->fundExpense($headers, '400');
        $this->fundExpense($headers, '100');
        $this->reverse($headers, $expense);

        // Act
        $response = $this->expensesOf($headers, $period);

        // Assert — يبقى سطراً يقول إنه عُكس، ولا يُعدّ ولا يحمّل أحداً.
        $reversed = collect($response->assertOk()->json('data.expenses'))->firstWhere('id', $expense);
        $this->assertFalse($reversed['counted']);
        $this->assertTrue($reversed['is_reversed']);
        $this->assertSame('فاتورة مكرّرة', $reversed['reversal']['reason']);
        $this->assertSame($period->code, $reversed['reversal']['period_code']);
        $this->assertSame('0.00', $reversed['investors_amount']);
        $this->assertSame([], $reversed['investors']);
        $response->assertJsonPath('data.totals.expenses_total', '100.00')
            ->assertJsonPath('data.totals.investors_total', '50.00');
    }

    public function test_a_closed_periods_expense_offers_no_reversal(): void
    {
        // Arrange — مصروفُ سبتمبر، وأُقفل سبتمبر.
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400');
        $this->october();

        // Act
        $response = $this->expensesOf($headers, $september);

        // Assert — أرقامُه أُعلنت؛ الخادمُ يقولها فلا يُرسم الزرّ.
        $response->assertOk()
            ->assertJsonPath('data.expenses.0.counted', true)
            ->assertJsonPath('data.expenses.0.can_reverse', false)
            ->assertJsonPath('data.totals.expenses_total', '400.00')
            ->assertJsonPath('data.totals.frozen_total', '400.00');
    }

    public function test_a_reversal_from_before_the_rule_still_counts_in_its_closed_period(): void
    {
        // Arrange — قبل 2026-10-05 كان مصروفُ فترةٍ مغلقة يُعكس، فيقع ردُّه على المفتوحة. صفوفٌ
        // كهذه باقيةٌ في القاعدة، وسبتمبر أُقفل عليها معدودة. تُكتب هنا يدوياً: البابُ أُغلق.
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $expense = $this->fundExpense($headers, '400');
        $october = $this->october();
        Carbon::setTestNow('2026-10-03 09:00:00');
        $original = InvestorDealExpense::query()->findOrFail($expense);
        $reversal = $original->replicate();
        $reversal->reverses_expense_id = $original->id;
        $reversal->incurred_on = now()->toDateString();
        $reversal->notes = 'فاتورة مكرّرة';
        $reversal->save();

        // Act
        $response = $this->expensesOf($headers, $september);

        // Assert — سبتمبر على أرقامه المعلنة، والسطرُ يقول أين وقع الردّ.
        $response->assertOk()
            ->assertJsonPath('data.expenses.0.counted', true)
            ->assertJsonPath('data.expenses.0.is_reversed', true)
            ->assertJsonPath('data.expenses.0.can_reverse', false)
            ->assertJsonPath('data.expenses.0.reversal.period_code', $october->code)
            ->assertJsonPath('data.totals.expenses_total', '400.00')
            ->assertJsonPath('data.totals.frozen_total', '400.00');
    }

    public function test_an_expense_dated_in_a_closed_period_is_charged_to_the_open_one(): void
    {
        // Arrange — أُقفل سبتمبر، ثم وصلت فاتورةٌ مؤرّخةٌ في ٢٠ منه.
        $september = $this->september();
        $october = $this->october();
        Carbon::setTestNow('2026-10-05 09:00:00');
        $headers = $this->bookkeeper();
        $late = $this->fundExpense($headers, '400', on: '2026-09-20');

        // Act
        $inSeptember = $this->expensesOf($headers, $september);
        $inOctober = $this->expensesOf($headers, $october);

        // Assert — يُرى في سبتمبر غيرَ معدود، وتحميلُه في أكتوبر.
        $inSeptember->assertOk()
            ->assertJsonPath('data.expenses.0.id', $late)
            ->assertJsonPath('data.expenses.0.counted', false)
            ->assertJsonPath('data.expenses.0.recorded_after_close', true)
            ->assertJsonPath('data.totals.expenses_total', '0.00')
            ->assertJsonPath('data.totals.frozen_total', '0.00');
        $inSeptember->assertJsonPath('data.expenses.0.can_reverse', true);
        $inOctober->assertOk()
            ->assertJsonPath('data.corrections.0.id', $late)
            ->assertJsonPath('data.corrections.0.can_reverse', true)
            ->assertJsonPath('data.corrections.0.investors_amount', '200.00')
            ->assertJsonPath('data.totals.investors_total', '200.00');
    }

    public function test_the_closed_periods_figures_carry_its_expenses(): void
    {
        // Arrange
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400');
        $this->october();

        // Act
        $response = $this->getJson('/api/v1/investment/periods', $headers);

        // Assert — المفتوحةُ بلا أرقام، والمغلقةُ بمصاريفها ونصيب المستثمرين منها.
        $periods = collect($response->assertOk()->json('data'))->keyBy('id');
        $this->assertSame('400.00', $periods[$september->id]['expenses_amount']);
        $this->assertSame('200.00', $periods[$september->id]['expenses_on_investors']);
        $this->assertNull($periods->firstWhere('status', 'open')['expenses_amount']);
        $this->assertNull($periods->firstWhere('status', 'open')['expenses_on_investors']);
    }

    public function test_reading_takes_the_view_grant(): void
    {
        // Arrange
        $period = $this->september();

        // Act
        $response = $this->expensesOf($this->bookkeeper(mayView: false), $period);

        // Assert
        $response->assertForbidden();
    }
}
