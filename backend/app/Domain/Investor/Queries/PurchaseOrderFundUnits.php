<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Support\LargestRemainder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * وحداتُ الصندوق التي أدخلها طلبُ شراء — أين هي الآن، ومن أخذ ما خرج منها.
 *
 * المواصفة: Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.١–٤.٣.
 *
 * **الطبقاتُ تُعرف بحركة الوصول لا بـ`reference_id`.** `stock_movements.reference_id` يحمل رقمَ
 * طلبيةٍ في مشتريات العجز، والمدخلُ اليدويّ يأخذه من الطلب. أمّا
 * `stock_arrivals.purchase_order_id` ← `stock_arrival_items.stock_movement_id` ←
 * `stock_batches.stock_movement_id` فثابتٌ — ويحمله كلُّ نسخةٍ من الطبقة: النقلُ بين المخازن
 * (`relocateBatches`) والتسليمُ للصندوق (`handOverBatches`) يكتبان حركةَ الوصول الأصلية.
 *
 * **المستهلكُ** سحبٌ من تلك الطبقات تحت `order_fulfillment` أو `scrap_loss` أو تسويةٍ نازلة،
 * لم يُعكس — أو عُكس وذهبت أكياسُه المسعَّرة إلى الشركة (`purchased_layers_to_company`): المطبعةُ
 * اشترتها، فالبيعُ قائم. النقلُ وتسليمُ الملكية وعكسُ الاستلام ليست بيعاً.
 */
final class PurchaseOrderFundUnits
{
    /** الحركاتُ التي يُعدّ صاحبُها مستهلكاً. */
    private const CONSUMING = ['order_fulfillment', 'scrap_loss', 'adjustment'];

    /**
     * بنودُ الصندوق في الطلب، مع طبقاتها.
     *
     * @return array<int, array{
     *     item_id: int,
     *     stock_item_id: int,
     *     received: string,
     *     weight_cents: string,
     *     batches: array<int, array{id: int, warehouse_id: int, stock_item_id: int, stock_movement_id: int, remaining: string, unit_cost: string}>
     * }> بنود الطلب بأرقامها
     */
    public function linesOf(int $purchaseOrderId, int $fundId): array
    {
        $batches = $this->batchesOf($purchaseOrderId, $fundId);

        if ($batches === []) {
            return [];
        }

        $byStockItem = [];

        foreach ($batches as $batch) {
            $byStockItem[$batch['stock_item_id']][$batch['id']] = $batch;
        }

        $items = DB::table('purchase_order_items')
            ->where('purchase_order_id', $purchaseOrderId)
            ->whereNull('deleted_at')
            ->whereIn('stock_item_id', array_keys($byStockItem))
            ->orderBy('id')
            ->get(['id', 'stock_item_id', 'quantity_ordered', 'quantity_received', 'base_total_cost']);

        $lines = [];

        foreach ($items as $item) {
            $received = (string) $item->quantity_received;

            if (bccomp($received, '0', 3) <= 0) {
                continue;
            }

            $lines[(int) $item->id] = [
                'item_id' => (int) $item->id,
                'stock_item_id' => (int) $item->stock_item_id,
                'received' => $received,
                // قيمةُ ما وصل بسعر الأساس — الوزنُ نفسُه الذي تُقسَم به تكاليفُ الوصول
                // (`ReceivePurchaseOrder::splitArrivalCosts`).
                'weight_cents' => LargestRemainder::toCents(Money::round($this->baseValueOf(
                    (string) ($item->base_total_cost ?? '0'),
                    (string) $item->quantity_ordered,
                    $received,
                ))),
                'batches' => $byStockItem[(int) $item->stock_item_id],
            ];
        }

        return $lines;
    }

    /**
     * كلُّ طبقات الصندوق التي أدخلها الطلب ونسخُها، بلا اعتبارٍ لما بقي فيها.
     *
     * @return array<int, array{id: int, warehouse_id: int, stock_item_id: int, stock_movement_id: int, remaining: string, unit_cost: string}>
     */
    public function batchesOf(int $purchaseOrderId, int $fundId): array
    {
        $rows = DB::table('stock_batches as b')
            ->where('b.investor_deal_id', $fundId)
            ->whereNull('b.deleted_at')
            ->whereIn('b.stock_movement_id', DB::table('stock_arrival_items as sai')
                ->join('stock_arrivals as sa', 'sa.id', '=', 'sai.stock_arrival_id')
                ->where('sa.purchase_order_id', $purchaseOrderId)
                ->whereNull('sa.reversed_at')
                ->whereNull('sa.deleted_at')
                ->whereNull('sai.deleted_at')
                ->select('sai.stock_movement_id'))
            ->orderBy('b.id')
            ->get(['b.id', 'b.warehouse_id', 'b.stock_item_id', 'b.stock_movement_id', 'b.quantity_remaining', 'b.unit_cost']);

        $batches = [];

        foreach ($rows as $row) {
            $batches[(int) $row->id] = [
                'id' => (int) $row->id,
                'warehouse_id' => (int) $row->warehouse_id,
                'stock_item_id' => (int) $row->stock_item_id,
                'stock_movement_id' => (int) $row->stock_movement_id,
                'remaining' => (string) $row->quantity_remaining,
                'unit_cost' => (string) $row->unit_cost,
            ];
        }

        return $batches;
    }

