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
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «مصاريف الصندوق» — كلُّ مصاريفه في قائمةٍ واحدة، وبجانب كلٍّ فترتُه، وفلترٌ بالفترة.
 *
 * **فترةُ المصروف هي التي يقع يومُه فيها** — قاعدةُ «مصاريف الفترة» في شاشة الفترة نفسُها، فمجموعُ
 * القائمة مفلترةً بفترةٍ هو مجموعُ تلك الشاشة بعينه.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundExpensesTest extends TestCase
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

    /** سبتمبر مفتوح، وفيه شريكان. */
    private function september(): InvestmentPeriod
    {
        Carbon::setTestNow('2026-09-01 09:00:00');
        $period = app(OpenInvestmentPeriod::class)(actorId: null);
        $this->fundPartner('سالم', '6000.00');
        $this->fundPartner('خالد', '4000.00');

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
     * @param  array<string, int|string>  $query
     */
    private function expenses(array $headers, array $query = []): TestResponse
    {
        return $this->getJson('/api/v1/investment/expenses?'.http_build_query($query), $headers);
    }

    public function test_it_lists_every_fund_expense_with_the_period_its_day_falls_in(): void
    {
        // Arrange — ٤٠٠ في سبتمبر، و١٠٠ في أكتوبر بعد إقفاله.
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400', name: 'شحن سبتمبر');
        $october = $this->october();
        Carbon::setTestNow('2026-10-05 09:00:00');
        $this->fundExpense($headers, '100', name: 'نقل أكتوبر');

        // Act
        $response = $this->expenses($headers);

        // Assert — الأحدثُ أولاً، وكلٌّ برمز فترته.
        $response->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.name', 'نقل أكتوبر')
            ->assertJsonPath('data.0.amount', '100.00')
            ->assertJsonPath('data.0.kind_label', 'شحن')
            ->assertJsonPath('data.0.period.id', $october->id)
            ->assertJsonPath('data.0.period.code', $october->code)
            ->assertJsonPath('data.0.counted', true)
            ->assertJsonPath('data.1.name', 'شحن سبتمبر')
            ->assertJsonPath('data.1.period.code', $september->code)
            ->assertJsonPath('meta.expenses_total', '500.00')
            ->assertJsonPath('meta.total', 2);
    }

    public function test_it_filters_by_period(): void
    {
        // Arrange
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400', name: 'شحن سبتمبر');
        $this->october();
        Carbon::setTestNow('2026-10-05 09:00:00');
        $this->fundExpense($headers, '100', name: 'نقل أكتوبر');

        // Act
        $response = $this->expenses($headers, ['period_id' => $september->id]);

        // Assert — سبتمبر وحده، ومجموعُه.
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'شحن سبتمبر')
            ->assertJsonPath('meta.expenses_total', '400.00')
            ->assertJsonPath('meta.total', 1);
    }

    public function test_a_reversed_expense_stays_a_row_and_leaves_the_total(): void
    {
        // Arrange
        $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $reversed = $this->fundExpense($headers, '400');
        $this->fundExpense($headers, '100');
        $this->postJson("/api/v1/investment/expenses/{$reversed}/reverse", ['reason' => 'فاتورة مكرّرة'], $headers)
            ->assertCreated();

        // Act
        $response = $this->expenses($headers);

        // Assert — سطرٌ يقول إنه عُكس ولماذا، لا سطرٌ ثانٍ لعكسه.
        $row = collect($response->assertOk()->json('data'))->firstWhere('id', $reversed);
        $response->assertJsonCount(2, 'data')->assertJsonPath('meta.expenses_total', '100.00');
        $this->assertTrue($row['is_reversed']);
        $this->assertFalse($row['counted']);
        $this->assertSame('فاتورة مكرّرة', $row['reversal']['reason']);
    }

    public function test_the_filtered_total_is_the_period_screens_total(): void
    {
        // Arrange — سبتمبر بمصروفٍ معدود، ثم فاتورةٌ بتاريخه سُجِّلت بعد إقفاله.
        $september = $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400');
        $this->october();
        Carbon::setTestNow('2026-10-05 09:00:00');
        $late = $this->fundExpense($headers, '250', on: '2026-09-20');

        // Act
        $listed = $this->expenses($headers, ['period_id' => $september->id]);
        $periodScreen = $this->getJson("/api/v1/investment/periods/{$september->id}/expenses", $headers);

        // Assert — المتأخّرةُ في سبتمبر بتاريخها، غيرَ معدودة فيه كما في شاشته.
        $row = collect($listed->assertOk()->json('data'))->firstWhere('id', $late);
        $this->assertSame($september->code, $row['period']['code']);
        $this->assertFalse($row['counted']);
        $this->assertTrue($row['recorded_after_close']);
        $this->assertSame(
            $periodScreen->assertOk()->json('data.totals.expenses_total'),
            $listed->json('meta.expenses_total'),
        );
        $listed->assertJsonPath('meta.expenses_total', '400.00');
    }

    public function test_landed_costs_and_old_deals_expenses_are_not_listed(): void
    {
        // Arrange — شحنٌ دخل تكلفةَ البضاعة، وجمركُ صفقةٍ قديمة، ومصروفُ صندوقٍ واحد.
        $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $fundExpense = $this->fundExpense($headers, '300');
        InvestorDealExpense::factory()->create([
            'investor_deal_id' => app(FundDeal::class)->idOrNull(),
            'is_landed' => true,
            'amount' => '900.00',
        ]);
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

        // Act
        $response = $this->expenses($headers);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $fundExpense)
            ->assertJsonPath('meta.expenses_total', '300.00');
    }

    public function test_an_expense_before_the_first_period_has_no_period(): void
    {
        // Arrange — مصروفٌ على الصندوق بتاريخٍ قبل أن تُفتح أوّلُ فترة.
        $this->september();
        $headers = $this->bookkeeper();
        $early = InvestorDealExpense::factory()->create([
            'investor_deal_id' => app(FundDeal::class)->idOrNull(),
            'incurred_on' => '2026-08-15',
            'amount' => '50.00',
        ]);

        // Act
        $response = $this->expenses($headers);

        // Assert — يُعرض بلا فترة، ويُعدّ في «كل المصاريف».
        $response->assertOk()
            ->assertJsonPath('data.0.id', $early->id)
            ->assertJsonPath('data.0.period', null)
            ->assertJsonPath('data.0.counted', true)
            ->assertJsonPath('meta.expenses_total', '50.00');
    }

    public function test_the_total_covers_every_page_not_the_one_shown(): void
    {
        // Arrange
        $this->september();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $this->fundExpense($headers, '400');
        $this->fundExpense($headers, '100');

        // Act
        $response = $this->expenses($headers, ['per_page' => 1]);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.expenses_total', '500.00');
    }

    public function test_an_unknown_period_is_refused(): void
    {
        // Arrange
        $this->september();
        $headers = $this->bookkeeper();

        // Act
        $response = $this->expenses($headers, ['period_id' => 999999]);

        // Assert
        $response->assertUnprocessable();
    }

    public function test_reading_takes_the_view_grant(): void
    {
        // Arrange
        $this->september();

        // Act
        $response = $this->expenses($this->bookkeeper(mayView: false));

        // Assert
        $response->assertForbidden();
    }
}
