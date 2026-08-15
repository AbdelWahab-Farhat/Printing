<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Support\Facades\DB;

/**
 * The one way `products.stock_unit` — and, through it, every `WarehouseStock`/`StockBatch` row
 * for this product's variants — ever changes after creation.
 *
 * **Declares the real physical unit, it does not convert one into another.** A product moved
 * from "counted by the piece" to "counted by the kilo" keeps whatever quantities are already on
 * the shelf: the numbers were correct in their own unit before this ran and stay correct after
 * it, because nothing here multiplies or divides them. This is what a storekeeper reaches for the
 * day they realise a product has always been weighed, not counted, and the system disagreed.
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
    public function __invoke(Product $product, PricingUnit $unit): Product
    {
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
}
