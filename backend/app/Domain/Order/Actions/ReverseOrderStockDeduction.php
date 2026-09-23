<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Inventory\Actions\CreditBackStockBatches;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\InventoryService;
use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\UndeliveredDisposition;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;

/**
 * Undoes what {@see DeductOrderStock} did, for an order that is being cancelled after its stock
 * already left the warehouse.
 *
 * **Credits back the exact batches each line drew from — never a fresh one at an averaged
 * cost.** {@see CreditBackStockBatches} does the crediting;
 * `OrderItem::fulfillment_stock_movement_id` is what tells this action which movement's
 * `stock_batch_consumptions` to read back per line. Recorded as its own
 * {@see MovementType::OrderReversal}, not an `Adjustment` — this is a
 * system-generated correction with a cause the ledger can name, not an operator's stocktake.
 *
 * **Every production-cost entry a line carries is voided by a further entry pointing back at it,
 * never edited or deleted** — the same rule `order_payments` and `production_cost_entries`
 * themselves already follow.
 *
 * **`order_items.material_cost`/`labor_cost`/`overhead_cost`/`cogs` and `orders.total_cogs` are
 * left untouched.** They are the historical record of what production actually cost before the
 * order was written off — a fact about the day the work was done, the same treatment
 * `order_items.warehouse_quantity` and `stock_arrival_items.unit_cost` already get. The reversal
 * is a separate accounting event, not a rewrite of what happened.
 *
 * Only lines that reached printing have anything to undo — a line with no
 * `fulfillment_stock_movement_id` never took stock out in the first place.
 */
final class ReverseOrderStockDeduction
{
    public function __construct(private readonly InventoryService $inventory) {}

    /**
     * @param  bool  $printedMaterialIsLost  **الفرق بين الإلغاء والحذف، وهو فرقٌ حقيقيّ لا علم.**
     *                                       الإلغاء نهاية: أكياسٌ طُبعت بشعار زبونٍ تراجع لا تعود
     *                                       إلى رفٍّ تُباع منه، فتُشطب. **والحذف قابلٌ للاستعادة**،
     *                                       و{@see RestoreOrder} تسحب المخزون من جديد — فلو شُطب
     *                                       هنا لما وجدت الاستعادةُ ما تسحبه ولارتدّت بـ«الكمية
     *                                       المتوفرة لا تكفي». فيُمرّره {@see ChangeOrderStatus}
     *                                       وحده، و{@see DeleteOrder} يترك الافتراض.
     */
    public function __invoke(Order $order, int $employeeId, bool $printedMaterialIsLost = false): void
    {
        // One query for the whole order rather than one per line; strict-mode lazy loading is on
        // outside production, so the hop from a line to its shelf has to be asked for explicitly.
        $order->items->loadMissing('variant.stockItem');

        foreach ($order->items as $item) {
            if ($item->fulfillment_stock_movement_id === null) {
                continue;
            }

            // **البضاعة التي مرّت على المكينة لا تعود إلى الرفّ.** أكياسٌ تحمل شعار زبونٍ ألغى
            // لا تساوي شيئاً لأحدٍ غيره، وإعادتُها ترفع رصيد المخزن ببضاعةٍ لا تُباع — ويقتسم
            // قيمتَها الوهمية مَن يدخل بعد ذلك.
            if ($printedMaterialIsLost && $this->carriesArtwork($order, $item)) {
                $this->reverseProductionCostEntries($item, $employeeId);
                $this->writeOffPrintedMaterial($order, $item, $employeeId);

                continue;
            }

            // Resolved rather than read off the line: a line names a size, a warehouse holds a
            // shelf, and only Inventory maps one to the other. A line that got this far has a
            // shelf by construction — it could not have been fulfilled otherwise — so the throw
            // inside is unreachable here rather than merely unlikely.
            $stockItem = $this->inventory->stockItemFor($item->variant);

            $this->inventory->recordMovement(StockMovementData::orderReversal(
                stockItemId: (int) $stockItem->getKey(),
                warehouseId: (int) $order->fulfillment_warehouse_id,
                quantity: $item->producedQuantity(),
                reversedMovementId: $item->fulfillment_stock_movement_id,
                referenceId: $order->getKey(),
                employeeId: $employeeId,
                // **The half of «استلم الزبون ما استلمش، المطبعة تتحمّل» that lives in the
                // warehouse.** A line that bought its plain material off a deal paid for it the
                // day it left the shelf, and that money is in an investor's ledger already.
                // Crediting the goods back to his cost layers would leave him holding both, and
                // the next order would buy the same kilo from him a second time — so those
                // layers come back as the company's own stock, at what the company paid for
                // them. Everything else on the line credits back exactly as before.
                purchasedLayersBelongToTheCompany: $item->stock_purchased_at !== null,
            ));

            $this->reverseProductionCostEntries($item, $employeeId);
        }
    }

