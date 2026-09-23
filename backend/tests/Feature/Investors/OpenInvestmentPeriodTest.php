<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Exceptions\APeriodIsAlreadyOpen;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * فتحُ فترةٍ — وهو ما يحلّ محلّ «إنشاء صفقة جديدة».
 *
 * الشريحة ١د من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * **ولا شيء يُصفَّر عند الانتقال.** البضاعةُ لم تتحرّك، والنقدُ في مكانه؛ الذي يحدث أن الفترة
 * الجديدة **تلتقط صورةً** من قيمة الصندوق وتحفظها رصيداً افتتاحياً. الترحيلُ قراءةٌ وتصوير، لا
 * نقل — وهذا هو الفرق الذي يجعل «ترحيل البضاعة» بلا جدولٍ ولا حركةٍ ولا مهمّةِ منتصف ليل.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class OpenInvestmentPeriodTest extends TestCase
{
    use RefreshDatabase;

    private function open(): OpenInvestmentPeriod
    {
        return app(OpenInvestmentPeriod::class);
    }

    /**
     * يُقفل فترةً بأرقامٍ صفرية مباشرةً في القاعدة — ما يلزم هنا أن تكون مغلقة، لا كيف أُغلقت.
     */
    private function closeOutright(InvestmentPeriod $period): void
    {
        DB::table('investment_periods')->where('id', $period->id)->update([
            'status' => PeriodStatus::Closed->value,
            'closed_at' => now(),
            'closing_stock_cost' => '0.00', 'closing_cash' => '0.00',
            'sales_revenue' => '0.00', 'cost_of_goods_sold' => '0.00',
            'cost_damaged' => '0.00', 'cost_short' => '0.00',
            'expenses_amount' => '0.00', 'net_profit' => '0.00',
            'investors_pool' => '0.00', 'company_share' => '0.00',
            'through_consumption_id' => 0, 'through_movement_id' => 0,
            'through_wallet_entry_id' => 0, 'through_cash_entry_id' => 0,
        ]);
    }

    public function test_the_first_period_starts_today_and_ends_on_the_last_day_of_its_month(): void
    {
        // Arrange — قرارُ المالك (§٠.٧): «الفترة الأولى تكون أول ما نرفع الميزة… وتنتهي في
        // بداية الشهر». فالأولى كسرٌ من يوم الفتح إلى آخر الشهر، لا شهرٌ كامل من يوم الفتح.
        Carbon::setTestNow('2026-09-23 09:00:00');

        // Act
        $period = ($this->open())(actorId: null);

        // Assert — ٢٣ ← ٣٠ سبتمبر، لا ٢٣ سبتمبر ← ٢٢ أكتوبر.
        $this->assertSame(PeriodStatus::Open, $period->status);
        $this->assertSame('2026-09-23', $period->starts_on->toDateString());
        $this->assertSame('2026-09-30', $period->ends_on->toDateString());
    }

    public function test_the_first_period_takes_subscriptions_on_every_one_of_its_days(): void
    {
        // Arrange — جوابُ §١٢و: سبعةُ أيامٍ على فترةٍ من ثمانية حدٌّ بلا معنى، والأولى وحدها
        // يُكتتب في شهرها نفسه — فنافذتُها كلُّ أيامها.
        Carbon::setTestNow('2026-09-23 09:00:00');

        // Act
        $period = ($this->open())(actorId: null);

        // Assert
        $this->assertSame('2026-09-30', $period->subscription_closes_on->toDateString());
    }

    public function test_the_period_after_the_first_is_a_whole_calendar_month(): void
    {
        // Arrange — الكسرُ انتهى على حافّة سبتمبر، فالتاليةُ تبدأ من أوّل أكتوبر.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $first = ($this->open())(actorId: null);
        $this->closeOutright($first);

        // Act
        Carbon::setTestNow('2026-10-01 09:00:00');
        $second = ($this->open())(actorId: null);

        // Assert — من الأول إلى آخر الشهر، لا من ٢٣ إلى ٢٢.
        $this->assertSame('2026-10-01', $second->starts_on->toDateString());
        $this->assertSame('2026-10-31', $second->ends_on->toDateString());
    }

    public function test_a_later_period_keeps_the_subscription_window_from_the_settings(): void
    {
        // Arrange — النافذةُ الممدودة للأولى وحدها؛ ما بعدها بابٌ للفترة التالية بمدّة الإعدادات.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $first = ($this->open())(actorId: null);
        $this->closeOutright($first);

        // Act
        Carbon::setTestNow('2026-10-01 09:00:00');
        $second = ($this->open())(actorId: null);

        // Assert — سبعةُ أيامٍ تشمل يومَ البدء.
        $this->assertSame('2026-10-07', $second->subscription_closes_on->toDateString());
    }

    public function test_a_longer_period_ends_on_the_edge_of_its_last_calendar_month(): void
    {
        // Arrange — «شهران يعنيان حافّةَ الشهر الثاني، لا ستّين يوماً من يوم الفتح». والكسرُ
        // يُعدّ شهرَه الأول، فلا يطول عن فترةٍ كاملة.
        DB::table('company_settings')->where('id', 1)->update(['investment_period_months' => 2]);
        Carbon::setTestNow('2026-09-23 09:00:00');
        $first = ($this->open())(actorId: null);
        $this->closeOutright($first);

        // Act
        Carbon::setTestNow('2026-11-01 09:00:00');
        $second = ($this->open())(actorId: null);

        // Assert
        $this->assertSame('2026-10-31', $first->ends_on->toDateString());
        $this->assertSame('2026-11-01', $second->starts_on->toDateString());
        $this->assertSame('2026-12-31', $second->ends_on->toDateString());
    }

    public function test_a_period_opened_on_the_thirty_first_does_not_spill_into_the_month_after(): void
    {
        // Arrange — فخُّ Carbon: ٣١ يناير + شهر = ٣ مارس. الحسابُ يبدأ من أوّل الشهر فلا يفيض.
        DB::table('company_settings')->where('id', 1)->update(['investment_period_months' => 2]);
        Carbon::setTestNow('2027-01-31 09:00:00');

        // Act
        $period = ($this->open())(actorId: null);

        // Assert — حافّةُ فبراير، لا آخرُ مارس.
        $this->assertSame('2027-02-28', $period->ends_on->toDateString());
    }

    public function test_a_period_after_one_that_ended_off_the_month_edge_lands_back_on_it(): void
    {
        // Arrange — فترةٌ فُتحت قبل هذا التقويم فانتهت في ٢١ أكتوبر. التاليةُ لا تُنقل خطأها
        // إلى ما بعدها: كسرٌ قصير إلى آخر أكتوبر، ثم شهورٌ تقويمية.
        $legacy = InvestmentPeriod::factory()->create([
            'starts_on' => '2026-09-22',
            'ends_on' => '2026-10-21',
            'subscription_closes_on' => '2026-09-28',
        ]);
        $this->closeOutright($legacy);

        // Act
        Carbon::setTestNow('2026-10-22 09:00:00');
        $next = ($this->open())(actorId: null);

        // Assert
        $this->assertSame('2026-10-22', $next->starts_on->toDateString());
        $this->assertSame('2026-10-31', $next->ends_on->toDateString());
    }

    public function test_it_freezes_the_durations_it_was_opened_under(): void
    {
        // Arrange — الوعدُ الذي قطعه المالك: تغييرُ الإعدادات لا يمسّ فترةً قائمة. ويُوفَّى
        // بالنسخ لا بالقراءة المتأخّرة.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $period = ($this->open())(actorId: null);

        // Act — تتغيّر الإعدادات بعد الفتح.
        DB::table('company_settings')->where('id', 1)->update([
            'investment_period_months' => 3,
            'investment_settlement_months' => 6,
            'investment_subscription_window_days' => 1,
            'investor_profit_share_percent' => '70.00',
        ]);

        // Assert — الفترةُ القائمة لم تتحرّك بحرف.
        $period->refresh();
        $this->assertSame(1, $period->period_months);
        $this->assertSame(7, $period->subscription_window_days);
        $this->assertSame('50.00', (string) $period->investor_profit_share_percent);
    }

    public function test_it_opens_on_the_value_the_fund_holds_right_now(): void
    {
        // Arrange — بضاعةٌ على الرفّ ونقدٌ في الخزينة: هما الرصيد الافتتاحي، لا صفر.
        Carbon::setTestNow('2026-10-01 09:00:00');
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1400.000',
            'unit_cost' => '10.000',
        ]);

        DB::table('investment_cash_entries')->insert([
            'type' => 'deposit',
            'amount' => '12000.00',
            'source_type' => 'investor_wallet_entry',
            'source_id' => 1,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $period = ($this->open())(actorId: null);

        // Assert — ١٤٬٠٠٠ بضاعة و١٢٬٠٠٠ نقداً، مصوَّرَين لا منقولَين.
        $this->assertSame('14000.00', (string) $period->opening_stock_cost);
        $this->assertSame('12000.00', (string) $period->opening_cash);
    }

    public function test_a_second_period_begins_the_day_after_the_first_ends(): void
    {
        // Arrange — لا يومَ بين فترتين ولا يومَ مشتركٌ بينهما.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $first = ($this->open())(actorId: null);
        $this->closeOutright($first);

        // Act — تُفتح التالية في ١٢ أكتوبر، متأخّرةً عن نهاية سابقتها.
        Carbon::setTestNow('2026-10-12 09:00:00');
        $second = ($this->open())(actorId: null);

        // Assert — تبدأ من الغد التالي لنهاية سابقتها لا من اليوم: الزمنُ لا يُترك فيه ثقب.
        $this->assertSame('2026-10-01', $second->starts_on->toDateString());
        $this->assertSame('2026-10-31', $second->ends_on->toDateString());
    }

    public function test_a_period_cannot_be_opened_while_one_is_running(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');
        ($this->open())(actorId: null);

        // Assert
        $this->expectException(APeriodIsAlreadyOpen::class);

        // Act
        ($this->open())(actorId: null);
    }

    public function test_the_code_is_allocated_the_way_every_other_code_is(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');

        // Act
        $period = ($this->open())(actorId: null);

        // Assert
        $this->assertSame('P'.$period->id, $period->code);
        $this->assertSame(1, InvestmentPeriod::query()->count());
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
