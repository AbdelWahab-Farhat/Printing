<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\PostDealShare;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\WithdrawFromFund;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\CapitalIsStillLocked;
use App\Domain\Investor\Exceptions\NoPeriodIsOpen;
use App\Domain\Investor\Exceptions\SubscriptionWindowIsClosed;
use App\Domain\Investor\Exceptions\WithdrawalExceedsBalance;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * الوحدات — كيف يدخل مستثمرٌ صندوقاً حيّاً فيه بضاعةٌ لم تُبَع بعد.
 *
 * الشريحة ٣ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}، وهي جوابُ البند ١٤:
 * **الداخلُ الجديد يشتري حصةً في قيمة الصندوق يوم دخوله، لا في نقده.**
 *
 * ```
 * سعرُ الوحدة = قيمةُ الصندوق ÷ الوحدات القائمة
 * وحداتُه     = ما دفع ÷ سعر الوحدة
 * نسبتُه      = وحداتُه ÷ مجموع الوحدات
 * ```
 *
 * مثالُ المالك: ١٬٠٠٠ عند الأول و١٬٢٠٠ عند الثاني وبضاعةٌ صارت ١٬٦٠٠ — الثالثُ الذي يدفع ١٬١٠٠
 * لا يأخذ ثلثاً، بل ما تشتريه ألفٌ ومئة من صندوقٍ قيمتُه ما هي عليه ذلك اليوم.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundUnitsTest extends TestCase
{
    use RefreshDatabase;

    private function openPeriod(): InvestmentPeriod
    {
        return app(OpenInvestmentPeriod::class)(actorId: null);
    }

    /**
     * يسلّم المالَ على الطاولة أولاً، ثم يشترك به في الصندوق.
     *
     * **حدثان في يومين**، دمجُهما في واحدٍ كان يخلق رأسَ مالٍ من لا شيء — قرارُ المالك: «مش أي
     * رقم يقبل، لين يكون في محفظة المستثمر».
     */
    private function deposit(Investor $investor, string $amount): mixed
    {
        $this->fundWallet($investor, $amount);

        return app(DepositToFund::class)(
            investorId: (int) $investor->id,
            amount: $amount,
            actorId: null,
        );
    }

    /** إيداعٌ نقديّ على الطاولة — البابُ القديم، بطريقة دفعٍ وبلا وحدات. */
    private function fundWallet(Investor $investor, string $amount): void
    {
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );
    }

    public function test_the_first_dinar_in_buys_a_unit_at_par(): void
    {
        // Arrange — صندوقٌ فارغ: لا قيمةَ تُقسَم عليها، فالسعرُ واحد ويصير الدينارُ وحدة.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();

        // Act
        $this->deposit($investor, '1000.00');

        // Assert
        $this->assertSame('1000.000000', app(FundUnits::class)->outstanding());
        $this->assertSame('1.000000', app(UnitPrice::class)());
    }

    public function test_a_later_investor_buys_into_the_value_not_into_the_cash(): void
    {
        // Arrange — وهذا هو البند ١٤ بعينه. ألفٌ دخلت واشترت بضاعةً صارت تساوي ١٬٦٠٠،
        // فالوحدةُ صارت ١٫٦ — ومن يدفع ١٬٦٠٠ بعدها يأخذ نصف الصندوق لا ثلاثة أرباعه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();

        $first = Investor::factory()->create();
        $this->deposit($first, '1000.00');

        // البضاعةُ ارتفعت قيمتُها: النقدُ صُرف على طبقةٍ تساوي ١٬٦٠٠.
        DB::table('investment_cash_entries')->insert([
            'type' => 'purchase', 'amount' => '1000.00',
            'source_type' => 'purchase_order', 'source_id' => 1, 'source_sequence' => 1,
            'occurred_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);
        StockBatch::factory()->create([
            'investor_deal_id' => app(FundDeal::class)()->id,
            'quantity_received' => '160.000',
            'quantity_remaining' => '160.000',
            'unit_cost' => '10.000',
        ]);

        $second = Investor::factory()->create();

        // Act
        $this->deposit($second, '1600.00');

        // Assert — ١٬٠٠٠ وحدة مقابل ١٬٠٠٠ وحدة: النصفُ بالنصف.
        $this->assertSame('1.600000', app(UnitPrice::class)(), 'سعر الوحدة قبل الدخول');
        $this->assertSame('2000.000000', app(FundUnits::class)->outstanding());
        $this->assertSame('1000.000000', app(FundUnits::class)->heldBy((int) $second->id));
    }

    public function test_a_deposit_shows_up_as_capital_in_his_wallet_and_as_cash_in_the_treasury(): void
    {
        // Arrange — بابٌ واحد يكتب في ثلاثة دفاتر، فلا يفترق دفترٌ عن أخيه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();

        // Act
        $this->deposit($investor, '5000.00');

        // Assert — خرج من محفظته ودخل الصندوق، ولم يُخلق دينار.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $balances['wallet']['capital']);
        $this->assertSame('5000.00', $balances['deals'][app(FundDeal::class)()->id]['capital']);

        $this->assertDatabaseHas('investment_cash_entries', [
            'type' => 'deposit',
            'amount' => '5000.00',
        ]);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::Allocation->value,
            'amount' => '5000.00',
        ]);
    }

    public function test_every_deposit_carries_its_own_lock(): void
    {
        // Arrange — قرارُ المالك: «كل deposit Timer خاص به لوحده ويجمد معه».
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();

        $this->deposit($investor, '100000.00');

        // فترةٌ تالية، ونافذتُها تفتح من جديد — وهو الطريقُ الوحيد لإيداعٍ ثانٍ.
        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
        $this->openPeriod();
        $this->deposit($investor, '100000.00');

        // Act
        $locks = DB::table('investment_units')->orderBy('id')->pluck('locked_until')->all();

        // Assert — سنةٌ من تاريخ كلٍّ منهما، لا من تاريخ أوّلهما.
        $this->assertSame('2027-09-01', substr((string) $locks[0], 0, 10));
        $this->assertSame('2027-10-02', substr((string) $locks[1], 0, 10));
    }

    public function test_locked_capital_does_not_leave(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $this->deposit($investor, '10000.00');

        // Assert
        $this->expectException(CapitalIsStillLocked::class);

        // Act
        Carbon::setTestNow('2026-12-01 09:00:00');
        app(WithdrawFromFund::class)(
            investorId: (int) $investor->id,
            amount: '1000.00',
            actorId: null,
        );
    }

    public function test_capital_leaves_once_its_lock_has_run_out_and_takes_its_units_with_it(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $this->deposit($investor, '10000.00');

        // Act
        Carbon::setTestNow('2027-10-01 09:00:00');
        app(WithdrawFromFund::class)(
            investorId: (int) $investor->id,
            amount: '4000.00',
            actorId: null,
        );

        // Assert — ٦٬٠٠٠ باقية في الصندوق و٤٬٠٠٠ رجعت محفظته، و٦٬٠٠٠ وحدة معها: النسبةُ لا
        // تنفصل عن المال.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('6000.00', $balances['deals'][app(FundDeal::class)()->id]['capital']);
        $this->assertSame('4000.00', $balances['wallet']['capital']);
        $this->assertSame('6000.000000', app(FundUnits::class)->heldBy((int) $investor->id));
    }

    public function test_a_deposit_with_no_open_period_is_refused(): void
    {
        // Arrange — لا فترةَ تسع وحداته، ولا سعرَ يُشترى به.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $investor = Investor::factory()->create();
        $this->fundWallet($investor, '1000.00');

        // Assert
        $this->expectException(NoPeriodIsOpen::class);

        // Act
        app(DepositToFund::class)(investorId: (int) $investor->id, amount: '1000.00', actorId: null);
    }

    public function test_money_arriving_after_the_window_is_refused_rather_than_silently_deferred(): void
    {
        // Arrange — «يمكنه فقط في بداية الفترة اول اسبوع او اول يوم مدة يحددها المدير». ولو
        // قُبل بعدها لغيّر قسمةَ شهرٍ نصفُه مضى، فيُقسَّم ربحُ طلبيةٍ من أوّله بنسب آخره.
        // **والحارسُ على ما بعد الأولى**: نافذتُها كلُّ أيامها (§١٢و)، فالتجربةُ على أكتوبر.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
        $this->openPeriod();
        $late = Investor::factory()->create();
        $this->fundWallet($late, '1000.00');

        // Assert
        $this->expectException(SubscriptionWindowIsClosed::class);

        // Act — نافذةُ أكتوبر أُغلقت في السابع.
        Carbon::setTestNow('2026-10-20 09:00:00');
        $this->deposit($late, '1000.00');
    }

    public function test_the_first_period_takes_money_on_any_of_its_days(): void
    {
        // Arrange — لا فترةَ قبل الأولى يُكتتب فيها، فنافذتُها كلُّ أيامها (§١٢و): من وصل في
        // العشرين من شهرها الأول شريكٌ فيها، لا منتظرٌ لما بعدها.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $late = Investor::factory()->create();

        // Act
        Carbon::setTestNow('2026-09-20 09:00:00');
        $this->deposit($late, '1000.00');

        // Assert
        $shares = app(PeriodShares::class)->current();
        $this->assertSame('100.000000', $shares[(int) $late->id] ?? null);
    }

    public function test_the_first_period_of_the_fund_is_entered_through_its_own_window(): void
    {
        // Arrange — اثنان دخلا داخل نافذة **أوّل** فترة، فنسبتاهما فيها بنسبة وحداتهما: لا فترةَ
        // قبلها يُكتتب فيها، ولولا ذلك لما كان للصندوق ملّاكٌ في شهره الأول.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $period = $this->openPeriod();

        $big = Investor::factory()->create();
        $small = Investor::factory()->create();
        $this->deposit($big, '3000.00');

        Carbon::setTestNow('2026-09-05 09:00:00');
        $this->deposit($small, '1000.00');

        // Act
        $shares = app(PeriodShares::class)->forPeriod((int) $period->id);

        // Assert
        $this->assertSame('75.000000', $shares[(int) $big->id] ?? null);
        $this->assertSame('25.000000', $shares[(int) $small->id] ?? null);
    }

    public function test_capital_that_joins_in_a_window_does_not_share_the_period_it_joined(): void
    {
        // Arrange — قرارُ المالك بنصّه: «لو فترة الاكتتاب ٧ أيام من بداية شهر تسعة، يقدر يحط
        // فلوسه في الصندوق وتجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر عشرة».
        // فالنافذةُ بابُ الفترة **التالية**: لا يُدخَل شهرٌ بدأ بالفعل.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $founder = Investor::factory()->create();
        $this->deposit($founder, '3000.00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
        $second = $this->openPeriod();

        $newcomer = Investor::factory()->create();
        $this->deposit($newcomer, '1000.00');

        // Act
        $shares = app(PeriodShares::class)->forPeriod((int) $second->id);

        // Assert — مالُه في الصندوق ووحداتُه قائمة، ونصيبُه من هذا الشهر لا شيء.
        $this->assertSame('100.000000', $shares[(int) $founder->id] ?? null);
        $this->assertArrayNotHasKey((int) $newcomer->id, $shares);
    }

    public function test_capital_that_waited_out_a_period_shares_the_one_after_it(): void
    {
        // Arrange — والنصفُ الثاني من القرار: ما جُمّد شهراً يُحتسب في الذي يليه بوحداته كاملة.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $founder = Investor::factory()->create();
        $this->deposit($founder, '3000.00');

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();
        $this->openPeriod();
        $newcomer = Investor::factory()->create();
        $this->deposit($newcomer, '1000.00');

        // Act
        Carbon::setTestNow('2026-11-02 09:00:00');
        $this->close();
        $third = $this->openPeriod();

        // Assert
        $shares = app(PeriodShares::class)->forPeriod((int) $third->id);

        $this->assertSame('75.000000', $shares[(int) $founder->id] ?? null);
        $this->assertSame('25.000000', $shares[(int) $newcomer->id] ?? null);
    }

    public function test_a_closed_period_keeps_the_shares_it_was_divided_by(): void
    {
        // Arrange — «نسبتهم الحالية مربوطة بكل فترة»: تُجمَّد مع بقيّة أرقامها ولا تُعاد قراءتها.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $period = $this->openPeriod();

        $one = Investor::factory()->create();
        $two = Investor::factory()->create();
        $this->deposit($one, '3000.00');
        $this->deposit($two, '1000.00');

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->close();

        // Assert
        $this->assertDatabaseHas('investment_period_shares', [
            'investment_period_id' => $period->id,
            'investor_id' => $one->id,
            'share_percent' => '75.000000',
        ]);
        $this->assertDatabaseHas('investment_period_shares', [
            'investment_period_id' => $period->id,
            'investor_id' => $two->id,
            'share_percent' => '25.000000',
        ]);
    }

    public function test_the_funds_profit_is_split_by_the_shares_of_its_period(): void
    {
        // Arrange — وهذا هو وصلُ الطرفين: الوحداتُ تقرّر النسبة، والنسبةُ تقسم الربح. ولولاه
        // لظلّت الوحداتُ رقماً جميلاً لا يصل جيبَ أحد.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();

        $big = Investor::factory()->create();
        $small = Investor::factory()->create();
        $this->deposit($big, '3000.00');
        $this->deposit($small, '1000.00');

        $fund = app(FundDeal::class)();
        $order = Order::factory()->create(['placed_at' => '2026-09-10 10:00:00']);

        // Act — ٤٠٠ للمستثمرين على طلبيةٍ من هذه الفترة.
        app(PostDealShare::class)(
            $fund,
            '400.00',
            'order',
            (int) $order->id,
            'اختبار',
        );

        // Assert — ٣٠٠ و١٠٠، بنسبة الوحدات لا بنسبة صفوفٍ في `investor_deal_shares` لا وجود لها.
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $big->id,
            'type' => WalletEntryType::Profit->value,
            'amount' => '300.00',
        ]);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $small->id,
            'type' => WalletEntryType::Profit->value,
            'amount' => '100.00',
        ]);
    }

    public function test_profit_becomes_capital_in_one_row_and_can_then_be_subscribed(): void
    {
        // Arrange — قرارُ المالك: «يمكنه تحويل رصيد الأرباح إلى رأس المال ليقوم بإستعماله».
        // ربحٌ أُفرج عنه وصار في محفظته، ولا يشترك به ما دام في جيب الأرباح.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();

        $deal = InvestorDeal::factory()->create();
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::ProfitRelease->value,
            'amount' => '2500.00',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::ProfitCapitalisation,
                amount: '2500.00',
            ),
            null,
        );

        // Assert — جيبٌ فرغ وجيبٌ امتلأ بصفٍّ واحد، ولا دينارَ عبر الطاولة.
        $after = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $after['wallet']['profit']);
        $this->assertSame('2500.00', $after['wallet']['capital']);
        $this->assertDatabaseMissing('investment_cash_entries', ['type' => 'profit_payout']);

        // ثم يشترك به كأيّ رأس مال.
        app(DepositToFund::class)(investorId: (int) $investor->id, amount: '2500.00', actorId: null);
        $this->assertSame('2500.000000', app(FundUnits::class)->heldBy((int) $investor->id));
    }

    public function test_capitalising_more_profit_than_he_earned_is_refused(): void
    {
        // Arrange — الجيبان يتحرّكان معاً، فتجاوزُ السقف يخلق رأسَ مالٍ من لا شيء ولا يظهر في
        // أيّ رصيدٍ بعده.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();

        // Assert
        $this->expectException(WithdrawalExceedsBalance::class);

        // Act
        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::ProfitCapitalisation,
                amount: '1.00',
            ),
            null,
        );
    }

    public function test_subscribing_more_than_the_wallet_holds_is_refused(): void
    {
        // Arrange — قرارُ المالك: «مش أي رقم يقبل، لين يكون في محفظة المستثمر».
        Carbon::setTestNow('2026-09-01 09:00:00');
        $this->openPeriod();
        $investor = Investor::factory()->create();
        $this->fundWallet($investor, '1000.00');

        // Assert
        $this->expectException(WithdrawalExceedsBalance::class);

        // Act
        app(DepositToFund::class)(investorId: (int) $investor->id, amount: '1500.00', actorId: null);
    }

    private function close(): mixed
    {
        return app(CloseInvestmentPeriod::class)(actorId: null, overrideReason: null);
    }

    private function aStockItem(): int
    {
        return (int) StockItem::factory()->create()->id;
    }

    private function aWarehouse(): int
    {
        return (int) Warehouse::factory()->create()->id;
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
