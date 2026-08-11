<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * Drafts a purchase order: the document, then every line it was raised with, in one transaction.
 *
 * Always lands in {@see PurchaseOrderStatus::New} — nothing is sent to a vendor and no stock moves
 * until {@see SendPurchaseOrder} or {@see ReceivePurchaseOrder} says otherwise.
 *
 * Each line's `total_cost` and `unit` are computed here, not trusted from the request: `total_cost`
 * is `unit_cost * quantity_ordered`, and `unit` is a snapshot of the variant's product's
 * `pricing_unit` at the moment the line is written — see the docblocks on
 * {@see PurchaseOrderItem::casts()}. `total_amount` is then derived from every line via
 * {@see RecalculatePurchaseOrderTotal}, the one place that sums a purchase order's cost.
 */
final class CreatePurchaseOrder
{
    public function __construct(private readonly RecalculatePurchaseOrderTotal $recalculateTotal) {}

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

            // One query for every size on the order rather than one per line: each needs its
            // product's pricing_unit for the line's `unit` snapshot.
            $variants = ProductVariant::query()
                ->with('product')
                ->whereIn('id', array_map(fn ($item) => $item->productVariantId, $data->items))
                ->get()
                ->keyBy(fn (ProductVariant $variant) => $variant->getKey());

            foreach ($data->items as $item) {
                /** @var ProductVariant $variant */
                $variant = $variants->get($item->productVariantId);

                $orderItem = new PurchaseOrderItem([
                    'quantity_ordered' => $item->quantityOrdered,
                    'unit_cost' => $item->unitCost,
                ]);
                $orderItem->purchase_order_id = $order->id;
                $orderItem->product_variant_id = $item->productVariantId;
                $orderItem->quantity_received = '0.000';

                // Not fillable — see PurchaseOrderItem's docblock. Computed here, always, so a
                // request can never post its own total or claim a unit the product disagrees with.
                $orderItem->forceFill([
                    'total_cost' => Money::round(bcmul($item->unitCost, $item->quantityOrdered, 6)),
                    'unit' => $variant->product->pricing_unit,
                ]);

                $orderItem->save();
            }

            ($this->recalculateTotal)($order);

            return $order->load(['vendor', 'warehouse', 'items.productVariant.product']);
        });
    }
}
