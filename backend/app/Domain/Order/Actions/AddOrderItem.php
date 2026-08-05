<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\CatalogService;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\Exceptions\ManualPriceRequired;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\Money;

/**
 * Prices one line and writes it.
 *
 * Pricing and writing are one action rather than two because the price must never travel as a
 * loose array between them: `unit_price` and `line_total` are deliberately not fillable, so a
 * caller handed a bare array would have to remember to force-fill exactly the two keys a
 * request must never supply. Both callers — taking an order and replacing its lines — go
 * through here, so there is one answer to "what does this line cost and how does it get saved".
 *
 * **Listed prices always win.** For a product with price tiers the number comes from
 * `CatalogService::quote()` and a `unit_price` in the request is ignored, so a posted number can
 * never undercut an agreed rate. Only a product the catalogue itself says is priced «حسب الطلب»
 * takes a price from the clerk — and then it is required, because there is nothing to fall back
 * on.
 */
final class AddOrderItem
{
    public function __construct(private readonly CatalogService $catalog) {}

    /**
     * @throws ManualPriceRequired
     */
    public function __invoke(Order $order, OrderItemData $data): OrderItem
    {
        $product = $this->catalog->findProduct($data->productId);

        /** @var ProductVariant $variant */
        $variant = $product->variants->firstWhere('id', $data->productVariantId)
            ?? $product->variants()->with('priceTiers')->findOrFail($data->productVariantId);

        $unitPrice = $product->hasListedPrices()
            ? $this->catalog->quote($product, $variant, $data->quantity)->unitPrice
            : $this->manual($product, $data);

        /** @var OrderItem $item */
        $item = $order->items()->make([
            'product_id' => (int) $product->getKey(),
            'product_variant_id' => (int) $variant->getKey(),
            // Copied, not joined: renaming a product must not rewrite a finished invoice.
            'product_name' => $product->name,
            'variant_label' => $variant->label,
            'pricing_unit' => $product->pricing_unit,
            'quantity' => $data->quantity,
            'notes' => $data->notes,
            'sort_order' => $data->sortOrder,
        ]);

        // Never fillable: these come from the catalogue, and a request that could post them
        // could name its own price.
        $item->forceFill([
            'unit_price' => $unitPrice,
            'line_total' => Money::round(bcmul($unitPrice, $data->quantity, 6)),
        ])->save();

        return $item;
    }

    /**
     * @throws ManualPriceRequired
     */
    private function manual(Product $product, OrderItemData $data): string
    {
        if ($data->unitPrice === null) {
            throw ManualPriceRequired::make($product->name);
        }

        return $data->unitPrice;
    }
}
