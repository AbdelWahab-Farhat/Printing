<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * الفترةُ المحاسبية — الضمانات التي تحملها القاعدة.
 *
 * الشريحة ١ج من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}. وهذا الجدول هو ما يحلّ
 * محلّ «صفقة #001 → #002 → #003»: الذي يتكرّر صار **فترةً محاسبية**، والبضاعةُ ورأسُ المال
 * يستمرّان عبرها.
 *
 * **وهو الجدولُ الوحيد في هذه الميزة الذي يخزّن أرقاماً مجمَّدة**، وذلك مقصودٌ ومخالفٌ لقاعدة
 * «الرصيد لا يُخزَّن» عن عمد: القاعدة صحيحةٌ للأرصدة الحيّة وخاطئةٌ للفترة المغلقة. فترةٌ تُحسب
 * عند كل قراءة تتحرّك تحت قدمها — مصروفٌ مؤرَّخٌ للماضي، تسويةُ هالكٍ تُدخَل اليوم، طلبيةٌ تُحذف —
 * **فيعطي السؤالُ نفسُه عن الشهر نفسِه جواباً مختلفاً كلَّ مرّة**، وهو ما لا يُدافَع عنه أمام
 * مستثمرٍ وُقِّع له على رقم.
 *
 * وما يُثبَّت هنا أربعةٌ، كلُّها في القاعدة:
 *
 * 1. **فترةٌ مفتوحةٌ واحدة لا غير** — فترتان مفتوحتان تعنيان أن ربح الطلبية يقع في أيّهما صادفت.
 * 2. **لا تتداخل نافذتان** — يومٌ واحد في فترتين يُحسب مرّتين أو لا يُحسب.
 * 3. **المغلقةُ تحمل أرقامها** — «مغلقة» بلا صافي ربحٍ ولا تاريخِ إقفال حالةٌ تكذب على قارئها.
 * 4. **والمفتوحةُ لا تحملها** — رقمٌ مجمَّدٌ على فترةٍ ما زالت تستقبل رقمٌ سيتغيّر.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestmentPeriodShapeTest extends TestCase
{
    use RefreshDatabase;

    /**
     * فترةٌ مفتوحة، افتراضُها سبتمبر ٢٠٢٦.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function period(array $overrides = []): array
    {
        return array_merge([
            'code' => 'P'.fake()->unique()->numberBetween(1, 99999),
            'status' => 'open',
            'starts_on' => '2026-09-01',
            'ends_on' => '2026-09-30',
            'subscription_closes_on' => '2026-09-07',
            'period_months' => 1,
            'subscription_window_days' => 7,
            'investor_profit_share_percent' => '50.00',
            'opening_stock_cost' => '14000.00',
            'opening_cash' => '12000.00',
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides);
    }

    /**
     * الأرقام التي يكتبها الإقفال — تُكتب كلُّها أو لا يُكتب شيء.
     *
     * @return array<string, mixed>
     */
    private function closingFigures(): array
    {
        return [
            'status' => 'closed',
            'closed_at' => now(),
            'closing_stock_cost' => '14000.00',
            'closing_cash' => '12000.00',
            'sales_revenue' => '18000.00',
            'cost_of_goods_sold' => '12000.00',
            'cost_damaged' => '0.00',
            'cost_short' => '0.00',
            'expenses_amount' => '0.00',
            'net_profit' => '6000.00',
            'investors_pool' => '3000.00',
            'company_share' => '3000.00',
            'through_consumption_id' => 40,
            'through_movement_id' => 120,
            'through_wallet_entry_id' => 90,
            'through_cash_entry_id' => 15,
        ];
    }

    public function test_a_period_opens_carrying_the_balance_it_inherited(): void
    {
        // Arrange — الرصيد الافتتاحي هو إقفال ما قبلها، ويُكتب رقماً لا يُحسب عند القراءة.

        // Act
        DB::table('investment_periods')->insert($this->period());

        // Assert
        $this->assertDatabaseHas('investment_periods', [
            'status' => 'open',
            'starts_on' => '2026-09-01',
            'opening_stock_cost' => '14000.00',
            'closed_at' => null,
            'net_profit' => null,
        ]);
    }

    public function test_only_one_period_is_ever_open(): void
    {
        // Arrange — فترتان مفتوحتان تعنيان أن ربح الطلبية يقع في أيّهما صادفت الاستعلام.
        DB::table('investment_periods')->insert($this->period());

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_periods')->insert($this->period([
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]));
    }

    public function test_a_closed_period_makes_room_for_the_next_one(): void
    {
        // Arrange — وهذا هو الاستمرار: تُقفَل سبتمبر فتُفتح أكتوبر، ولا صفقةَ جديدة تُولد.
        DB::table('investment_periods')->insert($this->period());
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update($this->closingFigures());

        // Act
        DB::table('investment_periods')->insert($this->period([
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]));

        // Assert
        $this->assertSame(2, DB::table('investment_periods')->count());
        $this->assertSame(1, DB::table('investment_periods')->where('status', 'open')->count());
    }

    public function test_two_periods_never_share_a_day(): void
    {
        // Arrange — يومٌ واحد في فترتين يُحسب مرّتين أو لا يُحسب، وكلاهما خطأ لا يُرى في شاشة.
        DB::table('investment_periods')->insert($this->period());
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update($this->closingFigures());

        // Assert
        $this->expectException(QueryException::class);

        // Act — تبدأ قبل أن تنتهي سابقتُها بيوم.
        DB::table('investment_periods')->insert($this->period([
            'starts_on' => '2026-09-30',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]));
    }

    public function test_a_period_that_ends_before_it_starts_is_refused(): void
    {
        // Arrange
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_periods')->insert($this->period(['ends_on' => '2026-08-31']));
    }

    public function test_a_closed_period_carries_every_figure_it_was_closed_on(): void
    {
        // Arrange — «مغلقة» بلا صافي ربحٍ حالةٌ تكذب على قارئها.
        DB::table('investment_periods')->insert($this->period());

        // Assert
        $this->expectException(QueryException::class);

        // Act — تُغلَق بلا أرقام.
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['status' => 'closed', 'closed_at' => now()]);
    }

    public function test_an_open_period_carries_no_frozen_figure_at_all(): void
    {
        // Arrange — رقمٌ مجمَّدٌ على فترةٍ ما زالت تستقبل رقمٌ سيتغيّر، وقارئُه لا يعلم.
        DB::table('investment_periods')->insert($this->period());

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['net_profit' => '6000.00']);
    }

    public function test_the_subscription_window_closes_inside_its_own_period(): void
    {
        // Arrange — نافذةُ اكتتابٍ تنتهي بعد الفترة تعني أن «أوّل الفترة» هو الفترةُ كلُّها.
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_periods')->insert($this->period([
            'subscription_closes_on' => '2026-10-15',
        ]));
    }

    public function test_a_period_whose_window_ended_waits_in_closing_without_freezing_a_figure(): void
    {
        // Arrange — النافذةُ انتهت وبقيت لها طلبيةٌ لم تُسلَّم. أرقامُها ما زالت تتحرّك، فلا
        // يُجمَّد منها شيء: «قيد الإغلاق» حالةُ فترةٍ لم تَعُد تستقبل قيداً جديداً وما زالت
        // تستقبل ربحَ طلبياتها هي.
        DB::table('investment_periods')->insert($this->period());

        // Act
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['status' => 'closing']);

        // Assert
        $this->assertDatabaseHas('investment_periods', [
            'starts_on' => '2026-09-01',
            'status' => 'closing',
            'closed_at' => null,
            'net_profit' => null,
        ]);
    }

    public function test_a_closing_period_does_not_hold_the_next_one_shut(): void
    {
        // Arrange — وهذا هو كلُّ الغرض من الحالة الثالثة: سبتمبر ينتظر آخرَ طلبياته بينما
        // أكتوبر يستقبل طلبياته، فلا تُحبَس أرباحُ أحدٍ من أجل طلبيةٍ واحدة.
        DB::table('investment_periods')->insert($this->period());
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['status' => 'closing']);

        // Act
        DB::table('investment_periods')->insert($this->period([
            'starts_on' => '2026-10-01',
            'ends_on' => '2026-10-31',
            'subscription_closes_on' => '2026-10-07',
        ]));

        // Assert — واحدةٌ مفتوحة لا اثنتان، والمنتظِرةُ بجانبها لا تُعدّ منها.
        $this->assertSame(1, DB::table('investment_periods')->where('status', 'open')->count());
        $this->assertSame(1, DB::table('investment_periods')->where('status', 'closing')->count());
    }

    public function test_a_closing_period_freezes_no_figure_either(): void
    {
        // Arrange — «قيد الإغلاق» ما زالت تستقبل ربحَ طلبياتها المتأخّرة، فأيُّ رقمٍ يُكتب
        // عليها اليوم رقمٌ سيتغيّر غداً — وهو العطبُ نفسُه الذي يحرسه الشرطُ على المفتوحة.
        DB::table('investment_periods')->insert($this->period());
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['status' => 'closing']);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['net_profit' => '6000.00']);
    }

    public function test_two_periods_may_wait_in_closing_at_once(): void
    {
        // Arrange — أغسطس بطلبيةٍ عالقة، وسبتمبر انتهى بعده وله عالقةٌ أخرى. لا شيء في النظام
        // يجعل الثانيةَ تنتظر الأولى، فلا قيدَ يمنع اجتماعَهما.
        DB::table('investment_periods')->insert($this->period([
            'starts_on' => '2026-08-01',
            'ends_on' => '2026-08-31',
            'subscription_closes_on' => '2026-08-07',
        ]));
        DB::table('investment_periods')->where('starts_on', '2026-08-01')
            ->update(['status' => 'closing']);

        // Act
        DB::table('investment_periods')->insert($this->period());
        DB::table('investment_periods')->where('starts_on', '2026-09-01')
            ->update(['status' => 'closing']);

        // Assert
        $this->assertSame(2, DB::table('investment_periods')->where('status', 'closing')->count());
    }
}
