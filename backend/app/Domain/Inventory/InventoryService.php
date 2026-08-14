<?php

declare(strict_types=1);

namespace App\Domain\Inventory;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Inventory\Actions\CreateWarehouse;
use App\Domain\Inventory\Actions\DeleteWarehouse;
use App\Domain\Inventory\Actions\RecordStockMovement;
use App\Domain\Inventory\Actions\SetLowStockThreshold;
use App\Domain\Inventory\Actions\SetStockUnit;
use App\Domain\Inventory\Actions\UpdateWarehouse;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\DTOs\StockSummary;
use App\Domain\Inventory\DTOs\WarehouseData;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Inventory\Queries\MovementFilters;
use App\Domain\Inventory\Queries\MovementListQuery;
use App\Domain\Inventory\Queries\StockFilters;
use App\Domain\Inventory\Queries\StockListQuery;
use App\Domain\Inventory\Queries\StockSummaryQuery;
use App\Domain\Inventory\Queries\WarehouseFilters;
use App\Domain\Inventory\Queries\WarehouseListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The Inventory module's public front door.
 *
 * When Orders arrives it will draw stock down by calling `recordMovement()` here — never by
 * writing a balance itself. That is the same seam Catalog has for pricing, and it exists for the
 * same reason: the number on the shelf and the reason it changed are produced by one piece of
 * code, so they cannot disagree.
 *
 * **There is deliberately no `setQuantity()`.** A balance moves because something happened, and
 * the something is the argument. A method that took a number and wrote it would be a way to
 * change stock without saying why, which is the one thing this context is built to prevent — a
 * stocktake correction is `recordAdjustment()`, and it leaves a row behind like everything else.
 *
 * This module depends on Catalog (to resolve a size) and on Identity (to name an employee).
 * Neither depends on it, and neither should: a product does not need to know it is stocked.
 */
class InventoryService
{
    public function __construct(
        private readonly CreateWarehouse $createWarehouse,
        private readonly UpdateWarehouse $updateWarehouse,
        private readonly DeleteWarehouse $deleteWarehouse,
        private readonly RecordStockMovement $recordStockMovement,
        private readonly SetLowStockThreshold $setLowStockThreshold,
        private readonly SetStockUnit $setStockUnit,
        private readonly WarehouseListQuery $warehouseListQuery,
        private readonly StockListQuery $stockListQuery,
        private readonly StockSummaryQuery $stockSummaryQuery,
        private readonly MovementListQuery $movementListQuery,
    ) {}

    // ── warehouses ──────────────────────────────────────────────────────────────────────

    /**
     * @return LengthAwarePaginator<int, Warehouse>
     */
    public function paginateWarehouses(WarehouseFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->warehouseListQuery)($filters, $perPage);
    }

    public function createWarehouse(WarehouseData $data): Warehouse
    {
        return ($this->createWarehouse)($data);
    }

    public function updateWarehouse(Warehouse $warehouse, WarehouseData $data): Warehouse
    {
        return ($this->updateWarehouse)($warehouse, $data);
    }

    /**
     * The balance lines inside go with it — they describe what is in *this* place.
     *
     * Refused while any of them is non-zero: stock inside a deleted warehouse is a number nobody
     * can reconcile. Soft, like every delete here, so the trail records who removed it and the
     * movements that passed through it stay readable.
     */
    public function deleteWarehouse(Warehouse $warehouse): void
    {
        ($this->deleteWarehouse)($warehouse);
    }

    // ── balances ────────────────────────────────────────────────────────────────────────

    /**
     * One warehouse's shelves.
     *
     * @return LengthAwarePaginator<int, WarehouseStock>
     */
    public function paginateStocks(Warehouse $warehouse, StockFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->stockListQuery)($warehouse, $filters, $perPage);
    }

    /**
     * The same shelves in five numbers — how many sizes, how much in total, and how many of them
     * are asking for attention. Counted by the database over the whole warehouse, never over the
     * page somebody happens to be looking at.
     */
    public function summariseStocks(Warehouse $warehouse): StockSummary
    {
        return ($this->stockSummaryQuery)($warehouse);
    }

    /**
     * Set or clear the level someone wants to be warned at. Null clears it.
     */
    public function setLowStockThreshold(WarehouseStock $stock, ?string $threshold): WarehouseStock
    {
        return ($this->setLowStockThreshold)($stock, $threshold);
    }

    /**
     * Declares what a product's stock is counted in, cascading it to every existing balance and
     * batch for the product's variants — see {@see SetStockUnit}.
     */
    public function setStockUnit(Product $product, PricingUnit $unit): Product
    {
        return ($this->setStockUnit)($product, $unit);
    }

    // ── the ledger ──────────────────────────────────────────────────────────────────────

    /**
     * @return LengthAwarePaginator<int, StockMovement>
     */
    public function paginateMovements(MovementFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->movementListQuery)($filters, $perPage);
    }

    /**
     * Record a movement and apply it to the balances it affects, atomically.
     *
     * The only way stock ever moves. The four movement types share this one entry point because
     * they differ only in which ends the {@see StockMovementData} filled in.
     */
    public function recordMovement(StockMovementData $data): StockMovement
    {
        return ($this->recordStockMovement)($data);
    }
}
