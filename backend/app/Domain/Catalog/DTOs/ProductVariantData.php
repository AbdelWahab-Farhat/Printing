<?php

declare(strict_types=1);

namespace App\Domain\Catalog\DTOs;

final readonly class ProductVariantData
{
    /**
     * @param  list<PriceTierData>  $priceTiers  Empty for a quote-only product.
     */
    public function __construct(
        public string $label,
        public ?int $widthCm = null,
        public ?int $heightCm = null,
        public bool $isActive = true,
        public int $sortOrder = 0,
        public array $priceTiers = [],
        /** Present when updating an existing variant. */
        public ?int $id = null,
    ) {}

    /**
     * @param  array<string, mixed>  $variant
     */
    public static function fromArray(array $variant): self
    {
        return new self(
            label: (string) $variant['label'],
            widthCm: isset($variant['width_cm']) ? (int) $variant['width_cm'] : null,
            heightCm: isset($variant['height_cm']) ? (int) $variant['height_cm'] : null,
            isActive: (bool) ($variant['is_active'] ?? true),
            sortOrder: (int) ($variant['sort_order'] ?? 0),
            priceTiers: array_map(
                PriceTierData::fromArray(...),
                is_array($variant['price_tiers'] ?? null) ? $variant['price_tiers'] : [],
            ),
            id: isset($variant['id']) ? (int) $variant['id'] : null,
        );
    }
}
