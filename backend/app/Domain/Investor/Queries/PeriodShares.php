<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriodShare;
use App\Domain\Investor\Support\Money;

/**
 * بأيّ نسبٍ يُقسَّم ربحُ فترةٍ بعينها — «نسبتهم الحالية مربوطة بكل فترة».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣.
 *
 * ```
 * نصيبُ فلان في الفترة P = وحداتُه عشيّةَ بدء P ÷ مجموع الوحدات تلك الليلة
 * ```
 *
 * ## لماذا عشيّةَ البدء، لا يومَ إغلاق النافذة
 *
 * **لا يُدخَل شهرٌ بدأ بالفعل.** قرارُ المالك بنصّه: «لو فترة الاكتتاب ٧ أيام من بداية شهر
 * تسعة، يقدر يحط فلوسه في الصندوق وتجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر
 * عشرة». فالنافذةُ في أول الفترة **بابُ الفترة التالية**: المالُ يدخل فيها ويُشغَّل، ونصيبُ
 * صاحبه يبدأ من الشهر الذي يليها.
 *
 * وكانت الصورةُ تُلتقط يومَ إغلاق النافذة، فيقاسم الداخلُ شهراً مضى ثلثُه قبل أن يصل مالُه —
 * وهو عينُ ما رفضه المالك: «لا يحسب كربح ولا يحسب كنسبة الا بداية شهر الجاي».
 *
 * ولا تُقرأ «اليوم» في كل حال: لو قُرئت لتغيّرت قسمةُ شهرٍ كلَّما دخل داخل، وصار ربحُ طلبيةٍ من
 * أوّله يُقسَّم بنسب آخره.
 *
 * ## وأوّلُ فترةٍ في عمر الصندوق تُدخَل من نافذتها هي
 *
 * لا فترةَ قبلها يُكتتب فيها، فلو حُرمت نافذتُها لما كان للصندوق ملّاكٌ أصلاً في شهره الأول.
 *
 * **وليست مجاملةً للبداية**: وعاءُ أرباحِ فترةٍ بلا شركاء لا يُقسَّم على أحد، فيبقى في الصندوق
 * ويرفع سعرَ الوحدة — فيصل أصحابَ الوحدات أنفسَهم من البابِ الخلفيّ رأسَ مالٍ لا ربحاً يُسحب.
 * وهو الخطرُ نفسُه الذي يُخرج {@see CloseInvestmentPeriod} نصيبَ الشركة نقداً من أجله.
 *
 * ## والمجمَّدُ يسبق المحسوب
 *
 * فترةٌ أُقفلت **وُزّع مالُها بهذه النسب** إلى جيوبٍ لا يُستعاد منها شيء. فإن وُجد صفٌّ مجمَّد
 * قُرئ منه ولا يُعاد حسابُ شيء: دفترُ الوحدات قد يتغيّر بعد سنة — صفٌّ يُعكس، وحداتٌ تُلغى —
 * فتُظهر الشاشةُ نسبةً غير التي قُبض بها.
 *
 * ## والقسمةُ بأكبر البواقي
 *
 * ثلاثةٌ بالتساوي تعطي ٣٣٫٣٣٣٣٣٣ ثلاثَ مرّات فينقص جزءٌ من مئة. {@see Money::allocate()} يوزّع
 * الباقي على أصحاب أكبر الكسور — الخوارزميةُ نفسها التي تُقسَّم بها الأرباح، فلا تعريفان
 * يفترقان.
 */
final class PeriodShares
{
    public const SCALE = 6;

    public function __construct(private readonly FundUnits $units) {}

    /**
     * @return array<int, string> المستثمر ← نسبتُه المئوية بستّ خانات
     */
    public function forPeriod(int $periodId): array
    {
        $frozen = InvestmentPeriodShare::query()
            ->where('investment_period_id', $periodId)
            ->pluck('share_percent', 'investor_id');

        if ($frozen->isNotEmpty()) {
            return $frozen
                ->mapWithKeys(fn ($percent, $id): array => [(int) $id => (string) $percent])
                ->all();
        }

        $period = InvestmentPeriod::query()->whereKey($periodId)->first();

        return $period === null ? [] : $this->live($period);
    }

    /**
     * الوحداتُ التي تقاسم هذه الفترة، قبل تحويلها إلى نسب.
     *
     * @return array<int, string>
     */
    public function unitsOf(InvestmentPeriod $period): array
    {
        return $this->units->byInvestor($this->cutoffFor($period));
    }

    /**
     * اللحظةُ التي تُلتقط عندها صورةُ الملّاك.
     *
     * **عشيّةَ البدء** لا يومَ إغلاق النافذة — انظر أعلى الملف. وهي عشيّةُ البدء لا إغلاقُ نافذة
     * الفترة السابقة: بينهما قد يخرج شريكٌ بوحداته، ومن خرج لا يقاسم شهراً لم يبدأ.
     *
     * وأوّلُ فترةٍ في عمر الصندوق تُدخَل من نافذتها هي — {@see InvestmentPeriod::isTheFirstOfTheFund()}.
     */
    private function cutoffFor(InvestmentPeriod $period): \DateTimeInterface
    {
        return $period->isTheFirstOfTheFund()
            ? $period->subscription_closes_on->endOfDay()
            : $period->starts_on->copy()->subDay()->endOfDay();
    }

    /**
     * @return array<int, string>
     */
    private function live(InvestmentPeriod $period): array
    {
        $held = $this->unitsOf($period);

        if ($held === []) {
            return [];
        }

        $ids = array_keys($held);
        $percents = Money::allocate('100', array_values($held), self::SCALE);

        $out = [];

        foreach ($ids as $index => $id) {
            $percent = $percents[$index] ?? '0';

            // من نصيبُه صفرٌ بعد التقريب ليس شريكاً في هذه الفترة: قيدُ القاعدة يرفض صفّاً
            // مجمَّداً بصفر، والقسمةُ عليه تعطيه لا شيء على كل حال.
            if (bccomp($percent, '0', self::SCALE) > 0) {
                $out[$id] = $percent;
            }
        }

        return $out;
    }

    /**
     * يجمّد نسبَ فترةٍ تُقفَل — مرّةً واحدة في عمرها.
     *
     * يُستدعى من {@see CloseInvestmentPeriod} داخل معاملته. وحارسُ
     * «مرّةً واحدة» هو الفهرسُ الفريد `(period, investor)` نفسُه: إعادةُ الإقفال — لو حدثت —
     * لا تكتب صفّاً ثانياً ولا تغيّر الأول.
     *
     * @return array<int, string>
     */
    public function freeze(InvestmentPeriod $period): array
    {
        $existing = InvestmentPeriodShare::query()
            ->where('investment_period_id', $period->getKey())
            ->exists();

        $shares = $this->forPeriod((int) $period->getKey());

        if ($existing || $shares === []) {
            return $shares;
        }

        $held = $this->unitsOf($period);

        foreach ($shares as $investorId => $percent) {
            InvestmentPeriodShare::query()->create([
                'investment_period_id' => $period->getKey(),
                'investor_id' => $investorId,
                'units' => $held[$investorId] ?? '0',
                'share_percent' => $percent,
            ]);
        }

        return $shares;
    }

    /** نسبُ الفترة الجارية — ما تعرضه اللوحة تحت «نسبةُ كلِّ شريك الآن». */
    public function current(): array
    {
        $open = InvestmentPeriod::query()->where('status', PeriodStatus::Open)->first();

        return $open === null ? [] : $this->forPeriod((int) $open->getKey());
    }
}
