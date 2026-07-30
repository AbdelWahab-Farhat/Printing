<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\DTOs\ProductData;
use App\Domain\Catalog\Models\Product;
use Illuminate\Support\Facades\DB;

final class CreateProduct
{
    public function __construct(private readonly SyncProductVariants $syncVariants) {}

    public function __invoke(ProductData $data): Product
    {
        return DB::transaction(function () use ($data): Product {
            $product = Product::create([
                'slug' => $data->slug,
                'name' => $data->name,
                'description' => $data->description,
                'features' => $data->features,
                'category' => $data->category,
                'pricing_unit' => $data->pricingUnit,
                'pricing_mode' => $data->pricingMode,
                'min_order_quantity' => $data->minOrderQuantity,
                'is_active' => $data->isActive ?? true,
                'sort_order' => $data->sortOrder,
            ]);

            ($this->syncVariants)($product, $data->variants ?? []);

            return $product->load('variants.priceTiers');
        });
    }
}
