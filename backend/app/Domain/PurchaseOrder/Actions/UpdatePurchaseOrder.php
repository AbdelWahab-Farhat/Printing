<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Actions\SyncCustomerShops;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderItemData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderItemDoesNotBelongToOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNotEditable;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\Money;
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
 * Every line's `total_cost` and `unit` are recomputed the same way {@see CreatePurchaseOrder}
 * computes them — never trusted from the request — and `total_amount` is re-derived from the
 * result via {@see RecalculatePurchaseOrderTotal}.
 *
 * @throws PurchaseOrderNotEditable
 * @throws PurchaseOrderItemDoesNotBelongToOrder
 */
final class UpdatePurchaseOrder
{
    public function __construct(private readonly RecalculatePurchaseOrderTotal $recalculateTotal) {}

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
            ($this->recalculateTotal)($order);

            return $order->load(['vendor', 'warehouse', 'items.productVariant.product']);
        });
    }

    /**
     * @param  list<PurchaseOrderItemData>  $items
     */
    private function syncItems(PurchaseOrder $order, array $items): void
    {
        $keptIds = [];

        // One query for every size on the order rather than one per line: each needs its
        // product's pricing_unit for the line's `unit` snapshot.
        $variants = ProductVariant::query()
            ->with('product')
            ->whereIn('id', array_map(fn (PurchaseOrderItemData $item) => $item->productVariantId, $items))
            ->get()
            ->keyBy(fn (ProductVariant $variant) => $variant->getKey());

        foreach ($items as $item) {
            /** @var ProductVariant $variant */
            $variant = $variants->get($item->productVariantId);

            $totalCost = Money::round(bcmul($item->unitCost, $item->quantityOrdered, 6));

            if ($item->id !== null) {
                // Scoped through the relation, so another order's line is never found here.
                $existing = $order->items()->whereKey($item->id)->first();

                if ($existing === null) {
                    throw PurchaseOrderItemDoesNotBelongToOrder::make($item->id, (int) $order->getKey());
                }

                $existing->fill(['quantity_ordered' => $item->quantityOrdered, 'unit_cost' => $item->unitCost]);
                $existing->product_variant_id = $item->productVariantId;
                $existing->forceFill(['total_cost' => $totalCost, 'unit' => $variant->product->pricing_unit]);
                $existing->save();
                $keptIds[] = $existing->getKey();

                continue;
            }

            $created = new PurchaseOrderItem(['quantity_ordered' => $item->quantityOrdered, 'unit_cost' => $item->unitCost]);
            $created->purchase_order_id = $order->id;
            $created->product_variant_id = $item->productVariantId;
            $created->quantity_received = '0.000';
            $created->forceFill(['total_cost' => $totalCost, 'unit' => $variant->product->pricing_unit]);
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
