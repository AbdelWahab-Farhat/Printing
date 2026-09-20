<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\NoPeriodIsOpen;
use App\Domain\Investor\Exceptions\PeriodHasNotEndedYet;
use App\Domain\Investor\Exceptions\PeriodHasOrdersInFlight;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\OrderInvestorSharesQuery;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * يُقفل الفترة: يجمّد أرقامها، ويُفرج عن أرباحها إلى محافظ أصحابها.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ١هـ.
 *
 * ## ثلاثةُ فروقٍ عن إقفال الصفقة القديم
 *
 * `CloseInvestorDeal` كان يفعل ثلاثة أشياء معاً؛ هذا يفعل واحداً منها:
 *
 * | | القديم | هنا |
 * | --- | --- | --- |
 * | الرفّ | **يشترط أن يكون فارغاً** | لا يشترط — نقيضُه هو الترحيل |
 * | رأس المال | **يُردّ إلى المحفظة** | لا يُمسّ: «عدم تصفير رأس المال عند الانتقال» |
 * | الربح | يُفرَج عنه | يُفرَج عنه — وهو كلُّ ما يفعله هذا الفعل |
 *
 * ## ولماذا ينتظر الطلبيات
 *
 * الطلبيةُ تخصّ فترةَ **تاريخها** لا فترةَ تسليمها، فطلبيةُ ٢٨ سبتمبر التي تُسلَّم في ٢ أكتوبر
 * ربحُها لسبتمبر. ولذلك يبقى سبتمبر مفتوحاً للقيد بعد ٣٠ منه حتى تصل آخرُ طلبياته — وإقفالُه
 * قبلها يُجمّد رقماً ناقصاً ثم يأتي الربحُ فلا يجد فترةً يقع فيها.
 *
 * **والتاريخُ يجعلها مستحقّة، والطلبياتُ تقرّر إن كانت تستطيع.** وطلبيةٌ واحدة عالقة — لا تُسلَّم
 * ولا تُلغى — تحبس الفترة ومعها أرباحُ كلّ مستثمريها، فالبابُ مفتوحٌ بـ`$overrideReason`: سببٌ
 * يُكتب على صفّ الفترة باسم فاعله، لا تجاوزٌ صامت.
 *
 * ## والأرقام تُقرأ من مصدرها هي
 *
 * `net_profit` و`investors_pool` من {@see OrderInvestorSharesQuery} — **الاستعلامُ نفسه الذي
 * يقرأ منه الاستحقاق**، فلا يمكن أن يختلف رقمُ الفترة عن مجموع ما قُيِّد فيها. وحصةُ الشركة
 * الباقي، تُحسب ولا تُكتب، كما هي في كل موضعٍ آخر من هذه الميزة.
 *
 * **وما يُفرَج عنه هو ما في الدفتر لا ما تحسبه هذه الدالة.** المستثمر يقبض ما قُيِّد له فعلاً
 * طلبيةً طلبيةً؛ وأيُّ حسابٍ ثانٍ هنا كان سيصير التعريفَ الذي يخالف الأول يوم تختلف قسمة.
 *
 * **والخسارةُ تُخصم من رأس المال** — قرارُ المالك: «عادي ممكن تخصمها من رأس المال». فلا تُرحَّل
 * خسارةٌ إلى فترةٍ تالية؛ تُشطب من رأس مال صاحبها في دفعته وحدها، وما تجاوزه تتحمّله الشركة على
 * سطرٍ باسمه. التفصيل في {@see settleInvestors()}.
 */
final class CloseInvestmentPeriod
{
    public function __construct(
        private readonly FundValuation $valuation,
        private readonly InvestorBalances $balances,
        private readonly OrderInvestorSharesQuery $shares,
        private readonly PeriodShares $periodShares,
        private readonly RecordCashEntry $cash,
    ) {}

