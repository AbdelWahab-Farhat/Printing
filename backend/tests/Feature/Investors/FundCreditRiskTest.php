<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundDraws;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\Actions\ReverseOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Events\OrderPaymentsRecalculated;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * من يتحمّل حين لا يدفع العميل — قرارُ المالك، ٢٤ سبتمبر ٢٠٢٦.
 *
 * > **خطرُ العميل على الشركة لا على المستثمر.** الشطبُ تدفع الشركةُ نصيبَ الصندوق منه، فلا
 * > تنتظره فترةٌ ولا يبقى ديناً في القيمة. والدفعةُ التي تُعكَس بعد الإفراج تُعيد ربحَ طلبيتها
 * > محجوزاً ما دامت فترتُه «قيد الإغلاق»؛ وبعد الإقفال يبقى الربحُ لصاحبه والدَّينُ في القيمة
 * > حتى يُدفع أو يُشطب.
 *
 * ومعها العطبُ الذي ظهر في الطريق: الخزينةُ لم تكن تُقيَّد لها دفعاتُ العملاء أصلاً.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundCreditRiskTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    // ───────────────────────────── fixtures ──────────────────────────────────

    /** طلبيةٌ سُلِّمت وباعت سادةً من رفّ الصندوق بـ`$total` كاملاً — سطرٌ واحد، سحبٌ واحد. */
    private function fundSale(string $total = '1000.00'): Order
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
            'placed_at' => '2026-09-10 09:00:00',
            'status' => 'delivered',
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
        ]);

        OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'fulfillment_stock_movement_id' => $movement->getKey(),
            'line_total' => $total,
        ]);

        return $order;
    }

    /**
     * طلبيةٌ بسطورٍ تسحب كلٌّ منها من رفٍّ يموّله مَن يُسمّى — للسؤال: هل يقبض الصندوقُ ما ليس له؟
     *
     * @param  list<array{financier: 'fund'|'company'|'other_deal', total: string, bought_by_press?: bool}>  $lines
     */
    private function saleOf(array $lines): Order
    {
        // **The fund exists in every one of these**, whoever financed the bags. Without it the
        // action returns before looking at the order at all, and «the fund took nothing» would
        // pass for the wrong reason.
        app(FundDeal::class)();

        $grand = '0';

        foreach ($lines as $line) {
            $grand = bcadd($grand, $line['total'], 2);
        }

        $order = Order::factory()->create([
            'placed_at' => '2026-09-10 09:00:00',
            'status' => 'delivered',
            'items_total' => $grand,
            'delivery_price' => '0.00',
            'grand_total' => $grand,
        ]);

        foreach ($lines as $line) {
            $dealId = match ($line['financier']) {
                'fund' => app(FundDeal::class)()->getKey(),
                'other_deal' => InvestorDeal::factory()->create()->getKey(),
                'company' => null,
            };
            $boughtByPress = $line['bought_by_press'] ?? false;

            $item = StockItem::factory()->named('رفّ '.fake()->unique()->numberBetween(1, 99999))->create();
            $batch = StockBatch::factory()->create([
                'investor_deal_id' => $dealId,
                'stock_item_id' => $item->getKey(),
                'printing_sale_price' => $boughtByPress ? '12.000' : null,
            ]);
            $movement = StockMovement::factory()->create([
                'movement_type' => 'order_fulfillment',
                'stock_item_id' => $item->getKey(),
            ]);

            StockBatchConsumption::factory()->create([
                'stock_batch_id' => $batch->getKey(),
                'stock_movement_id' => $movement->getKey(),
            ]);

            OrderItem::factory()->create([
                'order_id' => $order->getKey(),
                'fulfillment_stock_movement_id' => $movement->getKey(),
                'line_total' => $line['total'],
                'stock_purchased_at' => $boughtByPress ? now() : null,
            ]);
        }

        return $order->refresh();
    }

    /** كلُّ ما دخل خزينةَ الصندوق عن هذه الطلبية، من أيّ نوع. */
    private function fundTookFrom(Order $order): int
    {
        return InvestmentCashEntry::query()
            ->where('source_type', 'order')
            ->where('source_id', $order->id)
            ->count();
    }

    /** يكتب الأرقامَ الثلاثة كما يكتبها `RecalculateOrderPayments`، ثم يعلن الحدث مثله. */
    private function money(Order $order, string $paid, string $writtenOff = '0.00', string $carrier = '0.00'): void
    {
        $order->forceFill([
            'paid_amount' => $paid,
            'written_off_amount' => $writtenOff,
            'carrier_settled_amount' => $carrier,
        ])->save();

        event(new OrderPaymentsRecalculated((int) $order->id));
    }

    /** دفعةٌ حقيقيةٌ في دفتر الطلبية — إعادةُ الحجز تقرأ آخرَ صفٍّ فيه، لا الأرقامَ وحدها. */
    private function pay(Order $order, string $amount): OrderPayment
    {
        return app(RecordOrderPayment::class)(
            $order->refresh(),
            OrderPaymentData::fromArray(['amount' => $amount, 'method' => 'cash']),
        );
    }

    private function reverse(Order $order, OrderPayment $payment): void
    {
        app(ReverseOrderPayment::class)($order->refresh(), $payment, 'عُكست بالخطأ');
    }

    /** مجموعُ الصفوف القائمة من نوعٍ واحد عن هذه الطلبية. */
    private function standing(Order $order, CashEntryType $type): string
    {
        $sum = InvestmentCashEntry::query()
            ->where('source_type', 'order')
            ->where('source_id', $order->id)
            ->where('type', $type)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        return number_format((float) $sum, 2, '.', '');
    }

    /** ربحٌ قُيِّد لمستثمر على طلبية، كما يكتبه `PostDealShare` — بلا ختمٍ فيطالب به الإقفال. */
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

    /** خسارةٌ متأخّرة، مختومةٌ بفترتها — كما يكتبها `PostDealShare` لمبلغٍ سالب. */
    private function lateLoss(int $investorId, int $dealId, int $periodId, string $amount): void
    {
        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investorId,
            'investor_deal_id' => $dealId,
            'type' => WalletEntryType::Loss->value,
            'amount' => $amount,
            'source_type' => 'order',
            'source_id' => $this->orderOnBooks('2026-09-20 09:00:00', '100.00', '100.00')->id,
            'source_sequence' => 1,
            'investment_period_id' => $periodId,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function orderOnBooks(string $placedAt, string $grandTotal, string $paid): Order
    {
        return Order::factory()->create([
            'placed_at' => $placedAt,
            'status' => 'delivered',
            'grand_total' => $grandTotal,
            'paid_amount' => $paid,
        ]);
    }

    private function walletProfit(Investor $investor): string
    {
        return app(InvestorBalances::class)->forInvestor((int) $investor->id)['wallet']['profit'];
    }

    private function withheldRows(): int
    {
        return InvestorWalletEntry::query()->where('type', WalletEntryType::ProfitWithheld)->count();
    }

    // ─────────────────── the treasury is credited at all ───────────────────────

    public function test_a_plain_sale_paid_in_full_puts_its_price_in_the_fund_treasury(): void
    {
        // Arrange — العطبُ: الهدفُ كان يُقرأ من مفتاحٍ لا وجود له، فيصير صفراً دائماً.
        $order = $this->fundSale('1000.00');

        // Act
        $this->money($order, '1000.00');

        // Assert
        $this->assertSame('1000.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('0.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    public function test_a_part_payment_puts_its_share_in_and_the_rest_waits(): void
    {
        // Arrange
        $order = $this->fundSale('1000.00');

        // Act
        $this->money($order, '400.00');

        // Assert
        $this->assertSame('400.00', $this->standing($order, CashEntryType::SaleProceeds));
    }

    public function test_what_the_carrier_took_at_the_door_counts_as_the_customer_s_payment(): void
    {
        // Arrange — الترتيبُ القديم: الناقلُ أخذ أجرتَه من المبلغ باتّفاق، والعميلُ دفع كاملاً.
        $order = $this->fundSale('1000.00');

        // Act
        $this->money($order, '950.00', carrier: '50.00');

        // Assert
        $this->assertSame('1000.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('0.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    // ───────────── the fund takes only what its own money bought ─────────────────

    public function test_an_order_of_the_company_s_own_bags_puts_nothing_in_the_fund(): void
    {
        // Arrange — لا مستثمرَ موّل هذه الأكياس.
        $order = $this->saleOf([['financier' => 'company', 'total' => '1000.00']]);

        // Act — دُفع بعضُها وشُطب الباقي: لا شيءَ من الطريقين للصندوق.
        $this->money($order, '400.00', writtenOff: '600.00');

        // Assert
        $this->assertSame(0, $this->fundTookFrom($order));
    }

    public function test_an_order_of_an_old_deal_s_bags_puts_nothing_in_the_fund(): void
    {
        // Arrange — موّلها مستثمرون، لكن في صفقةٍ قديمة (كـD1) لا في الصندوق.
        $order = $this->saleOf([['financier' => 'other_deal', 'total' => '1000.00']]);

        // Act
        $this->money($order, '400.00', writtenOff: '600.00');

        // Assert
        $this->assertSame(0, $this->fundTookFrom($order));
    }

    public function test_fund_bags_the_press_already_bought_put_nothing_more_in_the_fund(): void
    {
        // Arrange — المطبعةُ دفعت ثمنَها للصندوق يومَ غادرت الرفّ؛ ما يدفعه العميلُ بعدها شأنُ المطبعة.
        $order = $this->saleOf([['financier' => 'fund', 'total' => '1000.00', 'bought_by_press' => true]]);

        // Act
        $this->money($order, '400.00', writtenOff: '600.00');

        // Assert — لا تحصيلَ ولا شطبَ يُقيَّد للصندوق عن هذه الطلبية.
        $this->assertSame(0, $this->fundTookFrom($order));
    }

    public function test_an_order_mixing_fund_and_company_bags_pays_the_fund_its_part_only(): void
    {
        // Arrange — سطرٌ بـ٦٠٠ من رفّ الصندوق، وسطرٌ بـ٤٠٠ من بضاعة الشركة.
        $order = $this->saleOf([
            ['financier' => 'fund', 'total' => '600.00'],
            ['financier' => 'company', 'total' => '400.00'],
        ]);

        // Act — العميلُ دفع نصفَ الفاتورة، وشُطب النصفُ الآخر.
        $this->money($order, '500.00', writtenOff: '500.00');

        // Assert — نصفُ الـ٦٠٠ من العميل ونصفُها من الشركة: ٦٠٠ لا ١٬٠٠٠.
        $this->assertSame('300.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('300.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    // ───────────────────── the company pays the write-off ──────────────────────

    public function test_a_written_off_difference_is_paid_into_the_fund_by_the_company(): void
    {
        // Arrange
        $order = $this->fundSale('1000.00');
        $this->money($order, '400.00');

        // Act
        $this->money($order, '400.00', writtenOff: '600.00');

        // Assert — النصيبُ كاملاً، ومن يدفع كلَّ جزءٍ منه مكتوبٌ باسمه.
        $this->assertSame('400.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('600.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    public function test_undoing_the_write_off_takes_the_company_s_money_back_out(): void
    {
        // Arrange
        $order = $this->fundSale('1000.00');
        $this->money($order, '400.00', writtenOff: '600.00');

        // Act
        $this->money($order, '400.00');

        // Assert
        $this->assertSame('400.00', $this->standing($order, CashEntryType::SaleProceeds));
        $this->assertSame('0.00', $this->standing($order, CashEntryType::WriteOffCoveredByCompany));
    }

    public function test_a_written_off_order_is_no_longer_a_debt_in_the_fund_s_value(): void
    {
        // Arrange
        $order = $this->fundSale('1000.00');
        $this->money($order, '400.00');
        $this->assertSame(1, app(FundDraws::class)->uncollected()->count());

        // Act
        $this->money($order, '400.00', writtenOff: '600.00');

        // Assert
        $this->assertSame(0, app(FundDraws::class)->uncollected()->count());
    }

    // ───────────────────────── the release gate ─────────────────────────────────

    public function test_a_write_off_opens_the_gate_and_lets_the_period_close(): void
    {
        // Arrange — طلبيةٌ بالأجل تُبقي سبتمبر «قيد الإغلاق» وربحَها محجوزاً.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $onCredit = $this->orderOnBooks('2026-09-12 09:00:00', '4000.00', '1000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $onCredit->id);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = app(CloseInvestmentPeriod::class)(actorId: null);
        $this->assertSame(PeriodStatus::Closing, $september->status);

        // Act — الباقي لن يأتي، فيُشطب.
        Carbon::setTestNow('2026-11-20 09:00:00');
        $this->money($onCredit, '1000.00', writtenOff: '3000.00');

        // Assert — الربحُ لصاحبه، والفترةُ لا تنتظر مالاً لن يصل.
        $this->assertSame('900.00', $this->walletProfit($investor));
        $this->assertSame(PeriodStatus::Closed, $september->refresh()->status);
    }

    // ──────────────────── a reversal after the release ───────────────────────────

    /**
     * سبتمبر «قيد الإغلاق»: طلبيةٌ دُفعت فأُفرج عن ربحها ٦٠٠، وأخرى بالأجل (٩٠٠) تُبقيه منتظراً.
     *
     * @return array{0: Investor, 1: InvestorDeal, 2: Order, 3: OrderPayment, 4: mixed, 5: Order}
     */
    private function closingWithOneReleased(): array
    {
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $paid = $this->orderOnBooks('2026-09-10 09:00:00', '5000.00', '0.00');
        $payment = $this->pay($paid, '5000.00');
        $onCredit = $this->orderOnBooks('2026-09-12 09:00:00', '4000.00', '1000.00');

        $this->accrue((int) $investor->id, (int) $deal->id, '600.00', (int) $paid->id);
        $this->accrue((int) $investor->id, (int) $deal->id, '900.00', (int) $onCredit->id);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = app(CloseInvestmentPeriod::class)(actorId: null);

        return [$investor, $deal, $paid, $payment, $september, $onCredit];
    }

    public function test_a_payment_reversed_in_a_closing_period_holds_its_profit_again(): void
    {
        // Arrange
        [$investor, $deal, $paid, $payment, $september] = $this->closingWithOneReleased();
        $this->assertSame('600.00', $this->walletProfit($investor));

        // Act — الدفعةُ عُكست.
        Carbon::setTestNow('2026-10-10 09:00:00');
        $this->reverse($paid, $payment);

        // Assert — عاد الستّمئة من المحفظة إلى الفترة، بصفٍّ يقول ذلك.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('0.00', $balances['wallet']['profit']);
        $this->assertSame('1500.00', $balances['deals'][(int) $deal->id]['profit']);
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->id,
            'type' => WalletEntryType::ProfitWithheld->value,
            'amount' => '600.00',
            'investment_period_id' => $september->id,
        ]);
        $this->assertSame(PeriodStatus::Closing, $september->refresh()->status);
    }

    public function test_holding_it_again_is_done_once_however_often_the_period_is_settled(): void
    {
        // Arrange
        [$investor, , $paid, $payment, $september] = $this->closingWithOneReleased();
        Carbon::setTestNow('2026-10-10 09:00:00');
        $this->reverse($paid, $payment);

        // Act — الإقفالُ الآليّ ينادي كلَّ يوم.
        app(CloseInvestmentPeriod::class)->finalise($september->refresh(), null);
        app(CloseInvestmentPeriod::class)->finalise($september->refresh(), null);

        // Assert
        $this->assertSame(1, $this->withheldRows());
        $this->assertSame('0.00', $this->walletProfit($investor));
    }

    public function test_paid_again_it_is_released_again(): void
    {
        // Arrange
        [$investor, , $paid, $payment] = $this->closingWithOneReleased();
        Carbon::setTestNow('2026-10-10 09:00:00');
        $this->reverse($paid, $payment);

        // Act
        Carbon::setTestNow('2026-10-12 09:00:00');
        $this->pay($paid, '5000.00');

        // Assert
        $this->assertSame('600.00', $this->walletProfit($investor));
    }

    public function test_a_late_loss_beside_it_is_still_left_for_carrying(): void
    {
        // Arrange — خسارةٌ وصلت بعد الإفراج **و**دفعةٌ عُكست. القاعدتان لا تختلطان: ربحُ الطلبية
        // وحده يعود محجوزاً، والخسارةُ تبقى سالبةً للترحيل.
        [$investor, $deal, $paid, $payment, $september] = $this->closingWithOneReleased();
        $this->lateLoss((int) $investor->id, (int) $deal->id, (int) $september->id, '100.00');

        // Act
        Carbon::setTestNow('2026-10-10 09:00:00');
        $this->reverse($paid, $payment);

        // Assert
        $this->assertDatabaseHas('investor_wallet_entries', [
            'type' => WalletEntryType::ProfitWithheld->value,
            'amount' => '600.00',
        ]);
        $this->assertSame(1, $this->withheldRows());
        $this->assertSame('0.00', $this->walletProfit($investor));
    }

    public function test_a_part_payment_on_an_order_that_never_stopped_owing_holds_nothing_back(): void
    {
        // Arrange — خسارةٌ متأخّرة تجعل المتاحَ سالباً، ثم تصل دفعةٌ جزئية على الطلبية الآجلة.
        // تلك الطلبيةُ لم يُفرَج عن ربحها قطّ، فلا شيءَ منه يُستردّ.
        [$investor, $deal, , , $september, $onCredit] = $this->closingWithOneReleased();
        $this->lateLoss((int) $investor->id, (int) $deal->id, (int) $september->id, '100.00');

        // Act
        Carbon::setTestNow('2026-10-10 09:00:00');
        $this->pay($onCredit, '500.00');

        // Assert
        $this->assertSame(0, $this->withheldRows());
        $this->assertSame('600.00', $this->walletProfit($investor));
    }

    public function test_after_the_period_has_closed_the_released_profit_stays_where_it_is(): void
    {
        // Arrange — سبتمبر أُقفل نهائياً على طلبيةٍ مدفوعة.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $paid = $this->orderOnBooks('2026-09-10 09:00:00', '5000.00', '0.00');
        $payment = $this->pay($paid, '5000.00');
        $this->accrue((int) $investor->id, (int) $deal->id, '600.00', (int) $paid->id);

        Carbon::setTestNow('2026-10-02 09:00:00');
        $september = app(CloseInvestmentPeriod::class)(actorId: null);
        $this->assertSame(PeriodStatus::Closed, $september->status);

        // Act — عُكست الدفعة بعد الإقفال.
        Carbon::setTestNow('2026-11-01 09:00:00');
        $this->reverse($paid, $payment);

        // Assert — لا يُكتب في فترةٍ مغلقة؛ الدَّينُ يبقى في القيمة حتى يُدفع أو يُشطب.
        $this->assertSame('600.00', $this->walletProfit($investor));
        $this->assertSame(0, $this->withheldRows());
    }
}
