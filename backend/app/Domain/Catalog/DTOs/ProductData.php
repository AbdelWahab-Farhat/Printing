<?php

declare(strict_types=1);

namespace App\Domain\Catalog\DTOs;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;

final readonly class ProductData
{
    /**
     * @param  list<string>|null  $features
     * @param  list<ProductVariantData>|null  $variants  null means "not supplied" — on update the
     *                                                   existing variants are left untouched.
     */
    public function __construct(
        /** null means "not supplied": the model derives one from the name and the code. */
        public ?string $slug,
        public string $name,
        /** The catalogue heading it sits under — «التصنيف». Required from every request. */
        public int $productCategoryId,
        public PricingUnit $pricingUnit,
        public PricingMode $pricingMode,
        public string $minOrderQuantity,
        public ?string $description = null,
        public ?array $features = null,
        /** null means "not supplied": on update the current value is kept. */
        public ?bool $isActive = null,
        public int $sortOrder = 0,
        public ?array $variants = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            slug: isset($validated['slug']) && $validated['slug'] !== ''
                ? (string) $validated['slug']
                : null,
            name: (string) $validated['name'],
            productCategoryId: (int) $validated['product_category_id'],
            pricingUnit: PricingUnit::from((string) $validated['pricing_unit']),
            pricingMode: PricingMode::from((string) $validated['pricing_mode']),
            minOrderQuantity: (string) ($validated['min_order_quantity'] ?? '1'),
            description: isset($validated['description']) && $validated['description'] !== ''
                ? (string) $validated['description']
                : null,
            features: is_array($validated['features'] ?? null) ? array_values($validated['features']) : null,
            isActive: array_key_exists('is_active', $validated) && $validated['is_active'] !== null
                ? (bool) $validated['is_active']
                : null,
            sortOrder: (int) ($validated['sort_order'] ?? 0),
            variants: array_key_exists('variants', $validated) && is_array($validated['variants'])
                ? array_map(ProductVariantData::fromArray(...), $validated['variants'])
                : null,
        );
    }
}