    public function __invoke(?int $actorId, ?string $overrideReason = null): InvestmentPeriod
    {
        return DB::transaction(function () use ($actorId, $overrideReason): InvestmentPeriod {
            $period = InvestmentPeriod::query()
                ->where('status', PeriodStatus::Open)
                ->lockForUpdate()
                ->first();

            if ($period === null) {
                throw NoPeriodIsOpen::make();
            }

            if ($overrideReason === null && ! $period->isDueToClose(now())) {
                // **الثقبُ الذي يسدّه هذا الحارس:** فترةٌ تُقفَل قبل نهاية نافذتها تترك أياماً
                // تقع طلبياتُها داخل نافذةٍ مغلقة، فيأتي ربحُها ولا يجد فترةً يقع فيها.
                throw PeriodHasNotEndedYet::make(
                    (string) $period->code,
                    $period->ends_on->toDateString(),
                );
            }

            $orderIds = $this->ordersOf($period);

            if ($overrideReason === null) {
                $inFlight = $this->inFlightAmong($orderIds);

                if ($inFlight !== []) {
                    throw PeriodHasOrdersInFlight::make((string) $period->code, $inFlight);
                }
            }

            [$netProfit, $investorsPool] = $this->profitOf($orderIds);

            $this->claimUnstamped($period);

            // **النسبُ تُجمَّد قبل أن يُقسَّم بها.** «نسبتهم الحالية مربوطة بكل فترة»: الفترةُ
            // المغلقة تحمل نسبَها كما وُزّع بها مالُها، فلا يُظهر كشفٌ بعد سنةٍ نسبةً غير التي
            // قُبض بها يوم أُقفلت.
            $this->periodShares->freeze($period);

            [$released, $writtenDown] = $this->settleInvestors($period);

            $companyShare = Money::round(bcsub($netProfit, $investorsPool, 8));

            // **نصيبُ الشركة يخرج نقداً، لا يُحسب ويُترك.** إيرادُ الطلبية كلُّه دخل خزينةَ
            // الصندوق عند التحصيل — ومنه حصةُ الشركة من الربح. لو بقيت هناك لصارت رأسَ مالٍ
            // عاملاً يقاسمه المستثمرون في الفترة التالية، ولارتفع سعرُ الوحدة بمالٍ ليس لهم.
            if (bccomp($companyShare, '0', 2) > 0) {
                ($this->cash)(
                    type: CashEntryType::CompanyPayout,
                    amount: $companyShare,
                    sourceType: AuditSubject::InvestmentPeriod->value,
                    sourceId: (int) $period->getKey(),
                    actorId: $actorId,
                );
            }

            $value = ($this->valuation)();

            $period->status = PeriodStatus::Closed;
            $period->closed_at = now();
            $period->closed_by = $actorId;

            $period->closing_stock_cost = $value['stock_on_shelf'];
            $period->closing_cash = $value['cash'];
            $period->sales_revenue = $this->revenueOf($orderIds);
            $period->cost_of_goods_sold = $this->drawnCost($period, ['order_fulfillment']);
            $period->cost_damaged = $this->drawnCost($period, ['scrap_loss']);
            $period->cost_short = $this->shortageCost($period);
            $period->expenses_amount = $this->expensesOf($period);

            $period->net_profit = $netProfit;

            // **ما أُفرِج عنه لا ما حُسب.** الرقمان واحدٌ في الحال السويّة، ويفترقان حين تُقفَل
            // فترةٌ بتجاوز أو تحمل خسارةً مرحَّلة — وحينها الصادقُ هو ما دخل جيوبَ الناس.
            $period->investors_pool = $released;
            $period->company_share = $companyShare;

            $period->through_consumption_id = (int) (DB::table('stock_batch_consumptions')->max('id') ?? 0);
            $period->through_movement_id = (int) (DB::table('stock_movements')->max('id') ?? 0);
            $period->through_wallet_entry_id = (int) (DB::table('investor_wallet_entries')->max('id') ?? 0);
            $period->through_cash_entry_id = (int) (DB::table('investment_cash_entries')->max('id') ?? 0);

            if ($overrideReason !== null) {
                $period->override_reason = $overrideReason;
                $period->overridden_by = $actorId;
            }

            $period->save();

            return $period;
        });
    }

