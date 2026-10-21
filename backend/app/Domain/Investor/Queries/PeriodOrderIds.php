<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * أيُّ الطلبيات لهذه الفترة، وأيُّها ما زال في الطريق.
 *
 * **قاعدتان يقرؤهما اثنان، فتعيشان في مكانٍ واحد.** {@see CloseInvestmentPeriod} يقرّر بهما متى
 * تُقفَل الفترة، و{@see PeriodOrdersByState} يعرض بهما «قيد التسليم» — ونسخةٌ ثانيةٌ على الشاشة
 * كانت تعني طلبيةً يحبس بها الإقفالُ الفترةَ ولا تراها الشاشة.
 *
 * **ولماذا لا تبقيان في الإقفال:** الإقفالُ ← {@see FundValuation} ← {@see FundProfitOwed} ←
 * {@see PeriodOrdersQuery}، فمن يقرأ طلبياتِ الفترة من الإقفال يُغلق حلقة.
 *
 * المواصفة: §١١ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 */
final class PeriodOrderIds
{
    /**
     * طلبياتُ هذه الفترة — بـ`placed_at` بالسقوط إلى `created_at`، بتوقيت المحلّ.
     *
     * وهو العمودُ نفسه الذي تعدّ عليه `OrderTotalsQuery` و`FiltersOrders`، فأرقامُ الصندوق
     * تتّفق مع تقارير الطلبيات بالبناء لا بالمصادفة.
     *
     * @return list<int>
     */
    public function of(InvestmentPeriod $period): array
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
    public function inFlightAmong(array $orderIds): array
    {
        return $this->ids($this->inFlightDraws($orderIds));
    }

    /**
     * أيُّها في الطريق **ولمستثمري الصندوق فيها ربحٌ يأتي بالتسليم** — «قيد التسليم» في شاشة الفترة.
     *
     * أضيقُ من {@see inFlightAmong()} عمداً. سحبٌ اشترته المطبعةُ بسعر السادة دفع للمستثمرين
     * هامشَه يومَ غادر الرفّ، وما يأتي بالتسليم بعده للشركة —
     * {@see OrderDealSlices} يُسقطه من القسمة بالشرط نفسِه. فطلبيةٌ كلُّ
     * سحبها كذلك لا ينتظر مستثمروها منها شيئاً، و«قيد التسليم» عليها كان يقول «متوقّع: 0» تحت
     * ربحٍ قبضوه — المالك 2026-10-19.
     *
     * **والإقفالُ يبقى على الأوسع.** تلك قاعدتُه في انتظار الفترة، وهذه قاعدةُ ما يُعرض.
     *
     * @param  list<int>  $orderIds
     * @return list<int>
     */
    public function owingDeliveryProfitAmong(array $orderIds): array
    {
        return $this->ids($this->inFlightDraws($orderIds)?->where(fn ($q) => $q
            ->whereNull('b.printing_sale_price')
            ->orWhereNull('oi.stock_purchased_at')));
    }

    /**
     * @param  list<int>  $orderIds
     */
    private function inFlightDraws(array $orderIds): ?Builder
    {
        if ($orderIds === []) {
            return null;
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
                ->whereNull('r.deleted_at'));
    }

    /**
     * @return list<int>
     */
    private function ids(?Builder $draws): array
    {
        if ($draws === null) {
            return [];
        }

        return $draws
            ->distinct()
            ->orderBy('o.id')
            ->pluck('o.id')
            ->map(fn ($id): int => (int) $id)
            ->all();
    }
}
