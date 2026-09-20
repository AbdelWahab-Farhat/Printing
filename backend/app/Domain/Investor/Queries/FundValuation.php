<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * كم يساوي الصندوق الآن — الرقمُ الذي تُقسَّم عليه كلُّ نسبة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} §٠٫٢.
 *
 * ```
 * قيمة الصندوق = نقد
 *              + بضاعة على الرفّ            (بالتكلفة)
 *              + بضاعة خرجت ولم تُسلَّم      (بالتكلفة)
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
        $shelf = $this->stockOnShelf($dealId);
        $inFlight = $this->drawnCostFor($dealId, fn ($q) => $q->whereNotIn('o.status', [
            OrderStatus::Delivered->value,
            OrderStatus::Settled->value,
            OrderStatus::Cancelled->value,
        ]));
        $receivable = $this->drawnCostFor($dealId, fn ($q) => $q
            ->whereIn('o.status', [OrderStatus::Delivered->value, OrderStatus::Settled->value])
            ->whereColumn('o.paid_amount', '<', 'o.grand_total'));
        $owed = $this->profitOwed($dealId);

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

    /** البضاعةُ التي ما زالت على الرفّ، بتكلفتها المجمّدة يوم وصلت. */
    private function stockOnShelf(?int $dealId): string
    {
        $cost = DB::table('stock_batches')
            ->whereNotNull('investor_deal_id')
            ->when($dealId !== null, fn ($q) => $q->where('investor_deal_id', $dealId))
            ->whereNull('deleted_at')
            ->sum(DB::raw('quantity_remaining * unit_cost'));

        return (string) ($cost ?? '0');
    }

    /**
     * تكلفةُ ما خرج من طبقات الصندوق لطلبياتٍ يصفها الشرط المُمرَّر.
     *
     * **بالتكلفة المجمّدة لحظة الخروج** (`stock_batch_consumptions.total_cost`) لا بإعادة تسعير:
     * البضاعةُ غادرت الرفّ بذلك الرقم، وأيُّ إعادة حسابٍ اليوم تعطي رقماً آخر بعد أول تحويل.
     *
     * والحركاتُ المعكوسة مستثناةٌ كاملةً — البضاعة رجعت، فهي محسوبةٌ في الرفّ لا هنا. والتحويلُ
     * الداخلي مستثنىً كذلك، وإلا قُرئ سحبُ المصدر بيعاً.
     *
     * @param  callable(Builder): mixed  $scope
     */
    private function drawnCostFor(?int $dealId, callable $scope): string
    {
        $query = DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->join('order_items as oi', 'oi.fulfillment_stock_movement_id', '=', 'm.id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->whereNotNull('b.investor_deal_id')
            ->when($dealId !== null, fn ($q) => $q->where('b.investor_deal_id', $dealId))
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereNull('oi.deleted_at')
            ->whereNull('o.deleted_at')
            ->where('m.movement_type', '<>', 'internal_transfer')
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'));

        $scope($query);

        return (string) ($query->sum('c.total_cost') ?? '0');
    }

    /**
     * ما يملكه المستثمرون من ربحٍ لم يصل جيوبهم بعد — غيرَ مسوّىً كان أو في محافظهم.
     *
     * مشيةٌ واحدة على الدفتر كلِّه بـ`deltas()`، لا أربعُ عباراتِ `CASE` تعيد قولَ ما يقوله
     * الـ enum: التعريفُ يعيش في موضعٍ واحد، وتعريفان يفترقان أوّلَ حالةٍ حافّة.
     */
    private function profitOwed(?int $dealId): string
    {
        $total = '0';

        foreach (InvestorWalletEntry::query()->with('reversedEntry')->get() as $entry) {
            $deltas = $entry->deltas();

            // **الجيبُ المحدَّد يخصّ صفقته، وجيبُ المحفظة يخصّ الجميع.** صفُّ الإفراج يسمّي
            // صفقتَه فيُنسب إليها، وصفُّ السحب لا يسمّي شيئاً — فما دام في المحفظة محسوبٌ
            // ديناً مهما كان مصدرُه. وهو دقيقٌ في الحال المستقرّة (لا صفقةَ إلا الصندوق)،
            // ويُبالغ قليلاً في دَين الصندوق ما دامت صفقةٌ قديمةٌ لم تُصفَّ بعد — وهو الاتجاهُ
            // الذي لا يظلم قائماً لصالح داخلٍ جديد.
            if ($dealId === null || (int) ($entry->investor_deal_id ?? 0) === $dealId) {
                $total = bcadd($total, $deltas['profit_deal'], 8);
            }

            $total = bcadd($total, $deltas['profit_wallet'], 8);
        }

        return $total;
    }
}
