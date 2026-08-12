<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;

/**
 * Adds a quantity back to the exact cost layers a movement drew it from.
 *
 * Called only from {@see ApplyStockChange::creditBack()}, after the balance row is already locked
 * and grown — never on its own. `stock_batch_consumptions` rows are never edited or deleted (see
 * that model's docblock), so the movement being reversed still names, permanently, which batches
 * to credit and by how much each.
 */
final class CreditBackStockBatches
{
    public function __invoke(int $stockMovementId): void
    {
        $totals = StockBatchConsumption::query()
            ->where('stock_movement_id', $stockMovementId)
            ->selectRaw('stock_batch_id, SUM(quantity) as total_quantity')
            ->groupBy('stock_batch_id')
            ->get();

        // Locked in ascending id order — the same deadlock-avoidance reasoning
        // RecordStockMovement::moveTransferBalances() already documents, in case two reversals
        // ever touch an overlapping set of batches at once.
        $batches = StockBatch::query()
            ->whereIn('id', $totals->pluck('stock_batch_id'))
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        foreach ($totals as $row) {
            $batch = $batches[$row->stock_batch_id];
            $batch->quantity_remaining = bcadd((string) $batch->quantity_remaining, (string) $row->total_quantity, 3);
            $batch->save();
        }
    }
}
