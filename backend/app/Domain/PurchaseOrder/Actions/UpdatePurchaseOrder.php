<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Actions\SyncCustomerShops;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderAdditionalCostData;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderItemData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderAdditionalCostDoesNotBelongToOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderItemDoesNotBelongToOrder;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNotEditable;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Replaces a purchase order's fields, lines and additional costs with what was sent — only while
 * it is still {@see PurchaseOrderStatus::New}.
 *
 * Lines and additional costs are each synced the same way {@see SyncCustomerShops} syncs a
 * customer's shops: an entry carrying an `id` updates that row, one without creates a new row,
 * and any existing row missing from the set is removed. Safe here specifically because nothing
 * may have shipped against a `new` order yet — there is no `quantity_received` on any line to
 * lose by deleting it.
 *
 * Every line's `unit` is recomputed the same way {@see CreatePurchaseOrder} computes it — never
 * trusted from the request. Every cost-shaped figure a line carries is then rebuilt from scratch
 * by {@see AllocatePurchaseOrderAdditionalCosts}, and `total_amount`/`total_additional_cost`
 * re-derived via {@see RecalculatePurchaseOrderTotal}.
 *
 * @throws PurchaseOrderNotEditable
 * @throws PurchaseOrderItemDoesNotBelongToOrder
 * @throws PurchaseOrderAdditionalCostDoesNotBelongToOrder
 */
final class UpdatePurchaseOrder
{
    public function __construct(
        private readonly AllocatePurchaseOrderAdditionalCosts $allocateAdditionalCosts,
        private readonly RecalculatePurchaseOrderTotal $recalculateTotal,
    ) {}

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
            $this->syncAdditionalCosts($order, $data->additionalCosts);
            ($this->allocateAdditionalCosts)($order);
            ($this->recalculateTotal)($order);

            return $order->load(['vendor', 'warehouse', 'items.productVariant.product', 'additionalCosts']);
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

            if ($item->id !== null) {
                // Scoped through the relation, so another order's line is never found here.
                $existing = $order->items()->whereKey($item->id)->first();

                if ($existing === null) {
                    throw PurchaseOrderItemDoesNotBelongToOrder::make($item->id, (int) $order->getKey());
                }

                $existing->fill(['quantity_ordered' => $item->quantityOrdered, 'base_total_cost' => $item->baseTotalCost]);
                $existing->product_variant_id = $item->productVariantId;
                $existing->forceFill(['unit' => $variant->product->pricing_unit]);
                $existing->save();
                $keptIds[] = $existing->getKey();

                continue;
            }

            $created = new PurchaseOrderItem(['quantity_ordered' => $item->quantityOrdered, 'base_total_cost' => $item->baseTotalCost]);
            $created->purchase_order_id = $order->id;
            $created->product_variant_id = $item->productVariantId;
            $created->quantity_received = '0.000';
            $created->forceFill(['unit' => $variant->product->pricing_unit]);
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

    /**
     * @param  list<PurchaseOrderAdditionalCostData>  $additionalCosts
     *
     * @throws PurchaseOrderAdditionalCostDoesNotBelongToOrder
     */
    private function syncAdditionalCosts(PurchaseOrder $order, array $additionalCosts): void
    {
        $keptIds = [];

        foreach ($additionalCosts as $cost) {
            if ($cost->id !== null) {
                // Scoped through the relation, so another order's cost is never found here.
                $existing = $order->additionalCosts()->whereKey($cost->id)->first();

                if ($existing === null) {
                    throw PurchaseOrderAdditionalCostDoesNotBelongToOrder::make($cost->id, (int) $order->getKey());
                }

                $existing->update(['name' => $cost->name, 'amount' => $cost->amount]);
                $keptIds[] = $existing->getKey();

                continue;
            }

            $keptIds[] = $order->additionalCosts()->create(['name' => $cost->name, 'amount' => $cost->amount])->getKey();
        }

        // One row at a time rather than a mass delete on the relation — see syncItems() above
        // for why: a mass delete fires no model events, leaving the audit trail with nothing to
        // say a cost ever existed.
        $order->additionalCosts()
            ->whereKeyNot($keptIds)
            ->each(fn (PurchaseOrderAdditionalCost $cost) => $cost->delete());
    }
}
