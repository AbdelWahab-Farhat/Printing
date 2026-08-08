<?php

declare(strict_types=1);

namespace App\Domain\Vendor\Actions;

use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Vendor\DTOs\StockArrivalData;
use App\Domain\Vendor\Models\StockArrival;
use App\Domain\Vendor\Models\StockArrivalItem;
use Illuminate\Support\Facades\DB;

/**
 * Posts a shipment: writes the document, then posts every line through the one path stock is
 * ever allowed to move through.
 *
 * This class never writes `warehouse_stocks` or `stock_movements` itself — each line becomes its
 * own ledger row via {@see InventoryService::recordMovement()}, the same call
 * `StockMovementController::arrivals()` makes for a single-line arrival. One transaction wraps
 * the whole document, so a shipment with three lines lands as three ledger entries and a
 * complete document, or as nothing at all.
 */
final class RecordStockArrival
{
    public function __construct(private readonly InventoryService $inventory) {}

    public function __invoke(StockArrivalData $data): StockArrival
    {
        return DB::transaction(function () use ($data): StockArrival {
            $arrival = new StockArrival([
                'invoice_number' => $data->invoiceNumber,
                'notes' => $data->notes,
            ]);

            // Assigned rather than mass-assigned, deliberately: none of these four may ever be
            // settable from a payload. Same rule RecordStockMovement::__invoke() applies to a
            // ledger row's identity. purchase_order_id is null for a plain arrival — only
            // PurchaseOrder\Actions\ReceivePurchaseOrder ever fills it in, and this class does
            // nothing else with it; see the note on StockArrivalData::$purchaseOrderId.
            $arrival->vendor_id = $data->vendorId;
            $arrival->warehouse_id = $data->warehouseId;
            $arrival->received_by = $data->receivedBy;
            $arrival->purchase_order_id = $data->purchaseOrderId;
            $arrival->save();

            foreach ($data->items as $item) {
                $movement = $this->inventory->recordMovement(StockMovementData::arrival([
                    'product_variant_id' => $item->productVariantId,
                    'to_warehouse_id' => $data->warehouseId,
                    'quantity' => $item->quantity,
                    // Ties the ledger entry back to the document that caused it — the slot the
                    // stock_movements migration set aside for exactly this.
                    'reference_id' => $arrival->id,
                ], $data->receivedBy));

                $arrivalItem = new StockArrivalItem(['quantity' => $item->quantity]);
                $arrivalItem->stock_arrival_id = $arrival->id;
                $arrivalItem->product_variant_id = $item->productVariantId;
                $arrivalItem->stock_movement_id = $movement->id;
                $arrivalItem->save();
            }

            return $arrival->load([
                'vendor', 'warehouse', 'receivedByUser',
                'items.productVariant.product', 'items.stockMovement',
            ]);
        });
    }
}
