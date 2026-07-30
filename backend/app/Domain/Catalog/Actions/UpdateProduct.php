<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\DTOs\ProductData;
use App\Domain\Catalog\Models\Product;
use Illuminate\Support\Facades\DB;

final class UpdateProduct
{
    public function __construct(private readonly SyncProductVariants $syncVariants) {}

    public function __invoke(Product $product, ProductData $data): Product
    {
        return DB::transaction(function () use ($product, $data): Product {
            $attributes = [
                'slug' => $data->slug,
                'name' => $data->name,
                'description' => $data->description,
                'features' => $data->features,
                'category' => $data->category,
                'pricing_unit' => $data->pricingUnit,
                'pricing_mode' => $data->pricingMode,
                'min_order_quantity' => $data->minOrderQuantity,
                'sort_order' => $data->sortOrder,
            ];

            // Only touched when the caller actually sent it, so an update that omits the field
            // cannot reactivate a product that was deliberately taken off the catalogue.
            if ($data->isActive !== null) {
                $attributes['is_active'] = $data->isActive;
            }

            $product->update($attributes);

            // null means the caller did not mention variants, so the price list is left alone.
            // An empty array is an explicit instruction to clear it.
            if ($data->variants !== null) {
                ($this->syncVariants)($product, $data->variants);
            }

            return $product->load(['variants.priceTiers', 'images']);
        });
    }
}
