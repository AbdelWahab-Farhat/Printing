<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Actions\PostPressPurchaseProceeds;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Investor\Support\StillOwed;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * ما خرج من طبقات الصندوق لطلبيات — **التعريفُ الواحد** الذي يقرؤه بندا اللوحة وقائمتاهما.
 *
 * بندان في {@see FundValuation} يقومان على هذا: «بضاعة خرجت ولم تُسلَّم» و«سُلِّمت ولم تُحصَّل».
 * وكلٌّ منهما يُفتح اليوم على قائمة طلبياته ({@see FundGoodsOut}) — ورقمُ اللوحة لا يصدق إلا إن
 * جمعت القائمةُ إليه. فالشرطُ مكتوبٌ هنا مرّةً، والرقمُ والقائمةُ يجمعان الصفوفَ نفسَها: شرطان
 * في موضعين يتّفقان اليوم ويفترقان أوّلَ ما يُعدَّل أحدُهما، والفرقُ لا يُرى إلا حين يجمع أحدٌ
 * القائمةَ بيده فلا تبلغ الرقم.
 *
 * ## بالتكلفة المجمّدة لحظة الخروج
 *
 * (`stock_batch_consumptions.total_cost`) لا بإعادة تسعير: البضاعةُ غادرت الرفّ بذلك الرقم،
 * وأيُّ إعادة حسابٍ اليوم تعطي رقماً آخر بعد أول تحويل.
 *
 * والحركاتُ المعكوسة مستثناةٌ كاملةً — البضاعة رجعت، فهي محسوبةٌ في الرفّ لا هنا. والتحويلُ
 * الداخلي مستثنىً كذلك، وإلا قُرئ سحبُ المصدر بيعاً.
 *
 * ## والسحبُ المسعَّر ليس مال الصندوق أصلاً
 *
 * سادةٌ خرجت بسعرٍ متّفقٍ عليه **بِيعت عند باب المخزن**، فثمنُها في الخزينة بـ
 * {@see PostPressPurchaseProceeds} ولا شأن للصندوق بعدها بالطلبية: لا بتسليمها ولا بتحصيلها
 * ولا بإلغائها. فعدُّها هنا بتكلفتها يحسب المال مرّتين — نقداً في الدرج وبضاعةً في المطبعة.
 *
 * والشرطُ هو الشرطُ نفسه الذي تُقسَّم به الأرباح في {@see OrderDealSlices}: طبقةٌ تحمل سعراً
 * **وسطرٌ اشترى فعلاً** (`order_items.stock_purchased_at`). سعرٌ على طبقةٍ سحبها سطرُ سادةٍ لم
 * يطبع لا يشتري شيئاً، وصاحبُها ما زال راكباً البيع.
 */
final class FundDraws
{
    /**
     * خرجت من الرفّ ولم تصل العميل — ولم تُلغَ.
     *
     * @param  int|null  $dealId  صفقةٌ بعينها، أو كلُّ ما موّله مستثمرون
     */
    public function inFlight(?int $dealId = null): Builder
    {
        return $this->base($dealId)->whereNotIn('o.status', [
            OrderStatus::Delivered->value,
            OrderStatus::Settled->value,
            OrderStatus::Cancelled->value,
        ]);
    }

    /**
     * وصلت العميل ولم يُحصَّل ثمنُها كاملاً.
     *
     * {@see StillOwed} لا حالةُ «تمت التسوية»: الواقعةُ المالية لا زرٌّ يضغطه موظّف،
     * وهو الشرطُ بعينه الذي تفتح به {@see InvestorBalances::releasableInPeriod()} بوّابةَ الإفراج.
     */
    public function uncollected(?int $dealId = null): Builder
    {
        return $this->base($dealId)
            ->whereIn('o.status', [OrderStatus::Delivered->value, OrderStatus::Settled->value])
            ->whereRaw(StillOwed::sql('o'));
    }

    /** كلُّ سحبٍ من طبقةٍ ممولة إلى سطرِ طلبيةٍ ما زال قائماً. */
    private function base(?int $dealId): Builder
    {
        return DB::table('stock_batch_consumptions as c')
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
            ->where(fn ($q) => $q
                ->whereNull('b.printing_sale_price')
                ->orWhereNull('oi.stock_purchased_at'))
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'));
    }
}
