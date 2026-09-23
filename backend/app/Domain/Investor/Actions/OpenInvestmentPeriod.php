<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Exceptions\APeriodIsAlreadyOpen;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Facades\DB;

/**
 * يفتح فترةً محاسبية — وهو ما يحلّ محلّ «إنشاء صفقة جديدة».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ١د.
 *
 * ## لا شيء يُصفَّر، ولا شيء يُنقَل
 *
 * البضاعةُ لم تتحرّك من رفّها والنقدُ في خزينته؛ الذي يحدث هنا أن الفترة الجديدة **تلتقط صورةً**
 * من قيمة الصندوق فتحفظها رصيداً افتتاحياً. «ترحيلُ البضاعة» الذي طلبه المالك **قراءةٌ وتصوير لا
 * نقل** — ولذلك لا جدولَ له ولا حركةَ مخزونٍ ولا مهمّةَ منتصف ليل. وأيُّ «حركة ترحيل» تُخترع هنا
 * تكسر ثابت «الرصيد = الدفتر».
 *
 * ## والمدد تُنسَخ لحظة الإنشاء
 *
 * `period_months` و`subscription_window_days` و`investor_profit_share_percent` تُقرأ من
 * {@see SettingsService} مرّةً وتُكتب على الصفّ، ولا تُقرأ من هناك بعدها. فمن أُقفل على شهرٍ واحد
 * يبقى شهراً واحداً ولو صارت المدةُ شهرين غداً — وهو نصُّ ما طلبه المالك. **والقراءةُ واحدة لا
 * أربع**: أربعُ قراءاتٍ لصفٍّ واحد تفتح أربعَ نوافذَ يتغيّر فيها الإعداد بين واحدةٍ وأختها.
 *
 * ## ومن أين تبدأ
 *
 * **من الغد التالي لنهاية سابقتها، لا من اليوم.** فترةُ سبتمبر قد يتأخّر إقفالُها إلى ١٢
 * أكتوبر — زرٌّ لم يُضغط أو جدولةٌ صمتت؛ ولو بدأت التاليةُ يومَ الإقفال لسقط من الزمن أحدَ عشر
 * يوماً لا تخصّ فترةً أصلاً، وطلبياتُها لا تجد أين تقع. وأوّلُ فترةٍ في عمر الصندوق تبدأ اليوم
 * لأن لا شيء قبلها.
 *
 * ## وأين تنتهي — §٠.٧ من المواصفة
 *
 * **على حافّة شهرٍ تقويميّ، لا بعد شهرٍ من يوم البدء.** «الفترة الأولى تكون أول ما نرفع الميزة…
 * وتنتهي في بداية الشهر، ثم تبدأ واحدة جديدة من بداية الشهر.» فالأولى كسرٌ (٢٣ ← ٣٠ سبتمبر)، وما
 * بعدها أكتوبرُ كاملاً ثم نوفمبر. ولو حُسبت «البدء + شهر − يوم» لانزاحت كلُّها عن الحافّة إلى
 * الأبد: ٢٣ أكتوبر ← ٢٢ نوفمبر. و`period_months` يبقى إعداداً: شهران يعنيان حافّةَ الشهر الثاني.
 *
 * وفترةٌ سابقةٌ انتهت خارج الحافّة — فُتحت قبل هذا التقويم — لا تنقل خطأها: التاليةُ كسرٌ قصير
 * إلى آخر شهرها، ثم يعود التقويم إلى حافّته وحده.
 *
 * والحارسُ `APeriodIsAlreadyOpen` فوق الفهرس الفريد في القاعدة: الفهرس يمنع الصفَّ الثاني مهما
 * كان الطريق، وهذا يُخرج رسالةً يقرأها من ضغط الزرّ.
 */
final class OpenInvestmentPeriod
{
    public function __construct(
        private readonly SettingsService $settings,
        private readonly FundValuation $valuation,
    ) {}

