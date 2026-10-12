<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Support\FundDeal;
use Illuminate\Support\Facades\DB;

/**
 * طلباتُ الشراء التي أدخلت للصندوق بضاعةً مستلمة — قائمةُ حقل «طلب الشراء» في ورقة المصروف.
 *
 * Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٨. **الشرطُ نفسُه الذي يقبل به التسجيل**
 * ({@see PurchaseOrderFundUnits}): طبقةٌ للصندوق فتحتها حركةُ وصولٍ قائمة لهذا الطلب — فلا يعرض
 * الحقلُ طلباً يرفضه الخادم. الأحدثُ استلاماً أولاً.
 */
final class FundPurchaseOrdersQuery
{
    public function __construct(private readonly FundDeal $fund) {}

    /**
     * @return list<array{id: int, vendor: ?string, order_date: ?string, received_on: ?string, items: list<string>}>
     */
    public function __invoke(int $limit = 50): array
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return [];
        }

        $orders = DB::table('stock_arrivals as sa')
            ->join('stock_arrival_items as sai', 'sai.stock_arrival_id', '=', 'sa.id')
            ->join('stock_batches as b', 'b.stock_movement_id', '=', 'sai.stock_movement_id')
            ->join('purchase_orders as po', 'po.id', '=', 'sa.purchase_order_id')
            ->leftJoin('vendors as v', 'v.id', '=', 'po.vendor_id')
            ->where('b.investor_deal_id', $fundId)
            ->whereNull('b.deleted_at')
            ->whereNull('sa.reversed_at')
            ->whereNull('sa.deleted_at')
            ->whereNull('sai.deleted_at')
            ->whereNull('po.deleted_at')
            ->groupBy('po.id', 'v.name', 'po.order_date')
            ->orderByDesc(DB::raw('max(sa.created_at)'))
            ->orderByDesc('po.id')
            ->limit($limit)
            ->get([
                'po.id',
                'v.name as vendor',
                'po.order_date',
                DB::raw('max(sa.created_at) as received_at'),
            ]);

        if ($orders->isEmpty()) {
            return [];
        }

        // ما اشتراه الصندوقُ في كل طلب — أسماءُ الرفوف، ليعرفه من يختاره دون فتحه.
        $items = DB::table('stock_arrivals as sa')
            ->join('stock_arrival_items as sai', 'sai.stock_arrival_id', '=', 'sa.id')
            ->join('stock_batches as b', 'b.stock_movement_id', '=', 'sai.stock_movement_id')
            ->join('stock_items as si', 'si.id', '=', 'sai.stock_item_id')
            ->whereIn('sa.purchase_order_id', $orders->pluck('id')->all())
            ->where('b.investor_deal_id', $fundId)
            ->whereNull('b.deleted_at')
            ->whereNull('sa.reversed_at')
            ->whereNull('sa.deleted_at')
            ->whereNull('sai.deleted_at')
            ->distinct()
            ->orderBy('si.name')
            ->get(['sa.purchase_order_id', 'si.name']);

        $names = [];

        foreach ($items as $item) {
            $names[(int) $item->purchase_order_id][] = (string) $item->name;
        }

        return $orders->map(fn (object $order): array => [
            'id' => (int) $order->id,
            'vendor' => $order->vendor === null ? null : (string) $order->vendor,
            'order_date' => $order->order_date === null ? null : substr((string) $order->order_date, 0, 10),
            'received_on' => $order->received_at === null ? null : substr((string) $order->received_at, 0, 10),
            'items' => $names[(int) $order->id] ?? [],
        ])->values()->all();
    }
}
