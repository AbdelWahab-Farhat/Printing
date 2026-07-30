<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\DTOs\ProductVariantData;
use App\Domain\Catalog\Exceptions\VariantDoesNotBelongToProduct;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;

/**
 * Makes a product's variants — and each variant's price tiers — match the given set exactly.
 *
 * Variants carrying an `id` are updated in place, ones without are created, and any left out is
 * removed. A variant's tiers are always replaced wholesale rather than diffed: a price list is
 * read as a unit, and rewriting it is both simpler and safer than trying to match rows whose
 * only identity is a threshold that may itself be the thing being edited.
 */
final class SyncProductVariants
{
    /**
     * @param  list<ProductVariantData>  $variants
     */
    public function __invoke(Product $product, array $variants): void
    {
        $keptIds = [];

        foreach ($variants as $variantData) {
            $variant = $this->upsertVariant($product, $variantData);
            $keptIds[] = $variant->getKey();

            // Replace the whole price list for this variant.
            $variant->priceTiers()->delete();

            foreach ($variantData->priceTiers as $tier) {
                $variant->priceTiers()->create([
                    'min_quantity' => $tier->minQuantity,
                    'unit_price' => $tier->unitPrice,
                ]);
            }
        }

        // Tiers of removed variants go with them via the cascade.
        $product->variants()->whereKeyNot($keptIds)->delete();
    }

    private function upsertVariant(Product $product, ProductVariantData $data): ProductVariant
    {
        $attributes = [
            'label' => $data->label,
            'width_cm' => $data->widthCm,
            'height_cm' => $data->heightCm,
            'is_active' => $data->isActive,
            'sort_order' => $data->sortOrder,
        ];

        if ($data->id === null) {
            return $product->variants()->create($attributes);
        }

        // Scoped through the relation, so another product's variant is never found here.
        $existing = $product->variants()->whereKey($data->id)->first();

        // Refuse rather than quietly creating a duplicate — a caller that named a specific
        // variant and silently got a different one is a bug worth surfacing.
        if ($existing === null) {
            throw VariantDoesNotBelongToProduct::make($data->id, (int) $product->getKey());
        }

        $existing->update($attributes);

        return $existing;
    }
}