    public function __invoke(?int $actorId): InvestmentPeriod
    {
        return DB::transaction(function () use ($actorId): InvestmentPeriod {
            $running = InvestmentPeriod::query()
                ->where('status', PeriodStatus::Open)
                ->lockForUpdate()
                ->first();

            if ($running !== null) {
                throw APeriodIsAlreadyOpen::make((string) $running->code);
            }

            $durations = $this->settings->investmentDurations();
            $value = ($this->valuation)();

            $previousEnd = InvestmentPeriod::query()->max('ends_on');

            // أوّلُ فترةٍ تبدأ اليوم؛ وما بعدها من الغد التالي لسابقتها فلا يسقط يومٌ من الزمن.
            $startsOn = $previousEnd === null
                ? now()->startOfDay()
                : now()->parse($previousEnd)->addDay()->startOfDay();

            // تنتهي على حافّة آخر شهرٍ تقويميٍّ من شهورها، وشهرُ البدء أوّلُها. فالأولى كسرٌ من
            // يوم الفتح إلى آخر شهره، وما بعدها يبدأ من الأول فيملأ شهوره كاملة. والحسابُ من أوّل
            // الشهر لا من يوم البدء: ٣١ يناير + شهرٌ في Carbon هو ٣ مارس لا فبراير.
            $endsOn = $startsOn->copy()
                ->startOfMonth()
                ->addMonths($durations['period_months'] - 1)
                ->endOfMonth()
                ->startOfDay();

            // الأولى نافذتُها كلُّ أيامها (§١٢و): لا فترةَ قبلها يُكتتب فيها، وسبعةُ أيامٍ على كسرٍ
            // من ثمانية حدٌّ بلا معنى. وما بعدها تشمل نافذتُه يومَ البدء، فسبعةُ أيامٍ من الأول
            // تنتهي في السابع لا في الثامن.
            $subscriptionCloses = $previousEnd === null
                ? $endsOn->copy()
                : $startsOn->copy()->addDays($durations['subscription_window_days'] - 1);

            // ولا تتجاوز فترتها مهما قصُرت الفترة أو طالت النافذة — القيدُ في القاعدة يرفضها،
            // وهذا يجعلها لا تصل إليه.
            if ($subscriptionCloses->greaterThan($endsOn)) {
                $subscriptionCloses = $endsOn->copy();
            }

            $period = new InvestmentPeriod;
            $period->status = PeriodStatus::Open;
            $period->starts_on = $startsOn->toDateString();
            $period->ends_on = $endsOn->toDateString();
            $period->subscription_closes_on = $subscriptionCloses->toDateString();
            $period->period_months = $durations['period_months'];
            $period->subscription_window_days = $durations['subscription_window_days'];
            $period->settlement_months = $durations['settlement_months'];
            $period->capital_lock_months = $durations['capital_lock_months'];
            $period->ends_settlement_cycle = $this->endsSettlementCycle($durations);
            $period->investor_profit_share_percent = $this->settings->investorProfitSharePercent();
            $period->opening_stock_cost = $value['stock_on_shelf'];
            $period->opening_cash = $value['cash'];
            $period->created_by = $actorId;
            $period->save();

            return $period;
        });
    }

    /**
     * أهذه الفترةُ آخرُ فتراتِ دورةِ تسوية؟
     *
     * عدٌّ لا تقديرٌ بتاريخ: القيدُ في القاعدة يجعل `settlement % period = 0`، فالدورةُ عددٌ
     * صحيحٌ من الفترات ينتهي دائماً على حافّة واحدةٍ منها. تُعدّ الفتراتُ منذ آخر فترةٍ أغلقت
     * دورة — أو منذ الأولى — فإن بلغت العدّةَ فهذه هي.
     *
     * **ويُقرأ الجوابُ يوم الفتح ويُكتب.** من يفتح شهراً يحتاج أن يعرف أهو شهرُ التصفية، وتغييرُ
     * المدة في منتصفه لا يقلب ما أُعلن — الانضباطُ نفسُه الذي تمشي عليه بقيّةُ المدد.
     *
     * @param  array{period_months: int, subscription_window_days: int, settlement_months: int, capital_lock_months: int}  $durations
     */
    private function endsSettlementCycle(array $durations): bool
    {
        $perCycle = intdiv($durations['settlement_months'], max(1, $durations['period_months']));

        if ($perCycle <= 1) {
            return true;
        }

        $sinceLast = InvestmentPeriod::query()
            ->when(
                InvestmentPeriod::query()->where('ends_settlement_cycle', true)->exists(),
                fn ($q) => $q->where(
                    'id',
                    '>',
                    InvestmentPeriod::query()->where('ends_settlement_cycle', true)->max('id'),
                ),
            )
            ->count();

        return $sinceLast + 1 >= $perCycle;
    }
}
