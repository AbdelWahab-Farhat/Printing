<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Inventory\Actions\CreditBackStockBatches;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;

/**
 * Corrects what left the warehouse, once the press knows what it actually used.
 *
 * **Two people weigh the same run, and the second one is right.** The warehouse weighs what it
 * pulls off the shelf on the way into «جاهزة للطباعة»; the press knows what the job actually
 * consumed by the time it reaches «جاهزة». Asking again there is not a duplicate question — it is
 * the only moment the true figure exists — and this action is what makes the shelf agree with it.
 *
 * **A correction is a restatement, not a patch.** Where a line's figure moved, the original
 * movement is reversed *in full* and the corrected quantity fulfilled fresh, rather than a delta
 * movement being recorded for the difference. Four reasons, and the first is what settles it:
 *
 * - {@see CreditBackStockBatches} credits a movement back **in its entirety** — it sums that
 *   movement's `stock_batch_consumptions` and returns them to their batches. There is no partial
 *   credit anywhere in Inventory, and inventing one means new FIFO-unwinding logic underneath the
 *   one number nobody can afford to have drift.
 * - It works identically in both directions. More used than pulled, or less: the same two steps,
 *   no sign branching in the stock layer at all.
 * - The corrected quantity lands on the **exact original cost layers**. They are credited back
 *   before the re-draw, inside the one transaction the whole move already runs in, so the batches
 *   are there to be drawn from again and `material_cost` comes out right rather than averaged.
 * - `order_items.fulfillment_stock_movement_id` stays **singular**, pointing at the new movement.
 *   That is what lets {@see ReverseOrderStockDeduction} and the entire cancellation path stay
 *   exactly as they are: a delta movement would have left that column naming one of two.
 *
 * **A line whose figure did not move is skipped entirely** — no reversal, no re-draw, no row in
 * the ledger. That is the common case, and a ledger that recorded a pair of movements every time
 * somebody confirmed a number would bury the corrections that matter.
 */
final class RestateOrderStockDeduction
{
    public function __construct(
        private readonly InventoryService $inventory,
        private readonly RecalculateOrderItemCost $recalculateItemCost,
    ) {}

    /**
     * @param  array<string, mixed>  $fields  What the move asked for — see {@see TransitionFields}.
     */
    public function __invoke(Order $order, array $fields, int $employeeId): void
    {
        $order->items->loadMissing('variant.stockItem');

        $warehouseId = (int) $order->fulfillment_warehouse_id;

        foreach ($order->items as $item) {
            $corrected = $this->correctedQuantity($item, $fields);

            if ($corrected === null) {
                continue;
            }

            $this->restate($order, $item, $corrected, $warehouseId, $employeeId);
        }
    }

    /**
     * What this line should now read, or null when nothing about it moved.
     *
     * **Null is "leave it alone", and an absent field means the same thing.** A line whose units
     * agree is never asked — what was sold is what leaves — and a line the form did offer opens
     * holding its existing figure, so an untouched box comes back identical and lands here as
     * null. Only a number a person actually changed gets past this.
     *
     * @param  array<string, mixed>  $fields
     */
    private function correctedQuantity(OrderItem $item, array $fields): ?string
    {
        if (! $item->isStockedInAnotherUnit()) {
            return null;
        }

        $answer = $fields[TransitionFields::stockQuantityKey($item)] ?? null;

        if ($answer === null || $answer === '') {
            return null;
        }

        $was = (string) ($item->warehouse_quantity ?? $item->quantity);

        // Compared numerically, not as strings: «3.5» and «3.500» are the same weight, and a
        // string comparison would reverse and re-draw the whole line to record no change at all.
        return bccomp((string) $answer, $was, 3) === 0 ? null : (string) $answer;
    }

    /**
     * Puts the line's original draw back on the shelf, then takes the corrected one.
     *
     * The order of the two is the whole safety of it: crediting first restores both the balance
     * and the cost layers, so the re-draw is checked against — and priced from — a shelf that
     * holds everything it held before this order touched it.
     */
    private function restate(
        Order $order,
        OrderItem $item,
        string $corrected,
        int $warehouseId,
        int $employeeId,
    ): void {
        $stockItem = $this->inventory->stockItemFor($item->variant);

        // Recorded as an OrderReversal rather than an Adjustment for the reason
        // ReverseOrderStockDeduction gives: this is a system correction with a cause the ledger
        // can name, not an operator's stocktake.
        if ($item->fulfillment_stock_movement_id !== null) {
            $this->inventory->recordMovement(StockMovementData::orderReversal(
                stockItemId: (int) $stockItem->getKey(),
                warehouseId: $warehouseId,
                quantity: (string) ($item->warehouse_quantity ?? $item->quantity),
                reversedMovementId: $item->fulfillment_stock_movement_id,
                referenceId: (int) $order->getKey(),
                employeeId: $employeeId,
            ));
        }

        // Written before the re-draw, because `producedQuantity()` is what the movement below
        // takes off the shelf and it reads this column.
        $item->forceFill(['warehouse_quantity' => $corrected])->save();

        $movement = $this->inventory->recordMovement(StockMovementData::fulfillment([
            'stock_item_id' => $stockItem->getKey(),
            'from_warehouse_id' => $warehouseId,
            'quantity' => $item->producedQuantity(),
            'reference_id' => $order->getKey(),
        ], $employeeId));

        $materialCost = StockBatchConsumption::query()
            ->where('stock_movement_id', $movement->getKey())
            ->sum('total_cost');

        // The pointer moves with it. Cancelling this order later credits back the *corrected*
        // draw against the batches it actually came from — see the class docblock.
        $item->forceFill([
            'material_cost' => Money::round((string) $materialCost),
            'fulfillment_stock_movement_id' => $movement->getKey(),
        ])->save();

        ($this->recalculateItemCost)($item);
    }
}
