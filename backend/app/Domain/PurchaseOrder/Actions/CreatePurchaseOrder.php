<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Drafts a purchase order: the document, then every line it was raised with, in one transaction.
 *
 * Always lands in {@see PurchaseOrderStatus::New} — nothing is sent to a vendor and no stock
 * moves until {@see SendPurchaseOrder} or {@see ReceivePurchaseOrder} says otherwise.
 */
final class CreatePurchaseOrder
{
    public function __invoke(PurchaseOrderData $data): PurchaseOrder
    {
        return DB::transaction(function () use ($data): PurchaseOrder {
            $order = new PurchaseOrder([
                'order_date' => $data->orderDate,
                'expected_date' => $data->expectedDate,
                'notes' => $data->notes,
            ]);

            // Assigned rather than mass-assigned, deliberately — see the class docblock on
            // PurchaseOrder. Status is never taken from the payload; a new order is always new.
            $order->vendor_id = $data->vendorId;
            $order->warehouse_id = $data->warehouseId;
            $order->status = PurchaseOrderStatus::New;
            $order->save();

            foreach ($data->items as $item) {
                $orderItem = new PurchaseOrderItem(['quantity_ordered' => $item->quantityOrdered]);
                $orderItem->purchase_order_id = $order->id;
                $orderItem->product_variant_id = $item->productVariantId;
                $orderItem->quantity_received = '0.000';
                $orderItem->save();
            }

            return $order->load(['vendor', 'warehouse', 'items.productVariant.product']);
        });
    }
}
