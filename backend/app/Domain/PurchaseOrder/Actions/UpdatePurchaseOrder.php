<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Customer\Actions\SyncCustomerShops;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderItemData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderItemDoesNotBelongToOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNotEditable;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Replaces a purchase order's fields and lines with what was sent — only while it is still
 * {@see PurchaseOrderStatus::New}.
 *
 * Lines are synced the same way {@see SyncCustomerShops} syncs a
 * customer's shops: an entry carrying an `id` updates that line, one without creates a new line,
 * and any existing line missing from the set is removed. Safe here specifically because nothing
 * may have shipped against a `new` order yet — there is no `quantity_received` on any line to
 * lose by deleting it.
 *
 * @throws PurchaseOrderNotEditable
 * @throws PurchaseOrderItemDoesNotBelongToOrder
 */
final class UpdatePurchaseOrder
{
    public function __invoke(PurchaseOrder $order, PurchaseOrderData $data): PurchaseOrder
    {
        if (! $order->status->isEditable()) {
            throw PurchaseOrderNotEditable::make($order->status);
        }

        return DB::transaction(function () use ($order, $data): PurchaseOrder {
            // One save rather than two: fillable and non-fillable fields are combined before
            // the single save() call below, so the whole edit lands as one UPDATE and one audit
            // log entry, not two.
            $order->fill([
                'order_date' => $data->orderDate,
                'expected_date' => $data->expectedDate,
                'notes' => $data->notes,
            ]);
            $order->vendor_id = $data->vendorId;
            $order->warehouse_id = $data->warehouseId;
            $order->save();

            $this->syncItems($order, $data->items);

            return $order->load(['vendor', 'warehouse', 'items.productVariant.product']);
        });
    }

    /**
     * @param  list<PurchaseOrderItemData>  $items
     */
    private function syncItems(PurchaseOrder $order, array $items): void
    {
        $keptIds = [];

        foreach ($items as $item) {
            if ($item->id !== null) {
                // Scoped through the relation, so another order's line is never found here.
                $existing = $order->items()->whereKey($item->id)->first();

                if ($existing === null) {
                    throw PurchaseOrderItemDoesNotBelongToOrder::make($item->id, (int) $order->getKey());
                }

                $existing->fill(['quantity_ordered' => $item->quantityOrdered]);
                $existing->product_variant_id = $item->productVariantId;
                $existing->save();
                $keptIds[] = $existing->getKey();

                continue;
            }

            $created = new PurchaseOrderItem(['quantity_ordered' => $item->quantityOrdered]);
            $created->purchase_order_id = $order->id;
            $created->product_variant_id = $item->productVariantId;
            $created->quantity_received = '0.000';
            $created->save();

            $keptIds[] = $created->getKey();
        }

        // One line at a time rather than a mass delete on the relation: a mass delete fires no
        // model events, which would leave the audit trail with nothing to say a line ever
        // existed — the same reasoning SyncCustomerShops documents. A purchase order has a
        // handful of lines.
        $order->items()
            ->whereKeyNot($keptIds)
            ->each(fn (PurchaseOrderItem $item) => $item->delete());
    }
}
