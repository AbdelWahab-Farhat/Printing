<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Actions;

use App\Domain\Catalog\CatalogService;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Exceptions\FractionalQuantityNotAllowed;
use App\Domain\Inventory\Exceptions\TransferRequiresTwoDifferentWarehouses;
use App\Domain\Inventory\Models\StockMovement;
use Illuminate\Support\Facades\DB;

/**
 * The single write path for stock. Every quantity in the business changed because this ran.
 *
 * One class for all four movement types, because they differ only in which ends are filled —
 * and that difference is already stated on {@see MovementType}.
 * Four near-identical actions would be four places for the balance-and-ledger pairing to drift
 * apart, and the pairing is the entire point.
 *
 * Everything happens in one transaction: the balances move and the row explaining them is
 * written together, or neither is. A partial failure here would leave a shelf count with no
 * reason behind it, which is precisely the state this design exists to make impossible.
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
            $this->moveBalances($data, $variant->product->pricing_unit);

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

            $movement->save();

            return $movement->load(['productVariant.product', 'fromWarehouse', 'toWarehouse', 'employee']);
        });
    }

    /**
     * Applies both ends, in an order that cannot deadlock.
     *
     * Two transfers running at once in opposite directions between the same pair of warehouses
     * would, taken in payload order, each hold the row the other is waiting for — a deadlock
     * PostgreSQL resolves by killing one of them, which surfaces to a storekeeper as a 500 for
     * no reason they could ever act on. Locking in ascending warehouse id instead gives every
     * transaction the same order, so one simply waits.
     */
    private function moveBalances(StockMovementData $data, PricingUnit $unit): void
    {
        $decreaseFirst = $data->toWarehouseId === null
            || ($data->fromWarehouseId !== null && $data->fromWarehouseId < $data->toWarehouseId);

        if ($decreaseFirst) {
            $this->decrease($data, $unit);
            $this->increase($data, $unit);

            return;
        }

        $this->increase($data, $unit);
        $this->decrease($data, $unit);
    }

    private function decrease(StockMovementData $data, PricingUnit $unit): void
    {
        if ($data->fromWarehouseId === null) {
            return;
        }

        $this->applyStockChange->decrease($data->fromWarehouseId, $data->productVariantId, $data->quantity, $unit);
    }

    private function increase(StockMovementData $data, PricingUnit $unit): void
    {
        if ($data->toWarehouseId === null) {
            return;
        }

        $this->applyStockChange->increase($data->toWarehouseId, $data->productVariantId, $data->quantity, $unit);
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
