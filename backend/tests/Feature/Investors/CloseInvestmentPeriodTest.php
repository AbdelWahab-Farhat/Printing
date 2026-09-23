<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
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
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Events\OrderPaymentsRecalculated;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
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
    private function accrue(int $investorId, int $dealId, string $amount, int $orderId, ?int $periodId = null): void
    {
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investorId,
            'investor_deal_id' => $dealId,
            'type' => WalletEntryType::Profit->value,
            'amount' => $amount,
            'source_type' => 'order',
            'source_id' => $orderId,
            'source_sequence' => 1,
            // بلا ختمٍ بالافتراض، فيطالب به الإقفالُ كما يفعل بصفٍّ وقع في نافذته؛ وبختمٍ
            // صريحٍ حين يقع الصفُّ **بعد** النافذة، لأن المطالبة حينها لا تبلغه.
            'investment_period_id' => $periodId,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /** رأسُ مالٍ في الصفقة — ما يُشطب منه لو كانت القاعدةُ قاعدةَ الفترة الجارية. */
    private function allocate(int $investorId, int $dealId, string $amount): void
    {
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investorId,
            'investor_deal_id' => $dealId,
            'type' => WalletEntryType::Allocation->value,
            'amount' => $amount,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    /** خسارةُ طلبية، كما يكتبها `PostDealShare` لمبلغٍ سالب. */
    private function accrueLoss(int $investorId, int $dealId, string $amount, int $orderId): void
    {
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investorId,
            'investor_deal_id' => $dealId,
            'type' => WalletEntryType::Loss->value,
            'amount' => $amount,
            'source_type' => 'order',
            'source_id' => $orderId,
            'source_sequence' => 1,
            'investment_period_id' => InvestmentPeriod::query()
                ->whereIn('status', [PeriodStatus::Open, PeriodStatus::Closing])
                ->orderBy('starts_on')
                ->value('id'),
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
        // Arrange — نافذتُها إلى ٣٠ سبتمبر؛ إقفالُها في الخامس والعشرين يترك خمسةَ أيامٍ تقع
        // طلبياتُها داخل نافذةٍ مغلقة، فيأتي ربحُها ولا يجد فترةً يقع فيها.
        //
        // **وهذا الحارسُ هو الباقي بعد §٠.٧.** ماتَ حارسُ «طلبياتٌ لم تصل» — الفترةُ تُقفَل في
        // موعدها وتنتظر — وبقي هذا: لا تُقفَل **قبل** موعدها.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $this->openPeriod();

        // Assert
        $this->expectException(PeriodHasNotEndedYet::class);

        // Act
        Carbon::setTestNow('2026-09-25 09:00:00');
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

        // Assert — والتاليةُ تبدأ على حافّة الشهر، لا بعد شهرٍ من يوم فتح سابقتها: الفترةُ
        // الأولى كسرٌ ينتهي بانتهاء شهره، وما بعدها شهورٌ تقويمية.
        $next = InvestmentPeriod::open();
        $this->assertNotNull($next);
        $this->assertSame('2026-10-01', $next->starts_on->toDateString());
        $this->assertSame((string) $closed->closing_stock_cost, (string) $next->opening_stock_cost);
    }

    public function test_the_payment_event_is_what_opens_the_second_gate(): void
    {
        // Arrange — لا نداءَ يدويّ هنا: المقصودُ أن يكون البابُ موصولاً بمجرى المال، فطلبيةٌ
        // تُحصَّل في نوفمبر تُفرج عن ربح سبتمبر بلا أن يتذكّرها أحد.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $onCredit = $this->orderPaid('2026-09-12 09:00:00', '4000.00', '1000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $onCredit->id);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();

        // Act
        Carbon::setTestNow('2026-11-20 09:00:00');
        $onCredit->forceFill(['paid_amount' => '4000.00'])->save();
        event(new OrderPaymentsRecalculated((int) $onCredit->id));

        // Assert
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('900.00', $balances['wallet']['profit']);
    }

    public function test_a_loss_arriving_after_the_money_left_is_not_taken_from_capital(): void
    {
        // Arrange — سبتمبر أُقفل على ربحٍ خرج إلى الجيب، ثم تُسلَّم آخرُ طلبياته بخسارة.
        // **ورأسُ المال لا يُمسّ هنا**: قاعدةُ الشطب من رأس المال لفترةٍ لم يخرج مالُها بعد.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $this->allocate((int) $investor->id, (int) $deal->id, '10000.00');

        $paid = $this->orderPaid('2026-09-05 09:00:00', '5000.00', '5000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $paid->id);

        $late = $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
        $this->assertSame('900.00', app(InvestorBalances::class)
            ->forInvestor((int) $investor->id)['wallet']['profit']);

        // Act — الطلبيةُ المتأخّرة تصل بخسارة ٤٠٠.
        Carbon::setTestNow('2026-10-07 09:00:00');
        $late->forceFill(['status' => 'delivered', 'paid_amount' => (string) $late->grand_total])->save();
        $this->accrueLoss((int) $investor->id, (int) $deal->id, '400.00', (int) $late->id);
        app(CloseInvestmentPeriod::class)->finalise(
            InvestmentPeriod::query()->where('status', PeriodStatus::Closing)->firstOrFail(),
            null,
        );

        // Assert — لا شطبٌ من رأس المال ولا تحمّلٌ من الشركة؛ رأسُ ماله كما هو.
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::CapitalWritedown->value,
        ]);
        $this->assertDatabaseMissing('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::LossAbsorbedByCompany->value,
        ]);
        $this->assertSame('10000.00', app(InvestorBalances::class)
            ->forInvestor((int) $investor->id)['deals'][(int) $deal->id]['capital']);
    }

    public function test_the_leftover_negative_moves_to_the_period_that_is_open(): void
    {
        // Arrange — الحالُ نفسُها، وأكتوبر مفتوح.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $this->allocate((int) $investor->id, (int) $deal->id, '10000.00');

        $paid = $this->orderPaid('2026-09-05 09:00:00', '5000.00', '5000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $paid->id);
        $late = $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = $this->close();
        $october = app(OpenInvestmentPeriod::class)(actorId: null);

        // Act
        Carbon::setTestNow('2026-10-07 09:00:00');
        $late->forceFill(['status' => 'delivered', 'paid_amount' => (string) $late->grand_total])->save();
        $this->accrueLoss((int) $investor->id, (int) $deal->id, '400.00', (int) $late->id);
        app(CloseInvestmentPeriod::class)->finalise($september->refresh(), null);

        // Assert — سبتمبر يُقفَل على صفرٍ بعد أن خرجت منه، وأكتوبر يحملها سالبةً تنتظر ربحَه.
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'investment_period_id' => $september->id,
            'type' => WalletEntryType::LossCarriedOut->value,
            'amount' => '400.00',
        ]);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'investment_period_id' => $october->id,
            'type' => WalletEntryType::LossCarriedIn->value,
            'amount' => '400.00',
        ]);
    }

    public function test_the_carried_negative_is_taken_out_of_the_next_release(): void
    {
        // Arrange — أكتوبر يحمل سالبَ ٤٠٠ ويربح ١٬٠٠٠.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $this->allocate((int) $investor->id, (int) $deal->id, '10000.00');

        $paid = $this->orderPaid('2026-09-05 09:00:00', '5000.00', '5000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $paid->id);
        $late = $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = $this->close();
        app(OpenInvestmentPeriod::class)(actorId: null);

        Carbon::setTestNow('2026-10-07 09:00:00');
        $late->forceFill(['status' => 'delivered', 'paid_amount' => (string) $late->grand_total])->save();
        $this->accrueLoss((int) $investor->id, (int) $deal->id, '400.00', (int) $late->id);
        app(CloseInvestmentPeriod::class)->finalise($september->refresh(), null);

        $octoberOrder = $this->orderPaid('2026-10-20 09:00:00', '6000.00', '6000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '1000.00', (int) $octoberOrder->id);

        // Act
        Carbon::setTestNow('2026-11-02 09:00:00');
        $this->close();

        // Assert — ٩٠٠ من سبتمبر و٦٠٠ من أكتوبر: ١٬٠٠٠ ناقص المرحَّل، لا ١٬٠٠٠ كاملة.
        $this->assertSame('1500.00', app(InvestorBalances::class)
            ->forInvestor((int) $investor->id)['wallet']['profit']);
    }

    public function test_an_order_paid_in_advance_releases_the_moment_it_is_delivered(): void
    {
        // Arrange — **البوّابتان لا ترتيبَ بينهما.** عربونٌ كامل يسبق التسليم، فالتحصيلُ وقع
        // قبل أن يُقيَّد الربحُ أصلاً — ولا حدثَ تحصيلٍ يأتي بعده ليفتح الباب. فلو كان
        // الإفراجُ معلّقاً على حدث الدفع وحده لانتظر هذا المالُ كنسةَ الكرون بلا سبب.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $prepaid = $this->orderPaid('2026-09-12 09:00:00', '4000.00', '4000.00');
        $late = $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();

        // Act — تُسلَّم الطلبيةُ المدفوعة سلفاً، ويُقيَّد ربحُها بختم **فترة الطلبية** كما
        // يكتبه `PostDealShare`، ثم يُعلَن التسليم.
        Carbon::setTestNow('2026-10-07 09:00:00');
        $september = InvestmentPeriod::query()->where('status', PeriodStatus::Closing)->firstOrFail();
        $this->accrue(
            (int) $investor->id,
            (int) $deal->id,
            '700.00',
            (int) $prepaid->id,
            (int) $september->id,
        );
        event(new OrderProfitFinalised((int) $prepaid->id));

        // Assert — في المحفظة فوراً، ولم تُقفَل الفترةُ بعد لأن الأخرى ما زالت في الطريق.
        $this->assertSame('700.00', app(InvestorBalances::class)
            ->forInvestor((int) $investor->id)['wallet']['profit']);
        $this->assertSame(PeriodStatus::Closing, $september->refresh()->status);
        $this->assertContains((int) $late->id, app(CloseInvestmentPeriod::class)->owedOrdersOf($september));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    /**
     * طلبيةٌ سحبت من رفّ الصندوق ولم تصل العميل بعد — أصغرُ ما يجعل الفترةَ منتظِرة.
     *
     * تُبنى بالمصانع لا بمرور الطلبية كاملاً: المقصودُ هنا حالةُ الفترة، لا صحّةُ خطّ الإنتاج،
     * وله اختباراتُه.
     */
    private function orderInFlight(string $placedAt): Order
    {
        $deal = app(FundDeal::class)();

        // **رفٌّ واحد للطبقة وللحركة.** المصنعان يخلقان صنفاً لكلٍّ منهما، فيصطدمان بفهرس
        // `stock_items_name_size_unique` — والواقعُ أن الحركةَ تخرج من الرفّ الذي تستهلكه.
        //
        // وباسمٍ خاصّ: مقاسُ المصنع متسلسلٌ بـ`% 40` فيلتفّ، ومصانعُ الطلبية تخلق أصنافَها
        // معه — فالاسمُ وحده ما يضمن ألا يصطدم رفُّ هذا الاختبار بغيره.
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

    public function test_a_period_whose_order_has_not_landed_closes_on_time_and_waits(): void
    {
        // Arrange — سبتمبر وفيه طلبيةٌ خرجت بضاعتُها ولم تصل. **كان الإقفالُ يُرفض**، فتُحبس
        // أرباحُ كلّ المستثمرين من أجلها؛ وقرارُ المالك أن تنتهي النافذةُ في موعدها.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $this->orderInFlight('2026-09-28 10:00:00');

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = $this->close();

        // Assert
        $this->assertSame(PeriodStatus::Closing, $period->status);
        $this->assertNull($period->closed_at);
        $this->assertNull($period->net_profit);
    }

    public function test_a_waiting_period_lets_the_next_one_open_behind_it(): void
    {
        // Arrange — وهذا هو كلُّ الغرض: أكتوبر يستقبل طلبياته بينما سبتمبر ينتظر آخرَ طلبية.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = $this->close();

        // Act
        $this->openPeriod();

        // Assert
        $this->assertSame(PeriodStatus::Closing, $september->refresh()->status);
        $this->assertSame(1, InvestmentPeriod::query()->where('status', PeriodStatus::Open)->count());
        $this->assertSame(2, InvestmentPeriod::query()->count());
    }

    public function test_a_period_with_nothing_left_in_the_air_closes_outright(): void
    {
        // Arrange — لا طلبيةَ معلّقة، فلا شيءَ ينتظره أحد: تُجمَّد أرقامُها في موعدها.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = $this->close();

        // Assert
        $this->assertSame(PeriodStatus::Closed, $period->status);
        $this->assertNotNull($period->closed_at);
        $this->assertNotNull($period->net_profit);
    }

    public function test_a_waiting_period_is_finalised_when_its_last_order_lands(): void
    {
        // Arrange — سبتمبر ينتظر طلبيةً واحدة، ثم تُسلَّم.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $order = $this->orderInFlight('2026-09-28 10:00:00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = $this->close();
        $this->assertSame(PeriodStatus::Closing, $september->status);

        // Act
        Carbon::setTestNow('2026-10-07 09:00:00');
        $order->forceFill([
            'status' => 'delivered',
            // **والتحصيلُ معه، لا التسليمُ وحده.** البوّابتان شرطٌ واحدٌ مركّب: فترةٌ انقضت
            // وطلبيةٌ وصل مالُها. وبلا هذا السطر تبقى الفترةُ تنتظر — وهو الصواب.
            'paid_amount' => (string) $order->grand_total,
        ])->save();
        app(CloseInvestmentPeriod::class)->finalise($september->refresh(), null);

        // Assert — الآن وحدها تُجمَّد الأرقام، لأن الآن وحدها لم يبقَ ما يحرّكها.
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
        $this->assertNotNull($september->refresh()->closed_at);
        $this->assertNotNull($september->refresh()->net_profit);
    }

    /** طلبيةٌ تخصّ الفترة، بتحصيلها كاملاً أو ناقصاً. */
    private function orderPaid(string $placedAt, string $grandTotal, string $paid): Order
    {
        return Order::factory()->create([
            'placed_at' => $placedAt,
            'status' => 'delivered',
            'grand_total' => $grandTotal,
            'paid_amount' => $paid,
        ]);
    }

    public function test_profit_of_an_order_not_collected_yet_is_not_released(): void
    {
        // Arrange — طلبيتان سُلِّمتا، واحدةٌ حُصِّلت وأخرى بالأجل. **الشرطان لا شرطٌ واحد**:
        // «في حال انتهت الفترة التي فيها طلبية وسُلّمت للزبون (Paid)» — فربحٌ لم يصل مالُه
        // خزينةَ الصندوق لا يُسحب، وإلا صار الرقمُ وعداً بلا دينارٍ خلفه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $collected = $this->orderPaid('2026-09-10 09:00:00', '5000.00', '5000.00');
        $onCredit = $this->orderPaid('2026-09-12 09:00:00', '4000.00', '1000.00');

        $this->accrue((int) $investor->id, (int) $deal->id, '600.00', (int) $collected->id);
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $onCredit->id);

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();

        // Assert — ٦٠٠ في المحفظة، و٩٠٠ ما زالت معلّقة على فترتها تنتظر التحصيل.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('600.00', $balances['wallet']['profit']);
        $this->assertSame('900.00', $balances['deals'][(int) $deal->id]['profit']);
    }

    public function test_collecting_it_later_releases_it_without_reopening_the_period(): void
    {
        // Arrange — الفاتورةُ تُحصَّل في نوفمبر، وفترتُها انقضت من زمان: يقبضها صاحبُها وقتَها.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $onCredit = $this->orderPaid('2026-09-12 09:00:00', '4000.00', '1000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $onCredit->id);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $period = $this->close();

        // Act — وصل الباقي.
        Carbon::setTestNow('2026-11-20 09:00:00');
        $onCredit->forceFill(['paid_amount' => '4000.00'])->save();
        app(CloseInvestmentPeriod::class)->releaseWhatIsNowPayable((int) $onCredit->id, null);

        // Assert
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('900.00', $balances['wallet']['profit']);
        $this->assertSame('0.00', $balances['deals'][(int) $deal->id]['profit']);
        $this->assertSame(PeriodStatus::Closed, $period->refresh()->status);
    }

    public function test_nothing_is_released_while_the_period_is_still_running(): void
    {
        // Arrange — «لا يوجد أرباح يمكن سحبها من أي طلبية حتى لو تم تسوية، حتى تنتهي مدة
        // الفترة». فالتحصيلُ وحدَه لا يفتح البابَ قبل موعده.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $collected = $this->orderPaid('2026-09-10 09:00:00', '5000.00', '5000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '600.00', (int) $collected->id);

        // Act — تحصيلٌ داخل الفترة، ولا إقفال.
        Carbon::setTestNow('2026-09-15 09:00:00');
        app(CloseInvestmentPeriod::class)->releaseWhatIsNowPayable((int) $collected->id, null);

        // Assert — المحفظةُ فارغة، والربحُ معلّقٌ حتى ينتهي الشهر.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $balances['wallet']['profit']);
        $this->assertSame('600.00', $balances['deals'][(int) $deal->id]['profit']);
    }
}
