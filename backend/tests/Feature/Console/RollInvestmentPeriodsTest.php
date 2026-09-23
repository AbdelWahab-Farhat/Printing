<?php

declare(strict_types=1);

namespace Tests\Feature\Console;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * الجدولةُ التي تُقفل الفترةَ في موعدها وتفتح التي تليها — §٠.٤ و§٠.٧ من المواصفة.
 *
 * «الفترة الأولى تكون أول ما نرفع الميزة ونبدأ بتشغيل cron وتنتهي في بداية الشهر، ثم تبدأ
 * واحدة جديدة من بداية الشهر.» والشروطُ الثلاثة التي اشترطتها §٠.٤ قبل أن يكون الإغلاقُ
 * الآليُّ آلةً لا وعداً: الفعلُ يُعاد بلا أثرٍ ثانٍ، والزرُّ اليدويُّ باقٍ، واللوحةُ تقول
 * «مستحقّة الإقفال منذ…» حين تصمت الجدولة.
 *
 * **وطلبيةٌ في الطريق لم تعد تحبس الفترة** (§٠.٧): تُقفَل في موعدها إلى «قيد الإغلاق» وتُفتح
 * التاليةُ فوقها. كانت نسخةٌ أولى من هذه المهمّة تنصرف وتعود غداً — وهو العقدُ الذي نُقض.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class RollInvestmentPeriodsTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    /** @return list<array{code: string, status: string, starts_on: string, ends_on: string}> */
    private function periods(): array
    {
        return InvestmentPeriod::query()
            ->orderBy('starts_on')
            ->get()
            ->map(fn (InvestmentPeriod $p): array => [
                'code' => (string) $p->code,
                'status' => $p->status->value,
                'starts_on' => $p->starts_on->toDateString(),
                'ends_on' => $p->ends_on->toDateString(),
            ])
            ->all();
    }

    public function test_it_opens_the_first_period_when_the_fund_has_none(): void
    {
        // Arrange — يومُ رفع الميزة وتشغيل الجدولة.
        Carbon::setTestNow('2026-09-23 10:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — كسرٌ إلى آخر الشهر.
        $periods = $this->periods();
        $this->assertCount(1, $periods);
        $this->assertSame('open', $periods[0]['status']);
        $this->assertSame('2026-09-23', $periods[0]['starts_on']);
        $this->assertSame('2026-09-30', $periods[0]['ends_on']);
    }

    public function test_it_leaves_a_running_period_alone(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-09-30 22:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — آخرُ يومها لم ينقضِ بعد.
        $periods = $this->periods();
        $this->assertCount(1, $periods);
        $this->assertSame('open', $periods[0]['status']);
    }

    public function test_it_closes_the_period_on_its_date_and_opens_the_next(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-10-01 03:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — سبتمبر أُقفل، وأكتوبر شهرٌ كامل.
        $periods = $this->periods();
        $this->assertCount(2, $periods);
        $this->assertSame('closed', $periods[0]['status']);
        $this->assertSame('open', $periods[1]['status']);
        $this->assertSame('2026-10-01', $periods[1]['starts_on']);
        $this->assertSame('2026-10-31', $periods[1]['ends_on']);
    }

    public function test_a_silent_stretch_is_caught_up_in_one_run(): void
    {
        // Arrange — الجدولةُ صمتت شهرين. الفتراتُ لا تُطوى في واحدة: لكلّ شهرٍ نسبُه وحَمَلتُه.
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-12-03 03:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert
        $periods = $this->periods();
        $this->assertSame(
            [
                ['2026-09-23', '2026-09-30', 'closed'],
                ['2026-10-01', '2026-10-31', 'closed'],
                ['2026-11-01', '2026-11-30', 'closed'],
                ['2026-12-01', '2026-12-31', 'open'],
            ],
            array_map(fn (array $p): array => [$p['starts_on'], $p['ends_on'], $p['status']], $periods),
        );
    }

    public function test_running_it_twice_writes_once(): void
    {
        // Arrange — §٠.٤: نداءان لا يكتبان مرّتين، فالإعادةُ آمنةٌ دائماً.
        Carbon::setTestNow('2026-09-23 10:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-10-01 03:00:00');
        $this->artisan('investment:roll-periods')->assertSuccessful();
        $before = $this->periods();

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert
        $this->assertSame($before, $this->periods());
    }

    public function test_a_waiting_period_with_nothing_left_owing_is_finalised(): void
    {
        // Arrange — «قيد الإغلاق» ولم يبقَ ما تنتظره: الجدولةُ ظهيرُ المستمع، تُتمّ ما فاته.
        Carbon::setTestNow('2026-09-23 10:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);
        DB::table('investment_periods')->where('id', $september->id)
            ->update(['status' => PeriodStatus::Closing->value]);
        Carbon::setTestNow('2026-10-02 03:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
        $this->assertNotNull(InvestmentPeriod::open());
    }

    public function test_an_order_in_flight_no_longer_holds_the_period_back(): void
    {
        // Arrange — §٠.٧: «النافذةُ تنتهي في موعدها، والطلبيةُ المتأخّرة تُدفَع وحدَها يوم تصل».
        Carbon::setTestNow('2026-09-01 09:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);
        $this->orderInFlight('2026-09-28 10:00:00');
        Carbon::setTestNow('2026-10-01 03:00:00');

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — سبتمبر ينتظر طلبيتَه، وأكتوبر يجري فوقه.
        $this->assertSame(PeriodStatus::Closing, $september->refresh()->status);
        $this->assertSame('2026-10-01', InvestmentPeriod::open()?->starts_on->toDateString());
    }

    public function test_a_dry_run_says_what_it_would_do_and_writes_nothing(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 10:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);
        Carbon::setTestNow('2026-10-01 03:00:00');

        // Act
        $this->artisan('investment:roll-periods', ['--dry-run' => true])->assertSuccessful();

        // Assert
        $this->assertSame(1, InvestmentPeriod::query()->count());
        $this->assertSame(PeriodStatus::Open, $september->refresh()->status);
    }

    /** طلبيةٌ سحبت من رفّ الصندوق ولم تصل العميل بعد. */
    private function orderInFlight(string $placedAt): Order
    {
        $deal = app(FundDeal::class)();

        $item = StockItem::factory()->named('رفّ الصندوق '.fake()->unique()->numberBetween(1, 99999))->create();
        $batch = StockBatch::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'stock_item_id' => $item->getKey(),
        ]);
        $movement = StockMovement::factory()->create([
            'movement_type' => 'order_fulfillment',
            'stock_item_id' => $item->getKey(),
        ]);

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->getKey(),
            'stock_movement_id' => $movement->getKey(),
        ]);

        $order = Order::factory()->create([
            'placed_at' => $placedAt,
            'status' => 'out_for_delivery',
        ]);

        OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'fulfillment_stock_movement_id' => $movement->getKey(),
        ]);

        return $order;
    }

    public function test_it_runs_every_hour_without_overlapping_itself(): void
    {
        // Arrange — الجدولُ يُبنى حين يبدأ Artisan، فيُقرأ بعد أن يبدأ لا قبله.
        $this->artisan('schedule:list')->assertSuccessful();

        // Act
        $events = array_values(array_filter(
            app(Schedule::class)->events(),
            fn ($event): bool => str_contains((string) $event->command, 'investment:roll-periods'),
        ));

        // Assert — كلَّ ساعة: إن فاتته واحدةٌ أدركته التالية، والإعادةُ لا تكتب شيئاً.
        $this->assertCount(1, $events);
        $this->assertSame('0 * * * *', $events[0]->expression);
        $this->assertTrue($events[0]->withoutOverlapping);
    }
}