    /**
     * طلبياتُ هذه الفترة — بـ`placed_at` بالسقوط إلى `created_at`، بتوقيت المحلّ.
     *
     * وهو العمودُ نفسه الذي تعدّ عليه `OrderTotalsQuery` و`FiltersOrders`، فأرقامُ الصندوق
     * تتّفق مع تقارير الطلبيات بالبناء لا بالمصادفة.
     *
     * @return list<int>
     */
    private function ordersOf(InvestmentPeriod $period): array
    {
        return DB::table('orders')
            ->whereNull('deleted_at')
            ->whereRaw('coalesce(placed_at, created_at)::date >= ?', [$period->starts_on->toDateString()])
            ->whereRaw('coalesce(placed_at, created_at)::date <= ?', [$period->ends_on->toDateString()])
            ->pluck('id')
            ->map(fn ($id): int => (int) $id)
            ->all();
    }

    /**
     * أيُّ هذه الطلبيات سحب من رفّ الصندوق ولم يصل العميل بعد.
     *
     * @param  list<int>  $orderIds
     * @return list<int>
     */
    private function inFlightAmong(array $orderIds): array
    {
        if ($orderIds === []) {
            return [];
        }

        return DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->join('order_items as oi', 'oi.fulfillment_stock_movement_id', '=', 'm.id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->whereIn('o.id', $orderIds)
            ->whereNotNull('b.investor_deal_id')
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereNull('oi.deleted_at')
            ->whereNull('o.deleted_at')
            ->whereNotIn('o.status', [
                OrderStatus::Delivered->value,
                OrderStatus::Settled->value,
                OrderStatus::Cancelled->value,
            ])
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'))
            ->distinct()
            ->orderBy('o.id')
            ->pluck('o.id')
            ->map(fn ($id): int => (int) $id)
            ->all();
    }

    /**
     * ربحُ الصندوق من طلبيات الفترة، وحصةُ المستثمرين منه.
     *
     * من {@see OrderInvestorSharesQuery} — المصدرُ نفسه الذي قُيِّد منه الاستحقاق، فلا يمكن أن
     * يختلف الرقمان. وطلبيةً طلبيةً لا في استعلامٍ واحد: هو ما يمشي عليه سطرُ شاشة الطلبية
     * اليوم، ويجري مرّةً واحدة عند الإقفال لا في كل فتح شاشة.
     *
     * @param  list<int>  $orderIds
     * @return array{0: string, 1: string}
     */
    private function profitOf(array $orderIds): array
    {
        $net = '0';
        $investors = '0';

        foreach ($orderIds as $orderId) {
            foreach (($this->shares)($orderId) as $row) {
                $net = bcadd($net, (string) ($row['profit'] ?? '0'), 8);
                $investors = bcadd($investors, (string) ($row['investors_share'] ?? '0'), 8);
            }
        }

        return [Money::round($net), Money::round($investors)];
    }

    /**
     * تطالب الفترةُ بالصفوف التي كُتبت في أيامها ولم تجد فترةً تسعها يومَ كُتبت.
     *
     * **متى يقع ذلك:** طلبيةُ ٥ أكتوبر تُسلَّم وسبتمبر ما زال مفتوحاً ينتظر آخرَ طلبياته —
     * فلا فترةَ تسع يومَها بعد، ويكتب {@see PeriodForEntry} صفَّها بلا ختم. أكتوبر حين يُقفَل
     * يجدها في نافذته فيأخذها.
     *
     * **وبـ`occurred_at` لا بتاريخ المصدر**، لأن الصفَّ لا يحمل تاريخ مصدره: وهما واحدٌ في هذه
     * الحال بعينها — الصفُّ بلا ختمٍ أصلاً لأن يومَ كتابته لم تكن له فترة، وذلك اليومُ هو ما
     * تطالب به هذه النافذة.
     *
     * وصفوفُ الصفقات القديمة — الواقعةُ قبل أن يُولد الصندوق — خارج كل نافذة، فلا تُطالَب بها
     * فترةٌ أبداً؛ بابُها `CloseInvestorDeal` كما كان.
     */
    private function claimUnstamped(InvestmentPeriod $period): void
    {
        DB::table('investor_wallet_entries')
            ->whereNull('investment_period_id')
            ->whereNull('deleted_at')
            ->whereRaw('occurred_at::date >= ?', [$period->starts_on->toDateString()])
            ->whereRaw('occurred_at::date <= ?', [$period->ends_on->toDateString()])
            ->update(['investment_period_id' => $period->getKey()]);
    }

    /**
     * تسويةُ كل مستثمر عند الإقفال: الخسارةُ من رأس ماله، ثم ما بقي من ربحٍ إلى محفظته.
     *
     * **الترتيبُ ثابتٌ ولا يُقلب:** تُشطب الخسارة أولاً، ثم يُفرَج عمّا بقي. إفراجٌ قبل الشطب
     * يسلّم مالاً كانت الفترةُ قد خسرته.
     *
     * ## الخسارةُ تُخصم من رأس المال — قرارُ المالك
     *
     * «عادي ممكن تخصمها من رأس المال». فالفترةُ الخاسرة تُغلق على حالها ولا تُرحَّل: خسارةُ
     * مستثمرٍ تُؤخذ من رأس ماله **في دفعته وحدها**، بصفّ {@see WalletEntryType::CapitalWritedown}
     * — لأن كل مبلغٍ في هذا الدفتر موجب، فلا «إرجاعٌ سالب» يُردّ به.
     *
     * **وما تجاوز رأسَ ماله تتحمّله الشركة** على سطرٍ باسمه
     * ({@see WalletEntryType::LossAbsorbedByCompany}): لا شيء في الاتفاق يجعله يدين بأكثر ممّا
     * وضع، والسطرُ يُكتب ليظهر في كشفه بدل أن يختفي في فرقٍ لا يسمّيه أحد.
     *
     * وهو الترتيبُ نفسُه الذي يمشي عليه `CloseInvestorDeal::settle()` — تعريفٌ واحد للقسمة لا
     * اثنان يفترقان.
     *
     * ## وما يُقرأ هو ربحُ **هذه الفترة**
     *
     * لا الدفترُ كلُّه — الشريحة ٢. الربحُ مختومٌ بفترته يوم يُقيَّد، فإقفالُ سبتمبر لا يرى صفّاً
     * لأكتوبر مهما تأخّر عنه. ورأسُ المال في المقابل **تراكميّ** لأن الشطب يأخذ ممّا وضعه الرجل
     * لا ممّا وضعه هذا الشهر.
     *
     * @return array{0: string, 1: string} ما أُفرِج عنه، وما شُطب من رؤوس الأموال
     */
    private function settleInvestors(InvestmentPeriod $period): array
    {
        $released = '0';
        $writtenDown = '0';

        // **ربحُ هذه الفترة وحدها.** قبل الشريحة ٢ كان هذا يمشي على الدفتر كلِّه، فإقفالُ سبتمبر
        // في ١٥ أكتوبر يُفرج عن ربح طلبيةٍ من أكتوبر سُلِّمت في الخامس — يقبض حَمَلةُ سبتمبر
        // ربحاً لم تصنعه فترتُهم، ولا يظهر في رقمٍ واحد لأن كل رصيدٍ هنا مشيُ صفوف.
        $perInvestor = $this->balances->profitInPeriod((int) $period->getKey());

        foreach ($perInvestor as $investorId => $deals) {
            // ورأسُ المال **تراكميّ**: الشطبُ يأخذ ممّا وضعه الرجلُ في الصفقة متى وضعه، لا ممّا
            // وضعه في هذه الفترة. فترةٌ خاسرة تأكل من رصيدٍ دخل قبلها بسنة، وهذا هو المقصود.
            $capitals = $this->balances->forInvestor((int) $investorId)['deals'];

            foreach ($deals as $dealId => $profit) {
                $capital = $capitals[$dealId]['capital'] ?? '0.00';

                if (bccomp($profit, '0', 2) < 0) {
                    $shortfall = substr($profit, 1);
                    $fromCapital = bccomp($shortfall, $capital, 2) > 0 ? $capital : $shortfall;

                    if (bccomp($fromCapital, '0', 2) > 0) {
                        $this->write($period, (int) $investorId, (int) $dealId, WalletEntryType::CapitalWritedown, $fromCapital);
                        $profit = bcadd($profit, $fromCapital, 2);
                        $writtenDown = bcadd($writtenDown, $fromCapital, 8);
                    }

                    if (bccomp($profit, '0', 2) < 0) {
                        $this->write($period, (int) $investorId, (int) $dealId, WalletEntryType::LossAbsorbedByCompany, substr($profit, 1));
                        $profit = '0.00';
                    }
                }

                if (bccomp($profit, '0', 2) > 0) {
                    $this->write($period, (int) $investorId, (int) $dealId, WalletEntryType::ProfitRelease, $profit);
                    $released = bcadd($released, $profit, 8);
                }
            }
        }

        return [Money::round($released), Money::round($writtenDown)];
    }

    /**
     * صفُّ تسويةٍ مختومٌ بالفترة التي تُقفَل.
     *
     * والفترةُ ما زالت `open` في القاعدة لحظةَ الكتابة — تُحفَظ `closed` بعد هذه الدورة كلِّها —
     * فلا يصطدم بحارس {@see InvestorWalletEntry}. والختمُ هو ما
     * يجعل إقفالاً ثانياً لا يُفرج عمّا أُفرج عنه: الصفُّ داخلٌ في `profitInPeriod` بسالبه.
     */
    private function write(InvestmentPeriod $period, int $investorId, int $dealId, WalletEntryType $type, string $amount): void
    {
        $entry = new InvestorWalletEntry([
            'amount' => Money::round($amount),
            'occurred_at' => now(),
        ]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $dealId;
        $entry->investment_period_id = $period->getKey();
        $entry->type = $type;
        $entry->save();
    }

    /**
     * مبيعاتُ الفترة كما يراها الصندوق — ثمنُ ما بِيع من بضاعته.
     *
     * @param  list<int>  $orderIds
     */
    private function revenueOf(array $orderIds): string
    {
        $total = '0';

        foreach ($orderIds as $orderId) {
            foreach (($this->shares)($orderId) as $row) {
                $total = bcadd($total, (string) ($row['goods_amount'] ?? '0'), 8);
            }
        }

        return Money::round($total);
    }

    /**
     * تكلفةُ ما خرج من رفّ الصندوق بأنواع حركةٍ بعينها، داخل نافذة الفترة.
     *
     * **بتاريخ الحركة لا بتاريخ الطلبية**، لأن الهالك والعجز لا طلبيةَ لهما. و`created_at` هو
     * التاريخ الوحيد الذي تحمله الحركة: `stock_movements` بلا `occurred_at`، فالواقعةُ تقع في
     * فترةِ إدخال ورقتها — حدٌّ معلومٌ مسجَّل في المواصفة، لا مفاجأة.
     *
     * @param  list<string>  $movementTypes
     */
    private function drawnCost(InvestmentPeriod $period, array $movementTypes): string
    {
        $cost = $this->periodDraws($period)
            ->whereIn('m.movement_type', $movementTypes)
            ->sum('c.total_cost');

        return Money::round((string) ($cost ?? '0'));
    }

    /** العجزُ: تسويةٌ نازلة سببُها نقصٌ أو تصحيحُ جرد. */
    private function shortageCost(InvestmentPeriod $period): string
    {
        $cost = $this->periodDraws($period)
            ->where('m.movement_type', 'adjustment')
            ->whereIn('m.adjustment_reason', ['shortage', 'count_correction'])
            ->sum('c.total_cost');

        return Money::round((string) ($cost ?? '0'));
    }

    private function periodDraws(InvestmentPeriod $period): Builder
    {
        return DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->whereNotNull('b.investor_deal_id')
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereRaw('m.created_at::date >= ?', [$period->starts_on->toDateString()])
            ->whereRaw('m.created_at::date <= ?', [$period->ends_on->toDateString()])
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'));
    }

    /**
     * مصاريفُ الفترة — بتاريخ وقوعها، وغيرُ المحمَّلة منها وحدها.
     *
     * المحمَّلةُ على الطبقة (`is_landed`) داخلةٌ في تكلفة البضاعة أصلاً، وطرحُها ثانيةً يدفع
     * ثمنَ فاتورة شحنٍ واحدة مرّتين.
     */
    private function expensesOf(InvestmentPeriod $period): string
    {
        $total = DB::table('investor_deal_expenses')
            ->whereNull('deleted_at')
            ->where('is_landed', false)
            ->whereNull('reverses_expense_id')
            ->whereBetween('incurred_on', [
                $period->starts_on->toDateString(),
                $period->ends_on->toDateString(),
            ])
            ->sum('amount');

        return Money::round((string) ($total ?? '0'));
    }
}
