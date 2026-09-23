<?php

declare(strict_types=1);

namespace Tests\Feature\Console;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/**
 * تدويرُ الفترات بلا ضغطةِ زرّ — البند ٧ من
 * {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * المالكُ طلب الإغلاق الآليّ، وهذه المهمّةُ هي؛ فما تحرسه هذه الاختبارات ثلاثة:
 *
 * 1. **لا تُقفل قبل الموعد** — فترةٌ تُقفَل مبكّراً تترك أياماً لا تخصّ فترةً، وربحُها لا يجد
 *    أين يقع.
 * 2. **تفتح التاليةَ في النداء نفسه** — صندوقٌ بلا فترةٍ مفتوحة لا يستقبل قيداً.
 * 3. **لا تتجاوز حارساً** — الطلبيةُ التي لم تُسلَّم تحبس الفترة، والمهمّةُ تنصرف وتعود غداً.
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

    public function test_a_period_still_running_is_left_alone(): void
    {
        // Arrange — شهرٌ فُتح اليوم، وأمامه أسابيع.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $opened = app(OpenInvestmentPeriod::class)(actorId: null);

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — واحدةٌ مفتوحة، وهي هي.
        $this->assertSame(1, InvestmentPeriod::query()->count());
        $this->assertSame(PeriodStatus::Open, $opened->refresh()->status);
    }

    public function test_a_period_past_its_end_is_closed_and_the_next_one_opened(): void
    {
        // Arrange — سبتمبر، ثم يومٌ بعد نهايته.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);
        $septemberEnd = $september->ends_on->toDateString();

        // Act
        Carbon::setTestNow($september->ends_on->copy()->addDay()->setTime(0, 20));
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — أُقفلت، وفُتحت تاليتُها من الغد التالي لنهايتها فلا يسقط يومٌ من الزمن.
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
        $this->assertNotNull($september->closed_at);

        $next = InvestmentPeriod::open();
        $this->assertNotNull($next);
        $this->assertSame(
            Carbon::parse($septemberEnd)->addDay()->toDateString(),
            $next->starts_on->toDateString(),
        );
    }

    public function test_the_first_period_of_the_fund_s_life_is_opened_by_the_task(): void
    {
        // Arrange — صندوقٌ لا فترةَ له بعد، كما هو يومَ تُشغَّل الميزة.
        Carbon::setTestNow('2026-09-15 00:20:00');
        $this->assertSame(0, InvestmentPeriod::query()->count());

        // Act
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert
        $period = InvestmentPeriod::open();
        $this->assertNotNull($period);
        $this->assertSame('2026-09-15', $period->starts_on->toDateString());
    }

    public function test_an_order_still_in_flight_holds_the_period_and_nothing_is_opened(): void
    {
        // Arrange — فترةٌ حلّ موعدُها، وفيها طلبيةٌ سحبت من رفّ الصندوق ولم تصل العميل.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);

        $order = Order::factory()->status(OrderStatus::Ready)->create([
            'placed_at' => '2026-09-16 10:00:00',
        ]);

        $fulfillment = StockMovement::factory()->create();

        OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'fulfillment_stock_movement_id' => $fulfillment->getKey(),
        ]);

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => StockBatch::factory()->create([
                'investor_deal_id' => InvestorDeal::factory()->create()->getKey(),
            ])->getKey(),
            'stock_movement_id' => $fulfillment->getKey(),
        ]);

        // Act
        Carbon::setTestNow($september->ends_on->copy()->addDay()->setTime(0, 20));
        $this->artisan('investment:roll-periods')->assertSuccessful();

        // Assert — لا إقفالَ ولا فتحَ ثانيةٍ فوقها: الفترةُ واحدةٌ وما زالت مفتوحة.
        $this->assertSame(1, InvestmentPeriod::query()->count());
        $this->assertSame(PeriodStatus::Open, $september->refresh()->status);
    }

    public function test_a_dry_run_writes_nothing(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-15 09:00:00');
        $september = app(OpenInvestmentPeriod::class)(actorId: null);

        // Act
        Carbon::setTestNow($september->ends_on->copy()->addDay()->setTime(0, 20));
        $this->artisan('investment:roll-periods', ['--dry-run' => true])->assertSuccessful();

        // Assert
        $this->assertSame(1, InvestmentPeriod::query()->count());
        $this->assertSame(PeriodStatus::Open, $september->refresh()->status);
    }
}