    /**
     * من أخذ من هذه الطبقات — سحبٌ لكل (حركة، طبقة)، بكميته ويوم فترته.
     *
     * `$throughConsumptionId` يقصر على ما سُحب **قبل** الهبوط؛ `$afterConsumptionId` على ما سُحب
     * بعده — العكسُ يحتاج الثاني ليردّ ما حمله الفرقُ في تكلفته.
     *
     * @param  list<int>  $batchIds
     * @return list<array{stock_batch_id: int, stock_movement_id: int, quantity: string, order_id: ?int, charged_on: string}>
     */
    public function consumersOf(array $batchIds, ?int $throughConsumptionId = null, ?int $afterConsumptionId = null): array
    {
        if ($batchIds === []) {
            return [];
        }

        $rows = DB::table('stock_batch_consumptions as c')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->leftJoin('orders as o', function ($join): void {
                $join->on('o.id', '=', 'm.reference_id')
                    ->whereIn('m.movement_type', ['order_fulfillment', 'scrap_loss']);
            })
            ->whereIn('c.stock_batch_id', $batchIds)
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereIn('m.movement_type', self::CONSUMING)
            ->when($throughConsumptionId !== null, fn ($q) => $q->where('c.id', '<=', $throughConsumptionId))
            ->when($afterConsumptionId !== null, fn ($q) => $q->where('c.id', '>', $afterConsumptionId))
            ->where(fn ($q) => $q
                ->whereNotExists(fn ($r) => $r->select(DB::raw(1))
                    ->from('stock_movements as r')
                    ->whereColumn('r.reverses_movement_id', 'm.id')
                    ->whereNull('r.deleted_at'))
                // عُكس، وأكياسُه المسعَّرة صارت للشركة لا لطبقتها — المطبعةُ اشترتها فالبيعُ قائم.
                ->orWhere(fn ($sold) => $sold
                    ->whereNotNull('b.printing_sale_price')
                    ->whereExists(fn ($r) => $r->select(DB::raw(1))
                        ->from('stock_movements as r')
                        ->whereColumn('r.reverses_movement_id', 'm.id')
                        ->where('r.purchased_layers_to_company', true)
                        ->whereNull('r.deleted_at'))))
            ->groupBy('c.stock_batch_id', 'c.stock_movement_id', 'o.id', 'o.placed_at', 'o.created_at', 'm.created_at')
            ->orderBy('c.stock_movement_id')
            ->orderBy('c.stock_batch_id')
            ->get([
                'c.stock_batch_id',
                'c.stock_movement_id',
                DB::raw('SUM(c.quantity) as quantity'),
                'o.id as order_id',
                DB::raw('coalesce(o.placed_at, o.created_at, m.created_at) as dated_at'),
            ]);

        $consumers = [];

        foreach ($rows as $row) {
            $consumers[] = [
                'stock_batch_id' => (int) $row->stock_batch_id,
                'stock_movement_id' => (int) $row->stock_movement_id,
                'quantity' => (string) $row->quantity,
                'order_id' => $row->order_id === null ? null : (int) $row->order_id,
                'charged_on' => Carbon::parse((string) $row->dated_at)->toDateString(),
            ];
        }

        return $consumers;
    }

    /** آخرُ استهلاكٍ في القاعدة كلِّها — حدُّ ما قبل الهبوط وما بعده. */
    public function watermark(): int
    {
        return (int) (DB::table('stock_batch_consumptions')->max('id') ?? 0);
    }

    /** قيمةُ ما وصل بسعر الأساس: `base_total_cost × received ÷ ordered`. */
    private function baseValueOf(string $baseTotal, string $ordered, string $received): string
    {
        if (bccomp($ordered, '0', 3) <= 0) {
            return $baseTotal;
        }

        return bcdiv(bcmul($baseTotal, $received, 10), $ordered, 10);
    }
}
