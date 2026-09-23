<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Models\ActivityLog;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * الترحيلُ الذي يعيد الفترةَ المفتوحة إلى حافّة شهرها.
 *
 * التقويمُ الشهريّ في {@see OpenInvestmentPeriod} يصحّ لما يُفتح
 * بعده؛ وما فُتح قبله قائمٌ على «البدء + شهر − يوم» — P1 على سيرفر التجربة من ٢٢ سبتمبر إلى ٢١
 * أكتوبر. وهذا يعيدها إلى ٣٠ سبتمبر ما دام ذلك لا يُخرج منها يوماً مضى.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class EndTheOpenPeriodOnItsMonthEdgeMigrationTest extends TestCase
{
    use RefreshDatabase;

    private function runTheMigration(): void
    {
        (require database_path('migrations/2026_09_23_140000_end_the_open_period_on_its_month_edge.php'))->up();
    }

    /** P1 كما فتحها التقويمُ القديم على سيرفر التجربة. */
    private function theOldFirstPeriod(): InvestmentPeriod
    {
        return InvestmentPeriod::factory()->create([
            'starts_on' => '2026-09-22',
            'ends_on' => '2026-10-21',
            'subscription_closes_on' => '2026-09-28',
        ]);
    }

    /** يُقفل فترةً بأرقامٍ صفرية مباشرةً في القاعدة — ما يلزم هنا أن تكون مغلقة، لا كيف أُغلقت. */
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

    public function test_it_pulls_the_open_period_in_to_the_last_day_of_its_month(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 09:00:00');
        $period = $this->theOldFirstPeriod();

        // Act
        $this->runTheMigration();

        // Assert — ٣٠ سبتمبر، لا ٢١ أكتوبر. والبدايةُ لا تتحرّك.
        $period->refresh();
        $this->assertSame('2026-09-22', $period->starts_on->toDateString());
        $this->assertSame('2026-09-30', $period->ends_on->toDateString());
    }

    public function test_the_first_period_now_takes_subscriptions_to_its_last_day(): void
    {
        // Arrange — §١٢و: نافذةُ الأولى كلُّ أيامها، ولم تكن قاعدةً يوم فُتحت.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $period = $this->theOldFirstPeriod();

        // Act
        $this->runTheMigration();

        // Assert
        $this->assertSame('2026-09-30', $period->refresh()->subscription_closes_on->toDateString());
    }

    public function test_a_later_period_keeps_the_window_it_was_opened_with(): void
    {
        // Arrange — الامتدادُ للأولى وحدها؛ ما بعدها نافذتُه بابٌ للتي تليها بمدّة الإعدادات.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $before = InvestmentPeriod::factory()->create([
            'starts_on' => '2026-09-01',
            'ends_on' => '2026-09-21',
            'subscription_closes_on' => '2026-09-07',
        ]);
        $this->closeOutright($before);
        $period = $this->theOldFirstPeriod();

        // Act
        $this->runTheMigration();

        // Assert
        $period->refresh();
        $this->assertSame('2026-09-30', $period->ends_on->toDateString());
        $this->assertSame('2026-09-28', $period->subscription_closes_on->toDateString());
    }

    public function test_it_leaves_the_period_alone_once_its_new_end_has_passed(): void
    {
        // Arrange — نُشر في ٥ أكتوبر: القصُّ إلى ٣٠ سبتمبر يُخرج من الفترة أياماً وقعت فيها
        // طلبياتٌ ومصاريفُ مختومةٌ بها. فتبقى كما هي، والتاليةُ تعود إلى الحافّة وحدها.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $period = $this->theOldFirstPeriod();
        Carbon::setTestNow('2026-10-05 09:00:00');

        // Act
        $this->runTheMigration();

        // Assert
        $period->refresh();
        $this->assertSame('2026-10-21', $period->ends_on->toDateString());
        $this->assertSame('2026-09-28', $period->subscription_closes_on->toDateString());
    }

    public function test_a_period_already_on_its_month_edge_is_not_written(): void
    {
        // Arrange
        Carbon::setTestNow('2026-10-03 09:00:00');
        $period = InvestmentPeriod::factory()->create([
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]);

        // Act
        $this->runTheMigration();

        // Assert — ولا سطرَ في سجلّها: لم يتغيّر فيها شيء.
        $this->assertSame('2026-10-31', $period->refresh()->ends_on->toDateString());
        $this->assertSame(0, ActivityLog::query()
            ->where('subject_type', $period->getMorphClass())
            ->where('subject_id', $period->getKey())
            ->where('event', 'updated')
            ->count());
    }

    public function test_the_change_is_written_into_the_period_history(): void
    {
        // Arrange — تاريخٌ يراه المستثمر تغيّر، فيُكتب في سجلّ الفترة من أين وإلى أين.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $period = $this->theOldFirstPeriod();

        // Act
        $this->runTheMigration();

        // Assert
        $entry = ActivityLog::query()
            ->where('subject_type', $period->getMorphClass())
            ->where('subject_id', $period->getKey())
            ->where('event', 'updated')
            ->latest('id')
            ->first();

        $this->assertNotNull($entry);
        $this->assertStringStartsWith('2026-10-21', (string) ($entry->attribute_changes?->get('old')['ends_on'] ?? ''));
        $this->assertStringStartsWith('2026-09-30', (string) ($entry->attribute_changes?->get('attributes')['ends_on'] ?? ''));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