    /**
     * هل تحمل بضاعةُ هذا السطر شعارَ الزبون الآن؟
     *
     * **سؤالان لا واحد، والخلطُ بينهما هو العطب الذي كان هنا.**
     *
     * الأول: أهذا سطرٌ تطبعه مكينتُنا أصلاً؟ — يجيب عنه {@see UndeliveredDisposition::forItem()}،
     * وهو المصدر الوحيد لهذه القسمة في النظام كلّه، يقرأه هذا الفعل و{@see RecordPartialDelivery}
     * و`TransitionFields` معاً فلا تفترق جملةُ الشاشة عن فعل الزرّ.
     *
     * والثاني — **وهو ما كان ناقصاً**: أطُبع فعلاً بعدُ؟ المخزون يخرج عند «جاهزة للطباعة»، **قبل
     * الطباعة بأيام**. فطلبيةٌ أُلغيت بعد ساعةٍ من خروج البضاعة بضاعتُها سادةٌ نظيفة على الطاولة،
     * وشطبُها خسارةً يحرق مالاً لم يُحرق. و`ready_at` هو ما يفصل: بلوغُ «جاهزة» يعني أن المكينة
     * قد مرّت. وهي العلامةُ نفسُها التي يقرأها `DealOrdersInFlightQuery` للسؤال المجاور — «متى لم
     * تعد المطبعة تستطيع تغيير رأيها» — لا علامةٌ مخترعةٌ لهذا الموضع.
     *
     * **وسطرُ السادة يعود دائماً** مهما تأخّر الإلغاء، لأنه لا يُطبع أبداً. و«الوسيط» لا يصل هنا
     * إطلاقاً: {@see OrderFlow::deductsStock()} تمنعه من سحب مخزون، فلا
     * `fulfillment_stock_movement_id` له ولا شيءَ يُعاد.
     */
    private function carriesArtwork(Order $order, OrderItem $item): bool
    {
        return $order->ready_at !== null
            && UndeliveredDisposition::forItem($item) === UndeliveredDisposition::WrittenOff;
    }

    /**
     * المادةُ التي خرجت ولم تعد — تُسجَّل خسارةً مسمّاة لا تختفي بين الأرقام.
     *
     * **بتكلفة المادة وحدها، لا بـ`cogs` السطر كلِّه.** العمالةُ والمصاريف العامة يعكسها
     * {@see reverseProductionCostEntries()} بصفوفٍ مقابلة قبل هذا السطر بلحظة؛ فجمعُها هنا ثانيةً
     * يحسب الشيء مرّتين. والسؤال الذي يجيب عنه هذا الصفّ واحدٌ بعينه: **كم كانت تساوي البضاعة التي
     * غادرت الرفّ ولم ترجع إليه؟**
     *
     * ونوعُه {@see ManufacturingCostType::DeliveryLoss} لا نوعٌ جديد: الواقعة هي هي — بضاعةٌ
     * صُنعت ولم يأخذها أحد — سواءٌ تركها الزبون على الطاولة أو ألغى قبل أن يصل. ونوعٌ ثالث يقول
     * الشيء نفسه يحتاج ذراعاً في كل `match` شاملة ولا يضيف جواباً.
     */
    private function writeOffPrintedMaterial(Order $order, OrderItem $item, int $employeeId): void
    {
        $amount = $item->material_cost;

        // سطرٌ بلا تكلفة مادة لا خسارة فيه تُكتب — وصفٌّ بصفر ضجيجٌ في تقريرٍ يُقرأ.
        if ($amount === null || bccomp((string) $amount, '0', 2) <= 0) {
            return;
        }

        $entry = new ProductionCostEntry;
        $entry->order_id = $order->getKey();
        $entry->order_item_id = $item->getKey();
        $entry->cost_type = ManufacturingCostType::DeliveryLoss;
        $entry->quantity = $item->producedQuantity();
        $entry->rate = null;
        $entry->amount = (string) $amount;
        $entry->recorded_by = $employeeId;
        $entry->incurred_at = now();
        $entry->notes = 'إلغاء بعد الطباعة — البضاعة لا تعود إلى الرفّ';
        $entry->save();
    }

    /**
     * Every entry this line still carries that is neither a reversal itself nor already
     * undone — see `RecalculateOrderItemManufacturingCost::activeEntriesFor()`, the same query.
     *
     * Scoped to per-line entries: nothing today ever writes an order-level one
     * (`order_item_id` null) — that shape is reserved for shared overhead allocation, which is
     * not built yet — so there is nothing of that kind to reverse.
     */
    private function reverseProductionCostEntries(OrderItem $item, int $employeeId): void
    {
        $active = ProductionCostEntry::query()
            ->where('order_item_id', $item->getKey())
            ->whereNull('reverses_entry_id')
            ->whereDoesntHave('reversal')
            ->get();

        foreach ($active as $entry) {
            $reversal = new ProductionCostEntry;
            $reversal->order_id = $entry->order_id;
            $reversal->order_item_id = $entry->order_item_id;
            $reversal->cost_type = $entry->cost_type;
            $reversal->quantity = $entry->quantity;
            $reversal->rate = $entry->rate;
            $reversal->amount = $entry->amount;
            $reversal->recorded_by = $employeeId;
            $reversal->incurred_at = now();
            $reversal->reverses_entry_id = $entry->getKey();
            $reversal->save();
        }
    }
}
