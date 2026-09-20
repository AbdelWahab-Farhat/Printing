<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\NoPeriodIsOpen;
use App\Domain\Investor\Exceptions\PeriodHasNotEndedYet;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\InvestorBalances;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * إقفالُ فترة — وهو الباب الوحيد الذي يصير به الربحُ قابلاً للسحب.
 *
 * الشريحة ١هـ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * **ثلاثةُ فروقٍ عن إقفال الصفقة القديم، وكلُّها نصُّ ما طلبه المالك:**
 *
 * 1. **لا يشترط رفّاً فارغاً** — نقيضُه هو الترحيل.
 * 2. **لا يردّ رأسَ المال** — «عدم تصفير رأس المال عند الانتقال لفترة جديدة».
 * 3. **يُفرج عن الربح وحده**، فينتقل من «غير مسوّى» إلى محفظةٍ يُسحب منها.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class CloseInvestmentPeriodTest extends TestCase
{
    use RefreshDatabase;

    private function openPeriod(): void
    {
        app(OpenInvestmentPeriod::class)(actorId: null);
    }

    private function close(?string $overrideReason = null): mixed
    {
        return app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: $overrideReason);
    }

    /** ربحٌ قُيِّد لمستثمر على دفعةِ شراء — كما يكتبه `PostDealShare` عند تسليم طلبية. */
    private function accrue(int $investorId, int $dealId, string $amount, int $orderId): void
    {
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investorId,
            'investor_deal_id' => $dealId,
            'type' => WalletEntryType::Profit->value,
            'amount' => $amount,
            'source_type' => 'order',
            'source_id' => $orderId,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_closing_moves_the_profit_into_a_wallet_it_can_be_drawn_from(): void
    {
        // Arrange — ربحٌ متراكمٌ أثناء الفترة، غيرُ مسوّىً ولا يُسحب.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $this->accrue((int) $investor->id, (int) $deal->id, '1846.00', 91);

        $before = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $before['wallet']['profit']);

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert — الجيبان تبادلا، ولم يُخلق دينار.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('1846.00', $after['wallet']['profit']);
        $this->assertSame('0.00', $after['deals'][(int) $deal->id]['profit']);
    }

    public function test_capital_is_not_returned_and_stock_is_not_cleared(): void
    {
        // Arrange — نقيضُ إقفال الصفقة القديم بالضبط.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Allocation->value,
            'amount' => '50000.00',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert — رأسُ المال حيث كان، ولا صفَّ إرجاعٍ واحد.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('50000.00', $after['deals'][(int) $deal->id]['capital']);
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'type' => WalletEntryType::Release->value,
        ]);
    }

    public function test_a_closed_period_carries_its_figures_and_its_watermarks(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $this->accrue((int) $investor->id, (int) $deal->id, '1846.00', 91);

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $period = $this->close();

        // Assert — «حتى أين حُسبت» جوابٌ مكتوب لا استنتاجٌ من تواريخ.
        $this->assertSame(PeriodStatus::Closed, $period->status);
        $this->assertNotNull($period->closed_at);
        $this->assertSame('1846.00', (string) $period->investors_pool);
        $this->assertNotNull($period->through_wallet_entry_id);
        $this->assertNotNull($period->through_consumption_id);
    }

    public function test_a_loss_is_taken_out_of_the_capital_that_bore_it(): void
    {
        // Arrange — قرارُ المالك: «عادي ممكن تخصمها من رأس المال». والخصمُ من رأس ماله في دفعته
        // وحدها، لا من مال غيره ولا من دفعةٍ أخرى.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Allocation->value,
            'amount' => '30000.00',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Loss->value,
            'amount' => '6500.00',
            'source_type' => 'order',
            'source_id' => 92,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert — ٣٠٬٠٠٠ صارت ٢٣٬٥٠٠، والجيبُ نظيف، ولا شيء أُفرِج عنه.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('23500.00', $after['deals'][(int) $deal->id]['capital']);
        $this->assertSame('0.00', $after['deals'][(int) $deal->id]['profit']);
        $this->assertSame('0.00', $after['wallet']['profit']);

        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::CapitalWritedown->value,
            'amount' => '6500.00',
        ]);
    }

    public function test_a_loss_beyond_his_capital_is_borne_by_the_company_on_a_line_of_its_own(): void
    {
        // Arrange — لا شيء في الاتفاق يجعله يدين بأكثر ممّا وضع.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Allocation->value,
            'amount' => '1000.00',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Loss->value,
            'amount' => '2500.00',
            'source_type' => 'order',
            'source_id' => 93,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert — ١٬٠٠٠ من ماله، و١٬٥٠٠ على الشركة بسطرٍ يظهر في كشفه.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $after['deals'][(int) $deal->id]['capital']);
        $this->assertSame('0.00', $after['deals'][(int) $deal->id]['profit']);

        $this->assertDatabaseHas('investor_wallet_entries', [
            'type' => WalletEntryType::CapitalWritedown->value,
            'amount' => '1000.00',
        ]);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'type' => WalletEntryType::LossAbsorbedByCompany->value,
            'amount' => '1500.00',
        ]);
    }

    public function test_a_period_still_taking_orders_is_not_closed_early(): void
    {
        // Arrange — نافذتُها إلى ١٤ أكتوبر؛ إقفالُها في الثاني يترك اثني عشر يوماً تقع
        // طلبياتُها داخل نافذةٍ مغلقة، فيأتي ربحُها ولا يجد فترةً يقع فيها.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        // Assert
        $this->expectException(PeriodHasNotEndedYet::class);

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
    }

    public function test_an_early_close_is_possible_with_a_reason_that_is_recorded(): void
    {
        // Arrange — البابُ مفتوحٌ لمن يقرّر وهو يعلم، وسببُه يُكتب باسم فاعله.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = $this->close('إنهاء الدورة مبكراً باتفاق الشركاء');

        // Assert
        $this->assertSame(PeriodStatus::Closed, $period->status);
        $this->assertSame('إنهاء الدورة مبكراً باتفاق الشركاء', $period->override_reason);
    }

    public function test_closing_twice_is_refused(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();
        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert
        $this->expectException(NoPeriodIsOpen::class);

        // Act
        $this->close();
    }

    public function test_the_next_period_opens_on_what_this_one_left(): void
    {
        // Arrange — وهذا هو الاستمرار: تُقفَل سبتمبر فتُفتح أكتوبر على رصيده، ولا صفقةَ تُولد.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();
        Carbon::setTestNow('2026-10-15 09:00:00');
        $closed = $this->close();

        // Act
        app(OpenInvestmentPeriod::class)(actorId: null);

        // Assert
        $next = InvestmentPeriod::open();
        $this->assertNotNull($next);
        $this->assertSame('2026-10-15', $next->starts_on->toDateString());
        $this->assertSame((string) $closed->closing_stock_cost, (string) $next->opening_stock_cost);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
