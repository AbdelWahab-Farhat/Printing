<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\PeriodIsClosed;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * ختمُ الفترة على دفتر المحافظ — «المغلقُ يبقى مغلقاً».
 *
 * الشريحة ٢ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * **الثقبُ الذي تسدّه هذه الشريحة:** الإقفالُ كان يُفرج عن كلّ ربحٍ موجب في الدفتر بلا سؤالٍ عن
 * فترته — فإقفالُ سبتمبر في ١٥ أكتوبر كان يسلّم حَمَلةَ سبتمبر ربحَ طلبياتِ أكتوبر.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PeriodStampingTest extends TestCase
{
    use RefreshDatabase;

    private function openPeriod(): InvestmentPeriod
    {
        return app(OpenInvestmentPeriod::class)(actorId: null);
    }

    private function close(?string $overrideReason = null): InvestmentPeriod
    {
        return app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: $overrideReason);
    }

    /** ربحٌ يُكتب كما يكتبه `PostDealShare`، بختمِ الفترة الذي يقرّره الحلّال. */
    private function accrue(int $investorId, int $dealId, string $amount, int $orderId, ?int $periodId): InvestorWalletEntry
    {
        $entry = new InvestorWalletEntry([
            'amount' => $amount,
            'occurred_at' => now(),
        ]);

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

    public function test_an_order_dated_in_september_is_stamped_september_though_it_delivers_in_october(): void
    {
        // Arrange — «كل طلبية في سبتمبر هي ل سبتمبر»: التاريخُ يقرّر، لا لحظةُ التسليم.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $period = $this->openPeriod();

        $orderId = (int) Order::factory()->create(['placed_at' => '2026-09-28 10:00:00'])->id;

        // Act — القيدُ يقع في أكتوبر، بعد نهاية نافذة سبتمبر.
        Carbon::setTestNow('2026-10-02 09:00:00');
        $stamp = app(PeriodForEntry::class)->bySource('order', $orderId);

        // Assert
        $this->assertSame((int) $period->id, $stamp);
    }

    public function test_a_correction_to_a_closed_period_lands_on_the_one_open_today(): void
    {
        // Arrange — سبتمبر أُقفل ووُزّع مالُه؛ تصحيحُ طلبيةٍ منه لا يُعاد إلى جيوبٍ خرج منها.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = $this->openPeriod();

        $orderId = (int) Order::factory()->create(['placed_at' => '2026-09-28 10:00:00'])->id;

        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();
        $october = $this->openPeriod();

        // Act
        $stamp = app(PeriodForEntry::class)->bySource('order', $orderId);

        // Assert
        $this->assertNotSame((int) $september->id, $stamp);
        $this->assertSame((int) $october->id, $stamp);
    }

    public function test_a_row_with_no_period_is_claimed_by_the_period_whose_window_covers_its_day(): void
    {
        // Arrange — نافذةُ الفترة الأولى من ١٥ سبتمبر إلى ١٤ أكتوبر، وهي ما زالت مفتوحةً في
        // العشرين منه تنتظر آخرَ طلبياتها. طلبيةُ ذلك اليوم **لا فترةَ تسعها بعد**، فتُكتب بلا
        // ختمٍ وتنتظر من يطالب بها.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        Carbon::setTestNow('2026-10-20 09:00:00');
        $orphan = $this->accrue((int) $investor->id, (int) $deal->id, '900.00', 71, null);
        $this->assertNull($orphan->investment_period_id);

        Carbon::setTestNow('2026-10-21 09:00:00');
        $this->close();
        $october = $this->openPeriod();

        // Act
        Carbon::setTestNow('2026-11-20 09:00:00');
        $this->close();

        // Assert
        $this->assertSame((int) $october->id, (int) $orphan->fresh()->investment_period_id);
    }

    public function test_closing_releases_only_what_its_own_period_earned(): void
    {
        // Arrange — وهذا هو الثقب بعينه: ربحُ أكتوبر لا يخرج مع إقفال سبتمبر.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $this->accrue((int) $investor->id, (int) $deal->id, '1000.00', 81, (int) $september->id);

        Carbon::setTestNow('2026-10-15 09:00:00');
        $closedSeptember = $this->close();
        $october = $this->openPeriod();

        $this->accrue((int) $investor->id, (int) $deal->id, '400.00', 82, (int) $october->id);

        // Act — إقفالُ سبتمبر جرى قبل قيدِ أكتوبر؛ فالتحقّقُ على ما أُفرج عنه هناك.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);

        // Assert — ألفٌ في المحفظة، وأربعمئةٌ ما زالت في جيب أكتوبر.
        $this->assertSame('1000.00', $after['wallet']['profit']);
        $this->assertSame('400.00', $after['deals'][(int) $deal->id]['profit']);
        $this->assertSame('1000.00', (string) $closedSeptember->investors_pool);
    }

    public function test_profit_accrued_after_a_close_does_not_leak_into_that_close(): void
    {
        // Arrange — الترتيبُ المقلوب: ربحُ أكتوبر مكتوبٌ **قبل** أن يُقفل سبتمبر.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $this->accrue((int) $investor->id, (int) $deal->id, '1000.00', 83, (int) $september->id);

        // ربحٌ لا يخصّ الفترة الأولى — نافذتُها انتهت في ١٤ أكتوبر، فيومُه خارج كل نافذة
        // ويُكتب بلا ختم.
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->accrue((int) $investor->id, (int) $deal->id, '400.00', 84, null);

        // Act
        Carbon::setTestNow('2026-10-21 09:00:00');
        $closed = $this->close();

        // Assert — ألفٌ خرجت، وأربعمئةٌ بقيت لمن يطالب بها.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('1000.00', $after['wallet']['profit']);
        $this->assertSame('400.00', $after['deals'][(int) $deal->id]['profit']);
        $this->assertSame('1000.00', (string) $closed->investors_pool);
    }

    public function test_a_closed_period_refuses_a_new_row(): void
    {
        // Arrange — أرقامُ الفترة جُمّدت وأُعلنت؛ صفٌّ يدخلها بعد ذلك يجعلها تكذب.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        Carbon::setTestNow('2026-10-15 09:00:00');
        $this->close();

        // Assert
        $this->expectException(PeriodIsClosed::class);

        // Act
        $this->accrue((int) $investor->id, (int) $deal->id, '500.00', 85, (int) $september->id);
    }

    public function test_a_reversal_stays_in_the_period_of_the_row_it_undoes(): void
    {
        // Arrange — وإلا صحّحت فترةٌ خطأً لم تقع فيها، وبقي الخطأُ قائماً في فترته.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = $this->openPeriod();

        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $entry = $this->accrue((int) $investor->id, (int) $deal->id, '1000.00', 86, (int) $september->id);

        // Act
        $stamp = app(PeriodForEntry::class)->floorOf((int) $entry->investment_period_id);

        // Assert
        $this->assertSame((int) $september->id, $stamp);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
