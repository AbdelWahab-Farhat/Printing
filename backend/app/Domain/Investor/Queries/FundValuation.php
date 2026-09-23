<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Support\Money;

/**
 * كم يساوي الصندوق الآن — الرقمُ الذي تُقسَّم عليه كلُّ نسبة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} §٠٫٢.
 *
 * ```
 * قيمة الصندوق = نقد
 *              + بضاعة على الرفّ            (بالتكلفة)
 *              + بضاعة خرجت ولم تُسلَّم      (بالتكلفة، خلا ما اشترته المطبعة سادةً)
 *              + مبيعات سُلِّمت ولم تُحصَّل   (بتكلفتها)
 *              − أرباحٌ لم تصل جيبَ أصحابها بعد
 * ```
 *
 * ## المبدأ الواحد وراء البنود الأربعة
 *
 * **كلُّ أصلٍ يدخل بتكلفته، وكلُّ هامشٍ يخصّ فترةَ طلبيته.** بضاعةٌ خرجت في سبتمبر وتُسلَّم في
 * أكتوبر مالُ الصندوق بتكلفتها عند الحافّة، **وربحُها لسبتمبر** — فيسترجع حَمَلةُ أكتوبر رأسَ
 * المال الذي تمثّله ويبقى هامشُها لأصحابه. ولو قُوِّمت بسعر بيعها لاقتسم الداخلون الجدد هامشاً
 * صنعه غيرُهم، وهو بالضبط ما يمنعه التقويمُ بالتكلفة.
 *
 * ## ولماذا يُطرح الربحُ المستحقّ
 *
 * ربحٌ في جيب مستثمر — أُفرِج عنه أو لم يُفرَج — **دَينٌ على الصندوق لا رأسُ مالٍ عامل**. النقدُ
 * الذي يقابله ما زال في الخزينة، فلو تُرك في القيمة لقُسِّم على الجميع مرّةً ثانية: يأخذ صاحبُه
 * نصيبَه منه بوصفه ربحاً، ثم يأخذ الباقون نصيبَهم منه بوصفه رأسَ مال.
 *
 * **ورأسُ المال لا يُطرح**، وهو الفرق: رأسُ المال هو الذي يعمل، وطرحُه يُفرِّغ الصندوق من نفسه.
 *
 * ## والقراءةُ من الدفاتر لا من أعمدة رصيد
 *
 * النقدُ مشيُ {@see InvestmentCashEntry}، والربحُ المستحقّ مشيُ `deltas()` — التعريفُ الواحد
 * الذي تقرأه كلُّ شاشةٍ وكلُّ سقف. أربعُ عباراتِ `CASE` في SQL تقول الشيء نفسه اليوم وتفترق عنه
 * أوّلَ ما يُضاف نوعُ حركة.
 */
final class FundValuation
{
    /**
     * **كلُّ بندٍ يُقرأ من تعريفه لا من نسخةٍ هنا.** كلُّ بندٍ في اللوحة صار يُفتح على قائمته —
     * الرفُّ على موادّه، والبضاعةُ الخارجة على طلبياتها، والربحُ المستحقّ على ما صنعه — ورقمُ
     * اللوحة لا يصدق إلا إن جمعت القائمةُ إليه. فالرقمُ والقائمةُ يقرآن الصفوفَ نفسَها من الصنف
     * نفسِه، ولا يُعاد هنا كتابةُ شرطٍ يفترق عن أخيه أوّلَ ما يُعدَّل.
     */
    public function __construct(
        private readonly FundShelfStock $shelf,
        private readonly FundDraws $draws,
        private readonly FundProfitOwed $profit,
    ) {}

    /**
     * @param  int|null  $dealId  حين يُمرَّر، تُحسب أصولُ تلك الصفقة وحدها — وهو ما يقرؤه
     *                            {@see UnitPrice}: سعرُ الوحدة يخصّ الصندوق لا صفقةً قديمة
     *                            تجاوره على الرفّ. والنقدُ كاملٌ دائماً: الخزينةُ لا تعرف
     *                            إلا مالَ الصندوق أصلاً.
     * @return array{
     *     cash: string,
     *     stock_on_shelf: string,
     *     goods_in_flight: string,
     *     receivables_at_cost: string,
     *     profit_owed: string,
     *     total: string
     * }
     */
    public function __invoke(?int $dealId = null): array
    {
        $cash = $this->cash();
        $shelf = $this->shelf->value($dealId);
        $inFlight = (string) ($this->draws->inFlight($dealId)->sum('c.total_cost') ?? '0');
        $receivable = (string) ($this->draws->uncollected($dealId)->sum('c.total_cost') ?? '0');
        $owed = $this->profit->total($dealId);

        $total = bcsub(
            bcadd(bcadd(bcadd($cash, $shelf, 8), $inFlight, 8), $receivable, 8),
            $owed,
            8,
        );

        return [
            'cash' => Money::round($cash),
            'stock_on_shelf' => Money::round($shelf),
            'goods_in_flight' => Money::round($inFlight),
            'receivables_at_cost' => Money::round($receivable),
            'profit_owed' => Money::round($owed),
            'total' => Money::round($total),
        ];
    }

    /**
     * ما في الخزينة — مشياً على الدفتر، والاتجاهُ من النوع لا من إشارة.
     *
     * والعكسُ يأخذ نقيضَ اتجاه الصفّ الذي يُبطله، تماماً كما في دفتر المحافظ.
     */
    private function cash(): string
    {
        $total = '0';

        foreach (InvestmentCashEntry::query()->with('reversedEntry')->get() as $entry) {
            $total = bcadd($total, $entry->signedAmount(), 8);
        }

        return $total;
    }
}
