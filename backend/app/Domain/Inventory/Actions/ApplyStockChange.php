<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Delivery\Actions\DeleteRegion;
use App\Domain\Inventory\Exceptions\InsufficientStock;
use App\Domain\Inventory\Models\WarehouseStock;

/**
 * Moves one balance, under a lock.
 *
 * **This is the only code in the application that writes `warehouse_stocks.quantity`**, which is
 * why the column is absent from that model's fillable list. Everything else records a reason;
 * this applies it.
 *
 * The lock is the whole point. Read-check-write on a balance is the textbook lost update: two
 * fulfillments of 60 against a shelf of 100 would both read 100, both find it sufficient, and
 * both write 40 — leaving 40 on a shelf that has had 120 taken off it. `lockForUpdate` makes
 * the second transaction wait for the first to commit and then see 40, at which point it
 * correctly refuses. Same reasoning as
 * {@see DeleteRegion}, which locks the parent city rather than
 * counting its regions.
 *
 * Must be called inside a transaction — a lock outside one is released immediately and
 * guarantees nothing. {@see RecordStockMovement} is the caller that provides it.
 */
final class ApplyStockChange
{
    /**
     * Takes `$quantity` out of the warehouse's balance for this size, or refuses.
     */
    public function decrease(int $warehouseId, int $productVariantId, string $quantity): WarehouseStock
    {
        $stock = $this->lockedRow($warehouseId, $productVariantId);

        // No row at all means this size has never been here, which is the same answer as a
        // balance of zero — and gives the storekeeper the number they need either way. Checked
        // before the balance rather than folded into the comparison: there is nothing to
        // decrement, so even a quantity of zero has no row to write it to.
        if ($stock === null) {
            throw InsufficientStock::make('0.000', $quantity);
        }

        $available = (string) $stock->quantity;

        if (bccomp($available, $quantity, 3) < 0) {
            throw InsufficientStock::make($available, $quantity);
        }

        $stock->quantity = bcsub($available, $quantity, 3);
        $stock->save();

        return $stock;
    }

    /**
     * Adds `$quantity` to the warehouse's balance, creating the line the first time a size
     * arrives somewhere.
     */
    public function increase(int $warehouseId, int $productVariantId, string $quantity): WarehouseStock
    {
        $stock = $this->lockedRow($warehouseId, $productVariantId);

        if ($stock === null) {
            // Created inside the caller's transaction and under the same unique index that makes
            // one row per (warehouse, size) a guarantee — so two concurrent first arrivals
            // cannot both insert. The loser fails on the index rather than silently producing a
            // second balance nobody would ever reconcile.
            //
            // Assigned rather than mass-assigned: none of these three is fillable, precisely so
            // that no payload can reach them. `create()` here would be discarded under strict
            // mode — and, worse, would still write a row, with a quantity of zero.
            $stock = new WarehouseStock;
            $stock->warehouse_id = $warehouseId;
            $stock->product_variant_id = $productVariantId;
            $stock->quantity = $quantity;
            $stock->save();

            return $stock;
        }

        $stock->quantity = bcadd((string) $stock->quantity, $quantity, 3);
        $stock->save();

        return $stock;
    }

    /**
     * The balance row for this size in this warehouse, locked until the transaction ends.
     */
    private function lockedRow(int $warehouseId, int $productVariantId): ?WarehouseStock
    {
        return WarehouseStock::query()
            ->where('warehouse_id', $warehouseId)
            ->where('product_variant_id', $productVariantId)
            ->lockForUpdate()
            ->first();
    }
}
