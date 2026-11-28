<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use Illuminate\Database\Eloquent\Collection;

/**
 * Which product sizes an instant order may sell (INSTANT-ORDERS-PLAN.md §3).
 *
 * All of these, and the screen and the server ask the same list:
 *
 * 1. The product and the size are active.
 * 2. «متاح للبيع الفوري» is on — the owner's switch, product by product.
 * 3. It is plain («سادة»): nothing is printed or made for a counter sale.
 * 4. It has listed prices: the unit price is fixed from the product, never typed (owner's
 *    decision, 2026-11-26).
 * 5. The size draws on a shelf, and that shelf counts in the unit the product is sold in — the
 *    stock leaves when the order is created, so the quantity must already be the shelf's
 *    (owner's decision: same-unit products only, for now).
 */
final class InstantSaleEligibility
{
    /** Relations every check below reads. */
    public const RELATIONS = ['productCategory.parent', 'variants.stockItem', 'variants.priceTiers'];

    /**
     * Why this size cannot be sold instantly, as the end of a sentence that starts with the
     * product's name — or null when it can.
     */
    public function refusalFor(Product $product, ?ProductVariant $variant): ?string
    {
        if (! $product->is_active || ! $product->is_instant_sale) {
            return 'غير متاح للبيع الفوري';
        }

        if ($product->productCategory?->productionMode() !== ProductionMode::None) {
            return 'ليس منتجاً سادة — البيع الفوري للمنتجات السادة فقط';
        }

        if ($product->pricing_mode !== PricingMode::Tiered) {
            return 'بلا سعر محدد — البيع الفوري بسعر المنتج فقط';
        }

        if ($variant === null || ! $variant->is_active) {
            return 'المقاس غير متاح';
        }

        if ($variant->stockItem === null) {
            return 'المقاس غير مربوط بمادة في المخزن';
        }

        if ($variant->stockItem->unit !== $product->pricing_unit) {
            return 'يُباع بوحدة غير وحدة المخزن — غير متاح للبيع الفوري حالياً';
        }

        return null;
    }

    /**
     * Every product with at least one size that may be sold instantly, each carrying only those
     * sizes — what the instant product picker lists.
     *
     * @return Collection<int, Product>
     */
    public function eligibleProducts(): Collection
    {
        $products = Product::query()
            ->where('is_active', true)
            ->where('is_instant_sale', true)
            ->with(self::RELATIONS)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return $products
            ->map(function (Product $product): Product {
                $product->setRelation('variants', $product->variants->filter(
                    fn (ProductVariant $variant) => $this->refusalFor($product, $variant) === null,
                )->values());

                return $product;
            })
            ->filter(fn (Product $product) => $product->variants->isNotEmpty())
            ->values();
    }
}
