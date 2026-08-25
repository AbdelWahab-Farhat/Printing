<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Support\Facades\DB;

/**
 * The one way a shelf's unit — and, through it, every `WarehouseStock` and `StockBatch`
 * snapshotted against it — ever changes after creation.
 *
 * Replaces the `SetStockUnit` that used to hang off a *product*. The requirement has not changed,
 * only its owner: a product bought in by weight and sold by the piece still needs
 * `products.pricing_unit` and this to disagree. What has changed is that the pile now has exactly
 * one owner for the answer, so كيس شحن سادة and كيس شحن مطبوع can no longer insist that one heap
 * of bags is counted two different ways.
 *
 * **Declares the real physical unit, it does not convert one into another.** An item moved from
 * "counted by the piece" to "counted by the kilo" keeps whatever quantities are already on the
 * shelf: the numbers were correct in their own unit before this ran and stay correct after it,
 * because nothing here multiplies or divides them. This is what a storekeeper reaches for the day
 * they realise a thing has always been weighed, not counted, and the system disagreed.
 *
 * **Every balance and every batch moves in the same transaction, under the same locks
 * {@see ApplyStockChange} already uses for cross-row consistency** — so a stock movement racing
 * this update either sees the unit before or after, never a balance in one unit sitting beside a
 * batch in another. Locked in ascending warehouse order for the same deadlock-avoidance reason
 * {@see ApplyStockChange::moveTransferBalances()} documents.
 */
final class SetStockItemUnit
{
    public function __invoke(StockItem $item, PricingUnit $unit): StockItem
    {
        return DB::transaction(function () use ($item, $unit): StockItem {
            $item->unit = $unit;
            $item->save();

            WarehouseStock::query()
                ->where('stock_item_id', $item->getKey())
                ->orderBy('warehouse_id')
                ->lockForUpdate()
                ->get()
                ->each(function (WarehouseStock $stock) use ($unit): void {
                    $stock->unit = $unit;
                    $stock->save();
                });

            StockBatch::query()
                ->where('stock_item_id', $item->getKey())
                ->orderBy('warehouse_id')
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->each(function (StockBatch $batch) use ($unit): void {
                    $batch->unit = $unit;
                    $batch->save();
                });

            return $item;
        });
    }
}
