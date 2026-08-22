<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Support\Facades\DB;

/**
 * The one way `products.stock_unit` — and, through it, every `WarehouseStock`/`StockBatch` row
 * for this product's variants — ever changes after creation.
 *
 * **What is on the shelf is discarded, not carried over, and that is the whole point.** 200 bags
 * are not 200 kilograms. This used to relabel the balance and leave the figure alone, so a shelf
 * counted by hand became a shelf claiming a weight nobody put on a scale — and every costing,
 * shortage and reorder answer downstream inherited it. A quantity is only meaningful in the unit
 * it was measured in, so changing the unit ends it.
 *
 * **It leaves through the ledger, not behind it.** {@see \Tests\Feature\Inventory\StockLedgerTest}
 * states the invariant this context exists to hold — for every (warehouse, size) the balance
 * equals the signed sum of its movements — so a balance quietly set to zero would break the one
 * rule all the machinery here serves. Each non-empty shelf is emptied by an `Adjustment` out,
 * recorded **before** the unit changes so it carries the unit the stock was actually counted in.
 * That is also what keeps «لماذا اختفى الرصيد؟» answerable a year later, by name and by date.
 *
 * **Re-picking the unit it already has does nothing at all.** Discarding a shelf because somebody
 * opened the sheet and tapped what was already selected would be the worst possible reading of
 * this endpoint.
 *
 * **Every balance and every batch moves in the same transaction, under the same locks
 * `ApplyStockChange` already uses for cross-row consistency** — so a stock movement racing this
 * update either sees the unit before or after, never a balance in one unit sitting beside a batch
 * in another. Locked in ascending (warehouse, variant) order for the same deadlock-avoidance
 * reason {@see ApplyStockChange::moveTransferBalances()} documents.
 *
 * Scoped to the whole product, not one variant: `stock_unit`, like `pricing_unit`, is a fact
 * about the product, and a bag counted in kilos in one warehouse and pieces in another is not a
 * number anyone could reconcile.
 */
final class SetStockUnit
{
    public function __construct(
        private readonly RecordStockMovement $recordMovement,
    ) {}

    /**
     * @param  int  $actorId  who is answerable for discarding the balances — the adjustment rows
     *                        name them, exactly as every other movement names its author.
     */
    public function __invoke(Product $product, PricingUnit $unit, int $actorId): Product
    {
        // Nothing to do, and nothing to destroy. Checked before the transaction opens so the
        // common "opened the sheet, changed nothing" path takes no locks at all.
        if ($product->stock_unit === $unit) {
            return $product;
        }

        // **Outside the transaction, and before the unit changes.** `RecordStockMovement` opens
        // its own transaction and resolves the unit it stamps from `$variant->product->stock_unit`
        // — so this has to run while that still says the *old* unit, or the bags would be recorded
        // as leaving in kilograms.
        $this->discardBalances($product, $actorId);

        return DB::transaction(function () use ($product, $unit): Product {
            $product->stock_unit = $unit;
            $product->save();

            $variantIds = $product->variants()->pluck('id');

            WarehouseStock::query()
                ->whereIn('product_variant_id', $variantIds)
                ->orderBy('warehouse_id')
                ->orderBy('product_variant_id')
                ->lockForUpdate()
                ->get()
                ->each(function (WarehouseStock $stock) use ($unit): void {
                    $stock->unit = $unit;
                    $stock->save();
                });

            // Emptied by the adjustments above, but relabelled all the same: a fully consumed
            // batch keeps its row for the cost history, and a spent row left in the old unit
            // would be the one thing in this product's records still saying "piece".
            StockBatch::query()
                ->whereIn('product_variant_id', $variantIds)
                ->orderBy('warehouse_id')
                ->orderBy('product_variant_id')
                ->orderBy('id')
                ->lockForUpdate()
                ->get()
                ->each(function (StockBatch $batch) use ($unit): void {
                    $batch->unit = $unit;
                    $batch->save();
                });

            return $product;
        });
    }

    /**
     * Takes every non-empty shelf for this product down to zero, one adjustment each.
     *
     * A zero balance is skipped rather than adjusted by zero: a ledger line recording no event is
     * noise in a feed people read to explain a discrepancy.
     */
    private function discardBalances(Product $product, int $actorId): void
    {
        $balances = WarehouseStock::query()
            ->whereIn('product_variant_id', $product->variants()->pluck('id'))
            ->where('quantity', '>', 0)
            ->orderBy('warehouse_id')
            ->orderBy('product_variant_id')
            ->get();

        foreach ($balances as $balance) {
            ($this->recordMovement)(StockMovementData::adjustment(
                [
                    'product_variant_id' => $balance->product_variant_id,
                    'warehouse_id' => $balance->warehouse_id,
                    'direction' => 'decrease',
                    'quantity' => (string) $balance->quantity,
                    'notes' => 'تصفير الرصيد عند تغيير وحدة المخزون من '
                        .$product->stock_unit->label().' — الكمية كانت محسوبة بالوحدة القديمة',
                ],
                $actorId,
            ));
        }
    }
}
