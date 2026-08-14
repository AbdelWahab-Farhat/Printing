<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderItemData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\ProductVariantNotOnPurchaseOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderHasNoWarehouse;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNotReceivable;
use App\Domain\PurchaseOrder\Exceptions\ReceivedQuantityExceedsOrdered;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Vendor\DTOs\StockArrivalData;
use App\Domain\Vendor\DTOs\StockArrivalItemData;
use App\Domain\Vendor\Models\StockArrival;
use App\Domain\Vendor\VendorService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Receives a shipment against a purchase order: posts it through Vendor's own front door, then
 * applies what it means for this order's lines and status.
 *
 * **This class never writes a balance, and never writes `stock_arrival_items` itself.**
 * {@see VendorService::recordStockArrival()} — the same call the plain
 * `POST /stock-arrivals` endpoint makes — is the only path taken to actually move stock, per
 * RULES.md §3: cross-context work goes through the other module's Service, never around it. What
 * happens here is layered strictly on top, in the same transaction: a line's
 * `quantity_received` climbs by what this shipment carried, and the order's status is
 * recomputed from the result.
 *
 * Each line's `final_unit_cost` — the base cost plus its allocated share of the order's
 * additional costs, from {@see AllocatePurchaseOrderAdditionalCosts} — also travels into the
 * {@see StockArrivalItemData} built here, so a shipment's landed cost (and the FIFO stock batch
 * it opens) includes delivery/customs/unloading, not just the vendor's quoted price. Priced
 * against what *this* shipment delivered, which can be less than the order line's own
 * `final_total_cost` on a partial receipt — so the vendor module still never decides a cost, only
 * records the one this module already agreed to.
 *
 * @throws PurchaseOrderNotReceivable
 * @throws PurchaseOrderHasNoWarehouse
 * @throws ProductVariantNotOnPurchaseOrder
 * @throws ReceivedQuantityExceedsOrdered
 */
final class ReceivePurchaseOrder
{
    public function __construct(private readonly VendorService $vendors) {}

    public function __invoke(PurchaseOrder $order, ReceivePurchaseOrderData $data): StockArrival
    {
        if (! in_array($order->status, [PurchaseOrderStatus::New, PurchaseOrderStatus::Arrived], true)) {
            throw PurchaseOrderNotReceivable::make($order->status);
        }

        if ($order->warehouse_id === null) {
            throw PurchaseOrderHasNoWarehouse::make((int) $order->getKey());
        }

        return DB::transaction(function () use ($order, $data): StockArrival {
            // Locked for the rest of the transaction so two concurrent receipts against the
            // same order cannot both read the same quantity_received and both pass the
            // over-receipt guard below — the same reasoning ApplyStockChange locks a balance row
            // for.
            $items = $order->items()->lockForUpdate()->get()->keyBy('product_variant_id');

            foreach ($data->items as $line) {
                $this->guardLine($order, $items, $line);
            }

            $arrival = $this->vendors->recordStockArrival(new StockArrivalData(
                vendorId: $order->vendor_id,
                warehouseId: $order->warehouse_id,
                receivedBy: $data->receivedBy,
                items: array_map(
                    function (ReceivePurchaseOrderItemData $line) use ($items): StockArrivalItemData {
                        /** @var PurchaseOrderItem $orderedLine */
                        $orderedLine = $items->get($line->productVariantId);
                        $unitCost = $orderedLine->final_unit_cost === null ? null : (string) $orderedLine->final_unit_cost;

                        return new StockArrivalItemData(
                            productVariantId: $line->productVariantId,
                            quantity: $line->quantity,
                            unitCost: $unitCost,
                            // Priced against what *this* shipment delivered, not the order line's
                            // own total — a partial receipt costs less than the whole line does.
                            totalCost: $unitCost === null
                                ? null
                                : Money::round(bcmul($unitCost, $line->quantity, 6)),
                        );
                    },
                    $data->items,
                ),
                invoiceNumber: $data->invoiceNumber,
                notes: $data->notes,
                purchaseOrderId: $order->getKey(),
            ));

            foreach ($data->items as $line) {
                /** @var PurchaseOrderItem $item */
                $item = $items->get($line->productVariantId);
                $item->quantity_received = bcadd((string) $item->quantity_received, $line->quantity, 3);
                $item->save();
            }

            $order->status = $this->isFullyReceived($items)
                ? PurchaseOrderStatus::Completed
                : PurchaseOrderStatus::Arrived;
            $order->save();

            return $arrival;
        });
    }

    /**
     * @param  Collection<int, PurchaseOrderItem>  $items  Keyed by product_variant_id.
     *
     * @throws ProductVariantNotOnPurchaseOrder
     * @throws ReceivedQuantityExceedsOrdered
     */
    private function guardLine(PurchaseOrder $order, Collection $items, ReceivePurchaseOrderItemData $line): void
    {
        $item = $items->get($line->productVariantId);

        if ($item === null) {
            throw ProductVariantNotOnPurchaseOrder::make($line->productVariantId, (int) $order->getKey());
        }

        $projected = bcadd((string) $item->quantity_received, $line->quantity, 3);

        if (bccomp($projected, (string) $item->quantity_ordered, 3) > 0) {
            throw ReceivedQuantityExceedsOrdered::make(
                $line->productVariantId,
                (string) $item->quantity_ordered,
                (string) $item->quantity_received,
                $line->quantity,
            );
        }
    }

    /**
     * @param  Collection<int, PurchaseOrderItem>  $items  Already carries this receipt's totals.
     */
    private function isFullyReceived(Collection $items): bool
    {
        return $items->every(
            fn (PurchaseOrderItem $item) => bccomp((string) $item->quantity_received, (string) $item->quantity_ordered, 3) >= 0,
        );
    }
}
