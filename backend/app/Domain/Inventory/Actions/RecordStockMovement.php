<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\CatalogService;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Enums\StockBatchSourceType;
use App\Domain\Inventory\Exceptions\FractionalQuantityNotAllowed;
use App\Domain\Inventory\Exceptions\TransferRequiresTwoDifferentWarehouses;
use App\Domain\Inventory\Models\StockMovement;
use Illuminate\Support\Facades\DB;

/**
 * The single write path for stock. Every quantity — and, since batch costing landed, every cost —
 * in the business changed because this ran.
 *
 * One class for all four movement types, because they differ only in which ends are filled —
 * and that difference is already stated on {@see MovementType}.
 * Four near-identical actions would be four places for the balance-and-ledger pairing to drift
 * apart, and the pairing is the entire point.
 *
 * Everything happens in one transaction: the balances move, the batches behind them move with
 * them, and the row explaining all of it is written together, or none of it is. A partial failure
 * here would leave a shelf count with no reason behind it, which is precisely the state this
 * design exists to make impossible.
 */
final class RecordStockMovement
{
    public function __construct(
        private readonly ApplyStockChange $applyStockChange,
        private readonly CatalogService $catalog,
    ) {}

    public function __invoke(StockMovementData $data): StockMovement
    {
        // Outside the transaction: it reads the catalogue and can 404, and holding a lock open
        // while doing so buys nothing. Resolved once and reused for both the whole-quantity guard
        // and the unit every balance touched by this movement is checked/stamped against.
        $variant = $this->catalog->findVariant($data->productVariantId);
        $this->guardWholeQuantity($data, $variant);

        if ($data->fromWarehouseId !== null && $data->fromWarehouseId === $data->toWarehouseId) {
            throw TransferRequiresTwoDifferentWarehouses::make();
        }

        return DB::transaction(function () use ($data, $variant): StockMovement {
            $movement = new StockMovement([
                'quantity' => $data->quantity,
                'notes' => $data->notes,
            ]);

            // Assigned rather than mass-assigned, deliberately. These four are the movement's
            // identity — which size, which direction, whose hands — and none of them may ever
            // be settable by a payload. See RULES.md §9.4.
            $movement->product_variant_id = $data->productVariantId;
            $movement->movement_type = $data->movementType;
            $movement->from_warehouse_id = $data->fromWarehouseId;
            $movement->to_warehouse_id = $data->toWarehouseId;
            $movement->reference_id = $data->referenceId;
            $movement->employee_id = $data->employeeId;

            // Saved before the balances move — not after, as before batch costing landed —
            // because consuming a cost layer needs this row's own id to attach the
            // `stock_batch_consumptions` it produces to. Still one transaction: a balance failure
            // rolls this insert back with everything else, so `test_a_refused_movement_leaves_no
            // _trace_at_all` holds exactly as before.
            $movement->save();

            $this->moveBalances($movement->id, $data, $variant->product->pricing_unit);

            return $movement->load(['productVariant.product', 'fromWarehouse', 'toWarehouse', 'employee']);
        });
    }

    /**
     * Applies both ends of this movement.
     *
     * Only {@see MovementType::InternalTransfer} ever fills both — every other type has exactly
     * one end non-null, so the deadlock-avoidance dance below applies to transfers alone.
     */
    private function moveBalances(int $movementId, StockMovementData $data, PricingUnit $unit): void
    {
        if ($data->fromWarehouseId !== null && $data->toWarehouseId !== null) {
            $this->moveTransferBalances($movementId, $data, $unit);

            return;
        }

        if ($data->fromWarehouseId !== null) {
            $this->applyStockChange->decrease(
                $data->fromWarehouseId, $data->productVariantId, $data->quantity, $unit, $movementId,
            );

            return;
        }

        if ($data->toWarehouseId !== null && $data->movementType === MovementType::OrderReversal) {
            $this->applyStockChange->creditBack(
                $data->toWarehouseId, $data->productVariantId, $unit, $data->reversedMovementId,
            );

            return;
        }

        if ($data->toWarehouseId !== null) {
            $this->applyStockChange->increase(
                $data->toWarehouseId, $data->productVariantId, $data->quantity, $unit,
                $this->batchCost($data), $this->batchSource($data->movementType),
            );
        }
    }

    /**
     * The one case with two rows to lock: relocates the stock, and the cost layers it is made of,
     * from one warehouse to another.
     *
     * Two transfers running at once in opposite directions between the same pair of warehouses
     * would, taken in payload order, each hold the row the other is waiting for — a deadlock
     * PostgreSQL resolves by killing one of them, which surfaces to a storekeeper as a 500 for
     * no reason they could ever act on. Locking both rows in ascending warehouse id first — before
     * either balance actually moves — gives every such transaction the same lock order, so one
     * simply waits; re-locking a row already held costs nothing, so the decrease/relocate calls
     * below can then run in the order that makes business sense (source first, so its cost layers
     * are known before the destination recreates them) regardless of which id is smaller.
     */
    private function moveTransferBalances(int $movementId, StockMovementData $data, PricingUnit $unit): void
    {
        $ids = [$data->fromWarehouseId, $data->toWarehouseId];
        sort($ids);

        foreach ($ids as $warehouseId) {
            $this->applyStockChange->lockBalance($warehouseId, $data->productVariantId);
        }

        $result = $this->applyStockChange->decrease(
            $data->fromWarehouseId, $data->productVariantId, $data->quantity, $unit, $movementId,
        );

        $this->applyStockChange->relocateBatches(
            $data->toWarehouseId, $data->productVariantId, $unit, $result->consumed,
        );
    }

    /**
     * What a brand-new cost layer opens at. `null` — no cost was ever supplied for this
     * movement — becomes `'0.000'`, the same "unknown" placeholder the opening-balance backfill
     * uses; see {@see ApplyStockChange::increase()}.
     */
    private function batchCost(StockMovementData $data): string
    {
        return $data->unitCost ?? '0.000';
    }

    private function batchSource(MovementType $type): StockBatchSourceType
    {
        return match ($type) {
            MovementType::PurchaseArrival => StockBatchSourceType::PurchaseArrival,
            MovementType::Adjustment => StockBatchSourceType::Adjustment,
            // Never reached: InternalTransfer and OrderReversal each relocate/credit back
            // existing batches instead of opening one, and OrderFulfillment/Adjustment-decrease
            // only ever call decrease().
            MovementType::InternalTransfer, MovementType::OrderFulfillment,
            MovementType::OrderReversal => StockBatchSourceType::Adjustment,
        };
    }

    /**
     * Half a shipping bag is a typo, half a kilo is Tuesday.
     *
     * Asked of Catalog rather than answered here: the same rule already stops an order for 2.5
     * bags, and two copies of it would eventually disagree about a product whose pricing unit
     * changed.
     */
    private function guardWholeQuantity(StockMovementData $data, ProductVariant $variant): void
    {
        if (! $this->catalog->requiresWholeQuantities($variant)) {
            return;
        }

        // The quantity is already normalised to three places, so "the fractional part is zero"
        // is the comparison — not a float `floor`, which would answer wrongly for values a
        // storekeeper can plausibly type.
        if (bccomp($data->quantity, bcadd($data->quantity, '0', 0), 3) !== 0) {
            throw FractionalQuantityNotAllowed::make($data->quantity);
        }
    }
}
