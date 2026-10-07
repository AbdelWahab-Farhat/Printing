<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\Investor;
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
 * نصيبُ الشركة من مصروف الصندوق تدفعه الشركة — CONTINUOUS-FUND-DESIGN §١٠، الخيار ب.
 *
 * ```
 * مصروفُ ٤٠٠، ونصيبُ المستثمرين ٥٠٪:
 *   نقدُ الصندوق   −400 مصروف   +200 نصيب الشركة من المصروف   =  −200
 *   محفظةُ الشريك  −200 خسارة
 * ```
 *
 * قبل الإصلاح كان النقدُ ينقص ٤٠٠ والمحفظةُ ٢٠٠، فتصير قيمةُ وحدات الشريك أقلَّ مما يقوله
 * دفترُه بنصيب الشركة — وهو ما كشفه الفحص (§١٠).
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundExpenseCompanyShareTest extends TestCase
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
    private function bookkeeper(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::RecordDealExpenses->value,
            PermissionName::ReverseInvestorMoney->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** سبتمبر مفتوح، وفيه شريكٌ بعشرة آلاف. */
    private function partner(): Investor
    {
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();

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

        return $investor;
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function expense(array $headers, string $amount): int
    {
        return (int) $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => 'شحن',
            'amount' => $amount,
            'incurred_on' => now()->toDateString(),
        ], $headers)->assertOk()->json('data.id');
    }

    private function coverOf(int $expense): ?InvestmentCashEntry
    {
        return InvestmentCashEntry::query()
            ->where('type', CashEntryType::ExpenseCoveredByCompany->value)
            ->where('source_type', AuditSubject::InvestorDealExpense->value)
            ->where('source_id', $expense)
            ->first();
    }

    /** ما تساويه وحداتُ الشريك بسعر اليوم — وهو ما يُسحب به. */
    private function worth(Investor $investor): string
    {
        return bcmul(app(FundUnits::class)->heldBy((int) $investor->id), app(UnitPrice::class)(), 2);
    }

    public function test_the_fund_loses_only_what_the_investors_were_charged(): void
    {
        // Arrange
        $investor = $this->partner();
        Carbon::setTestNow('2026-09-10 09:00:00');

        // Act
        $expense = $this->expense($this->bookkeeper(), '400');

        // Assert — النقدُ ينقص ٢٠٠ لا ٤٠٠، والصفُّ باسم الشركة بتاريخ المصروف.
        $this->assertSame('9800.00', app(FundCash::class)());
        $cover = $this->coverOf($expense);
        $this->assertNotNull($cover);
        $this->assertSame('200.00', (string) $cover->amount);
        $this->assertSame('2026-09-10', $cover->occurred_at->toDateString());
        $this->assertSame('9800.00', $this->worth($investor));
    }

    public function test_after_the_close_the_units_are_worth_what_the_ledger_says(): void
    {
        // Arrange — فترةُ الفحص: لا مبيعات، ومصروفُ ٤٠٠.
        $investor = $this->partner();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $this->expense($this->bookkeeper(), '400');

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null);

        // Assert — ٩٬٨٠٠ في الدفتر و٩٬٨٠٠ قيمةُ الوحدات، لا ٩٬٦٠٠.
        $capital = app(InvestorBalances::class)->forDeal((int) app(FundDeal::class)->idOrNull())['per_investor'][$investor->id]['capital'];
        $this->assertSame('9800.00', $capital);
        $this->assertSame('9800.00', $this->worth($investor));
    }

    public function test_reversing_the_expense_takes_the_companys_share_back_with_it(): void
    {
        // Arrange
        $this->partner();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $headers = $this->bookkeeper();
        $expense = $this->expense($headers, '400');

        // Act
        $this->postJson("/api/v1/investment/expenses/{$expense}/reverse", ['reason' => 'فاتورة مكرّرة'], $headers)
            ->assertCreated();

        // Assert — النقدُ كما كان، ونصيبُ الشركة معكوس.
        $this->assertSame('10000.00', app(FundCash::class)());
        $this->assertTrue($this->coverOf($expense)->reversedBy()->exists());
    }

    public function test_the_expenses_rows_carry_the_time_it_was_recorded_on_its_own_day(): void
    {
        // Arrange — العاشرةُ ليلاً في طرابلس يوم ٥ أكتوبر (٢٠:٠٠ UTC)، ومصروفان: لليوم، ولـ٢٠ سبتمبر.
        $this->partner();
        Carbon::setTestNow('2026-10-05 20:00:00');
        $headers = $this->bookkeeper();

        // Act
        $today = $this->expense($headers, '400');
        $backdated = (int) $this->postJson('/api/v1/investment/expenses', [
            'kind' => 'shipping',
            'name' => 'شحن متأخّر',
            'amount' => '100',
            'incurred_on' => '2026-09-20',
        ], $headers)->assertOk()->json('data.id');

        // Assert — لا منتصفَ ليل: يومُه المختار، في ساعة تسجيله — في الدفترين.
        $momentsOf = fn (int $id): array => [
            InvestmentCashEntry::query()->where('source_type', AuditSubject::InvestorDealExpense->value)
                ->where('source_id', $id)->orderBy('source_sequence')
                ->pluck('occurred_at')->map->toDateTimeString()->all(),
            DB::table('treasury_movements')->where('source_type', AuditSubject::InvestorDealExpense->value)
                ->where('source_id', $id)->value('occurred_at'),
        ];
        $this->assertSame([['2026-10-05 20:00:00', '2026-10-05 20:00:00'], '2026-10-05 20:00:00'], $momentsOf($today));
        $this->assertSame([['2026-09-20 20:00:00', '2026-09-20 20:00:00'], '2026-09-20 20:00:00'], $momentsOf($backdated));
    }

    public function test_the_backfill_covers_old_expenses_once_and_dates_them_today(): void
    {
        // Arrange — مصروفٌ من قبل الإصلاح: لا صفَّ باسم الشركة.
        $this->partner();
        Carbon::setTestNow('2026-09-10 09:00:00');
        $expense = $this->expense($this->bookkeeper(), '400');
        $this->coverOf($expense)->forceDelete();
        Carbon::setTestNow('2026-10-05 09:00:00');

        // Act
        $this->artisan('investment:cover-company-expense-shares')->assertSuccessful();
        $afterDryRun = $this->coverOf($expense);
        $this->artisan('investment:cover-company-expense-shares', ['--apply' => true])->assertSuccessful();
        $this->artisan('investment:cover-company-expense-shares', ['--apply' => true])->assertSuccessful();

        // Assert
        $this->assertNull($afterDryRun);
        $this->assertSame(
            1,
            InvestmentCashEntry::query()->where('type', CashEntryType::ExpenseCoveredByCompany->value)->count(),
        );
        $this->assertSame('200.00', (string) $this->coverOf($expense)->amount);
        $this->assertSame('2026-10-05', $this->coverOf($expense)->occurred_at->toDateString());
        $this->assertSame('9800.00', app(FundCash::class)());
    }
}
