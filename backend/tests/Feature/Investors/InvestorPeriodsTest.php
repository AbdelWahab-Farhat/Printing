<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriodShare;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * فتراتُه على صفحته — بدل الصفقات. قرارُ المالك 2026-09-25: «عرض الفترات بدلا من الصفقات».
 *
 * **وربحُه في الفترة هو ما تقوله شاشةُ الفترة له**، لا حسابٌ ثانٍ: الصفُّ يُفتح عليها، وصفٌّ يقول
 * رقماً وشاشتُه تقول غيرَه يطرح سؤالاً لا جوابَ له.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestorPeriodsTest extends TestCase
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
    private function headers(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewInvestors->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** ربحٌ يُكتب كما يكتبه `PostDealShare`: بمصدره وختمِ فترته. */
    private function accrue(int $investorId, int $dealId, string $amount, int $orderId, int $periodId): InvestorWalletEntry
    {
        $entry = new InvestorWalletEntry(['amount' => $amount, 'occurred_at' => now()]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $dealId;
        $entry->type = WalletEntryType::Profit;
        $entry->source_type = 'order';
        $entry->source_id = $orderId;
        $entry->source_sequence = 1;
        $entry->investment_period_id = $periodId;
        $entry->save();

        return $entry;
    }

    /** العكسُ كما يكتبه `PostDealShare::reverse()` — بلا مصدرٍ خاصّ به. */
    private function reverse(InvestorWalletEntry $original): void
    {
        $reversal = new InvestorWalletEntry(['amount' => (string) $original->amount, 'occurred_at' => now()]);

        $reversal->investor_id = $original->investor_id;
        $reversal->investor_deal_id = $original->investor_deal_id;
        $reversal->investment_period_id = $original->investment_period_id;
        $reversal->type = WalletEntryType::Reversal;
        $reversal->reverses_entry_id = $original->getKey();
        $reversal->save();
    }

    private function share(InvestmentPeriod $period, Investor $investor, string $percent): void
    {
        InvestmentPeriodShare::query()->create([
            'investment_period_id' => $period->id,
            'investor_id' => $investor->id,
            'units' => '1000.000000',
            'share_percent' => $percent,
        ]);
    }

    private function september(): InvestmentPeriod
    {
        return InvestmentPeriod::factory()->create([
            'code' => 'P1',
            'starts_on' => '2026-09-01',
            'ends_on' => '2026-09-30',
            'subscription_closes_on' => '2026-09-07',
        ]);
    }

    /** بعد سبتمبر لا معها: «مفتوحةٌ واحدة» قيدٌ في القاعدة. */
    private function october(): InvestmentPeriod
    {
        return InvestmentPeriod::factory()->create([
            'code' => 'P2',
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]);
    }

    /**
     * تُقفَل **بعد** أن يُكتب ربحُها — المغلقةُ لا تقبل صفّاً، وقيدُ `_shape` يشترط أرقامَ الإقفال
     * كلَّها معاً.
     */
    private function seal(InvestmentPeriod $period): void
    {
        $period->forceFill([
            'status' => PeriodStatus::Closed,
            'closed_at' => now(),
            'closing_stock_cost' => '0.00',
            'closing_cash' => '0.00',
            'sales_revenue' => '0.00',
            'cost_of_goods_sold' => '0.00',
            'cost_damaged' => '0.00',
            'cost_short' => '0.00',
            'expenses_amount' => '0.00',
            'net_profit' => '0.00',
            'investors_pool' => '0.00',
            'company_share' => '0.00',
            'through_consumption_id' => 0,
            'through_movement_id' => 0,
            'through_wallet_entry_id' => 0,
            'through_cash_entry_id' => 0,
        ])->save();
    }

    public function test_his_page_lists_each_period_he_shared_newest_first_with_his_profit_in_it(): void
    {
        // Arrange — شريكٌ في الفترتين: سبتمبر أعطته طلبيتين، وأكتوبر طلبيةً واحدة.
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create();

        $september = $this->september();
        $this->share($september, $ahmad, '100.000000');
        $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', (int) Order::factory()->create()->id, (int) $september->id);
        $this->accrue((int) $ahmad->id, (int) $deal->id, '200.00', (int) Order::factory()->create()->id, (int) $september->id);
        $this->seal($september);

        $october = $this->october();
        $this->share($october, $ahmad, '100.000000');
        $this->accrue((int) $ahmad->id, (int) $deal->id, '120.00', (int) Order::factory()->create()->id, (int) $october->id);

        // Act
        $response = $this->withHeaders($this->headers())->getJson("/api/v1/investors/{$ahmad->id}");

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data.periods')
            ->assertJsonPath('data.periods.0.id', (int) $october->id)
            ->assertJsonPath('data.periods.0.code', 'P2')
            ->assertJsonPath('data.periods.0.profit', '120.00')
            ->assertJsonPath('data.periods.1.id', (int) $september->id)
            ->assertJsonPath('data.periods.1.code', 'P1')
            ->assertJsonPath('data.periods.1.profit', '500.00');
    }

    public function test_a_period_he_had_no_share_in_is_not_on_his_page(): void
    {
        // Arrange — سالم وحده شريكُ سبتمبر؛ أحمد لم يدخلها.
        $ahmad = Investor::factory()->create();
        $salem = Investor::factory()->create();

        $this->share($this->september(), $salem, '100.000000');

        // Act
        $response = $this->withHeaders($this->headers())->getJson("/api/v1/investors/{$ahmad->id}");

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data.periods');
    }

    public function test_a_period_he_shared_that_has_made_nothing_yet_is_listed_at_zero(): void
    {
        // Arrange — أكتوبر بدأت ولم تُسلَّم فيها طلبيةٌ بعد: شريكٌ فيها، وربحُه صفر.
        $ahmad = Investor::factory()->create();

        $this->seal($this->september());
        $this->share($this->october(), $ahmad, '100.000000');

        // Act
        $response = $this->withHeaders($this->headers())->getJson("/api/v1/investors/{$ahmad->id}");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.periods')
            ->assertJsonPath('data.periods.0.code', 'P2')
            ->assertJsonPath('data.periods.0.profit', '0.00');
    }

    public function test_his_profit_in_a_period_is_what_the_period_screen_says_he_took(): void
    {
        // Arrange — طلبيةٌ قُيِّدت ثم عُكست، وأخرى باقية، وشريكٌ ثانٍ في الفترة نفسها.
        $september = $this->september();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create();
        $salem = Investor::factory()->create();

        $this->share($september, $ahmad, '75.000000');
        $this->share($september, $salem, '25.000000');

        $undone = $this->accrue((int) $ahmad->id, (int) $deal->id, '450.00', (int) Order::factory()->create()->id, (int) $september->id);
        $this->reverse($undone);
        $kept = Order::factory()->create();
        $this->accrue((int) $ahmad->id, (int) $deal->id, '150.00', (int) $kept->id, (int) $september->id);
        $this->accrue((int) $salem->id, (int) $deal->id, '50.00', (int) $kept->id, (int) $september->id);
        $this->seal($september);

        $headers = $this->headers();

        // Act
        $page = $this->withHeaders($headers)->getJson("/api/v1/investors/{$ahmad->id}");
        $screen = $this->withHeaders($headers)->getJson("/api/v1/investment/periods/{$september->id}/orders");

        // Assert
        $taken = collect($screen->json('data.investors'))->firstWhere('investor_id', (int) $ahmad->id);

        $page->assertOk()->assertJsonPath('data.periods.0.profit', '150.00');
        $this->assertSame($taken['amount'], $page->json('data.periods.0.profit'));
    }
}
