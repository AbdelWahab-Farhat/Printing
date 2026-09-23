<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Actions\PostDealEarningsForOrder;
use App\Domain\Investor\Actions\PostDealShare;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\OrderService;
use Illuminate\Support\Facades\DB;

/**
 * «ربح قيد التسليم» — أوّلُ الأرقام الثلاثة في المحفظة، والوحيدُ الذي لا صفَّ له في الدفتر.
 *
 * المواصفة: §٠.٨ و§١٢أ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ```
 * ربح قيد التسليم  →  أرباح معلّقة  →  أرباح متاحة للسحب
 * محسوبٌ هنا           profit_deal       profit_wallet
 * ```
 *
 * ## يُسعَّر ما بلغ «جاهزة» وحده
 *
 * «في حالة الجاهزة تقدر تحسبها، قبل ذلك تكون مجهولة.» الربحُ `grand_total − total_cogs`،
 * و`total_cogs` لا تكتمل قبل «جاهزة»: البضاعةُ تخرج من الرفّ عند «جاهزة للطباعة»، وتكلفةُ الإنتاج
 * تُحسب أوّلَ مرّةٍ تُسمّى فيها الطلبيةُ جاهزة (`ready_at`). فما دون ذلك لا رقمَ له، ولا يُخترع له
 * رقمٌ بتكلفةٍ معيارية يخالف ما يُقبض فعلاً.
 *
 * ## والرقمُ ما سيقيّده التسليمُ بعينه
 *
 * الحسابُ هو حسابُ {@see PostDealEarningsForOrder} خطوةً خطوة: الشريحةُ لكلّ صفقة
 * ({@see OrderDealSlices})، ثم نصيبُ المستثمرين منها بنسبة فترة الطلبية
 * ({@see ProfitShareForEntry})، ثم قسمتُه على الشركاء بـ{@see PostDealShare::preview()} — القسمةُ
 * نفسُها التي يكتب بها. فما يُعرض اليوم هو ما يصل «أرباح معلّقة» يوم التسليم، لا تقديرٌ يقاربه.
 *
 * وهامشُ المكينة (سعرُ السادة) ليس هنا: يُقيَّد عند «جاهزة للطباعة» فيكون في «أرباح معلّقة» قبل
 * أن يُسلَّم شيء.
 */
final class ProfitAwaitingDelivery
{
    /** ما يُقيَّد عندها ربحُ الطلبية — وما بعدها ليس انتظاراً. */
    private const FINISHED = ['delivered', 'settled', 'cancelled'];

    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
        private readonly ProfitShareForEntry $profitShare,
        private readonly PostDealShare $share,
    ) {}

    /**
     * @return array<int, array{amount: string, orders: int}> المستثمر ← نصيبُه وعددُ طلبياته
     */
    public function __invoke(): array
    {
        $amounts = [];
        $orders = [];

        foreach ($this->candidates() as $orderId) {
            foreach ($this->sharesOf($orderId) as $investorId => $amount) {
                $amounts[$investorId] = bcadd($amounts[$investorId] ?? '0', $amount, 8);
                $orders[$investorId][$orderId] = true;
            }
        }

        $out = [];

        foreach ($amounts as $investorId => $amount) {
            $out[$investorId] = [
                'amount' => Money::round($amount),
                'orders' => count($orders[$investorId] ?? []),
            ];
        }

        return $out;
    }

    /**
     * @return array{amount: string, orders: int}
     */
    public function forInvestor(int $investorId): array
    {
        return ($this)()[$investorId] ?? ['amount' => '0.00', 'orders' => 0];
    }

    /**
     * طلبياتٌ خرجت بضاعتُها من رفّ صفقةٍ وبلغت «جاهزة» ولم تبلغ خاتمتَها.
     *
     * **والطريقُ إلى الصفقة سحبُ المخزون نفسه**، كما يقرؤه {@see DealOrdersInFlightQuery}: الطلبيةُ
     * لا تعرف صفقتَها، والطبقةُ التي سُحبت منها تعرف. وسحبٌ عُكس لا يربطها بشيء.
     *
     * @return list<int>
     */
    private function candidates(): array
    {
        return DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->join('order_items as oi', 'oi.fulfillment_stock_movement_id', '=', 'm.id')
            ->join('orders as o', 'o.id', '=', 'oi.order_id')
            ->whereNotNull('b.investor_deal_id')
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereNull('oi.deleted_at')
            ->whereNull('o.deleted_at')
            ->whereNotIn('o.status', self::FINISHED)
            // `ready_at` لا يُمحى، فطلبيةٌ رجعت من الطريق تبقى مسعَّرةً بتكلفتها التي حُسبت.
            ->whereNotNull('o.ready_at')
            ->whereNotNull('o.total_cogs')
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'))
            ->distinct()
            ->orderBy('o.id')
            ->pluck('o.id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    /**
     * نصيبُ كلّ شريكٍ من طلبيةٍ واحدة لو سُلِّمت الآن.
     *
     * @return array<int, string>
     */
    private function sharesOf(int $orderId): array
    {
        $order = $this->orders->profitAttributionFor($orderId);

        if ($order === null || $order['gross_profit'] === null || $order['lines'] === []) {
            return [];
        }

        $slices = OrderDealSlices::profitsOf(OrderDealSlices::forOrder(
            $order,
            $this->inventory->consumptionBreakdownFor(
                array_map(fn (array $line) => $line['movement_id'], $order['lines']),
            ),
        ));

        $out = [];

        foreach ($slices as $dealId => $slice) {
            $deal = InvestorDeal::query()->whereKey($dealId)->first();

            if ($deal === null) {
                continue;
            }

            $cut = $deal->investorsCutOf(
                $slice,
                $this->profitShare->bySource($deal, AuditSubject::Order->value, $orderId),
            );

            foreach ($this->share->preview($deal, $cut, AuditSubject::Order->value, $orderId) as $investorId => $amount) {
                $out[$investorId] = bcadd($out[$investorId] ?? '0', $amount, 8);
            }
        }

        return $out;
    }
}
