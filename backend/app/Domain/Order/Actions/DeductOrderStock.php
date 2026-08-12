<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;

/**
 * Takes an order's lines out of a warehouse, once — the first real link between `Order` and
 * `Inventory`. Called by {@see ChangeOrderStatus}, inside its own transaction, the moment an
 * order first enters `printing`.
 *
 * **This class never writes a balance or a ledger row itself.**
 * {@see InventoryService::recordMovement()} — the same call every other stock movement in this
 * application goes through — is the only path taken, per RULES.md §3: cross-context work goes
 * through the other module's Service, never around it. One movement per line, so a shortfall on
 * size two of three throws mid-loop and rolls back everything `ChangeOrderStatus` did in this
 * call, including the status change itself and any lines already deducted — there is no partial
 * deduction sitting beside an order that still reads `new`.
 *
 * **The number deducted is exactly what the employee typed, nothing more.** A line whose
 * `warehouse_quantity` is null deducts the ordered quantity unchanged — sales unit and warehouse
 * unit agree, the common case. A line that has one deducts that value as-is, not
 * `quantity * something` — bags weighed together on a scale don't have a meaningful per-piece
 * weight to multiply out, so the employee enters the batch total directly and it is trusted
 * whole. See {@see OrderItem::producedQuantity()}.
 *
 * **Since batch costing landed, this is also the one place `order_items.material_cost` is
 * written.** `InventoryService::recordMovement()` FIFO-consumes cost layers behind the scenes;
 * `stock_batch_consumptions` rows tied to the movement it returns are the only record of what
 * that actually cost, so this action reads them back rather than the movement carrying the
 * figure itself.
 */
final class DeductOrderStock
{
    public function __construct(
        private readonly InventoryService $inventory,
        private readonly RecalculateOrderItemCost $recalculateItemCost,
    ) {}

    public function __invoke(Order $order, int $warehouseId, int $employeeId): void
    {
        foreach ($order->items as $item) {
            $movement = $this->inventory->recordMovement(StockMovementData::fulfillment([
                'product_variant_id' => $item->product_variant_id,
                'from_warehouse_id' => $warehouseId,
                'quantity' => $item->producedQuantity(),
                'reference_id' => $order->getKey(),
            ], $employeeId));

            $materialCost = StockBatchConsumption::query()
                ->where('stock_movement_id', $movement->getKey())
                ->sum('total_cost');

            // The forward pointer ReverseOrderStockDeduction reads back if this order is later
            // cancelled — see the note on OrderItem::fulfillmentStockMovement().
            $item->forceFill([
                'material_cost' => Money::round((string) $materialCost),
                'fulfillment_stock_movement_id' => $movement->getKey(),
            ])->save();

            ($this->recalculateItemCost)($item);
        }
    }
}
