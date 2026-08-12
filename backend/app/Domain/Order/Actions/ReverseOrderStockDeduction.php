<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Inventory\Actions\CreditBackStockBatches;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\InventoryService;
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

    public function __invoke(Order $order, int $employeeId): void
    {
        foreach ($order->items as $item) {
            if ($item->fulfillment_stock_movement_id === null) {
                continue;
            }

            $this->inventory->recordMovement(StockMovementData::orderReversal(
                productVariantId: $item->product_variant_id,
                warehouseId: (int) $order->fulfillment_warehouse_id,
                quantity: $item->producedQuantity(),
                reversedMovementId: $item->fulfillment_stock_movement_id,
                referenceId: $order->getKey(),
                employeeId: $employeeId,
            ));

            $this->reverseProductionCostEntries($item, $employeeId);
        }
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
