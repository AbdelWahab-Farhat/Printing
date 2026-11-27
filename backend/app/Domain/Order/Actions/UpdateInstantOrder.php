<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\Models\Product;
use App\Domain\Delivery\Support\BranchAccess;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\DiscountRequiresPermission;
use App\Domain\Order\Exceptions\InstantOrderRefused;
use App\Domain\Order\Exceptions\OrderNeedsAtLeastOneItem;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\InstantOrderStock;
use App\Domain\Order\Support\InstantSaleEligibility;
use App\Domain\Order\Support\Money;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Edits an instant order while it is still «جديدة»: its lines, quantities, discount and notes
 * (INSTANT-ORDERS-PLAN.md §9, owner's decision 2026-11-26).
 *
 * **The stock moves through the existing line edit.** {@see SyncOrderItems} already returns a
 * changed or removed line's draw and takes the new figure, in one transaction, re-posting the
 * investors behind it — the machinery «تعديل البنود بعد السحب» uses. This action only answers the
 * questions that are the instant road's own: its permission and branch, its eligible products,
 * and its shortfall sentence (counting the stock the order already holds as available to it).
 *
 * The branch and the customer never change here: a sale moved to another branch is cancelled and
 * taken again there (owner's decision).
 */
final class UpdateInstantOrder
{
    public function __construct(
        private readonly SyncOrderItems $syncItems,
        private readonly RecalculateOrderTotals $recalculate,
        private readonly ApplyManufacturingRates $applyManufacturingRates,
        private readonly RecalculateOrderCogs $recalculateCogs,
        private readonly BranchAccess $branches,
        private readonly InstantOrderStock $stock,
        private readonly InstantSaleEligibility $eligibility,
    ) {}

    /**
     * @param  list<OrderItemData>  $items
     *
     * @throws InstantOrderRefused
     */
    public function __invoke(Order $order, array $items, string $discount, ?string $notes, User $actor): Order
    {
        if (! $order->isInstant()) {
            throw InstantOrderRefused::notInstant();
        }

        if ($items === []) {
            throw OrderNeedsAtLeastOneItem::make();
        }

        if (! $this->branches->mayActFor($actor, $order->city_id === null ? null : (int) $order->city_id)) {
            throw InstantOrderRefused::notYourBranch((string) $order->city_name);
        }

        return DB::transaction(function () use ($order, $items, $discount, $notes, $actor): Order {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status !== OrderStatus::New) {
                throw InstantOrderRefused::notEditable();
            }

            if (bccomp($discount, (string) $locked->discount, Money::SCALE) !== 0
                && ! $actor->can(PermissionName::DiscountOrders->value)) {
                throw DiscountRequiresPermission::make();
            }

            $existing = $locked->items()->get()->keyBy('id');
            $products = $this->products($items, $existing);

            $this->guardNewLines($items, $products);

            $this->stock->assertAvailable(
                $this->withKeptProducts($items, $existing),
                $products,
                (int) $locked->fulfillment_warehouse_id,
                $this->drawnByOrder($locked),
            );

            $before = $existing->keys()->all();

            ($this->syncItems)($locked, $items, $actor, stockMoveAuthorised: true);

            $locked->forceFill(['discount' => $discount, 'notes' => $notes])->save();

            ($this->recalculate)($locked->load('items'));

            // Only the new lines are costed: the kept ones were costed when the order was taken,
            // and costing them twice would double their labour and overhead.
            $added = $locked->items->reject(fn (OrderItem $item) => in_array($item->getKey(), $before, true));

            if ($added->isNotEmpty()) {
                ($this->applyManufacturingRates)((clone $locked)->setRelation('items', $added->values()), (int) $actor->getKey());
            }

            ($this->recalculateCogs)($locked);

            return $locked->refresh();
        });
    }

    /**
     * Every product the edit names — the kept lines' own included, read off the line.
     *
     * @param  list<OrderItemData>  $items
     * @param  Collection<int, OrderItem>  $existing
     * @return \Illuminate\Database\Eloquent\Collection<int, Product>
     */
    private function products(array $items, $existing)
    {
        $ids = array_map(
            fn (OrderItemData $item): int => $item->id !== null && $existing->has($item->id)
                ? (int) $existing[$item->id]->product_id
                : $item->productId,
            $items,
        );

        return Product::query()
            ->with(InstantSaleEligibility::RELATIONS)
            ->whereKey(array_values(array_unique($ids)))
            ->get()
            ->keyBy('id');
    }

    /**
     * A new line must be sellable now. A kept line was sellable when the order was taken, and
     * stays on it even if the product has since been switched off.
     *
     * @param  list<OrderItemData>  $items
     * @param  \Illuminate\Database\Eloquent\Collection<int, Product>  $products
     */
    private function guardNewLines(array $items, $products): void
    {
        foreach ($items as $index => $item) {
            if ($item->id !== null) {
                continue;
            }

            $product = $products->get($item->productId);

            if ($product === null) {
                throw InstantOrderRefused::productNotEligible($index, 'المنتج', 'غير موجود');
            }

            $refusal = $this->eligibility->refusalFor($product, $product->variants->firstWhere('id', $item->productVariantId));

            if ($refusal !== null) {
                throw InstantOrderRefused::productNotEligible($index, (string) $product->name, $refusal);
            }
        }
    }

    /**
     * The lines as the shelf sees them: a kept line is always its own product and size.
     *
     * @param  list<OrderItemData>  $items
     * @param  Collection<int, OrderItem>  $existing
     * @return list<OrderItemData>
     */
    private function withKeptProducts(array $items, $existing): array
    {
        return array_map(function (OrderItemData $item) use ($existing): OrderItemData {
            if ($item->id === null || ! $existing->has($item->id)) {
                return $item;
            }

            $line = $existing[$item->id];

            return new OrderItemData(
                productId: (int) $line->product_id,
                productVariantId: (int) $line->product_variant_id,
                quantity: $item->quantity,
                notes: $item->notes,
                sortOrder: $item->sortOrder,
                id: $item->id,
            );
        }, $items);
    }

    /**
     * What this order holds on its warehouse's shelves right now, per stock item — available to
     * the edit, because the edit gives it back before drawing again.
     *
     * @return array<int, string>
     */
    private function drawnByOrder(Order $order): array
    {
        $drawn = [];

        foreach ($order->linesWithStockStillDrawn()->load('variant') as $line) {
            $stockItemId = (int) $line->variant?->stock_item_id;

            if ($stockItemId === 0) {
                continue;
            }

            $drawn[$stockItemId] = bcadd($drawn[$stockItemId] ?? '0', $line->producedQuantity(), 3);
        }

        return $drawn;
    }
}
