<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Queries;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductCategory;

final readonly class ProductFilters
{
    public function __construct(
        /** Matches the name or the slug. */
        public ?string $search = null,
        public ?ProductCategory $category = null,
        public ?PricingUnit $pricingUnit = null,
        public ?PricingMode $pricingMode = null,
        /** null = both active and inactive. */
        public ?bool $isActive = null,
    ) {}

    /**
     * @param  array<string, mixed>  $query
     */
    public static function fromArray(array $query): self
    {
        $search = isset($query['search']) ? trim((string) $query['search']) : '';

        return new self(
            search: $search !== '' ? $search : null,
            category: ProductCategory::tryFrom((string) ($query['category'] ?? '')),
            pricingUnit: PricingUnit::tryFrom((string) ($query['pricing_unit'] ?? '')),
            pricingMode: PricingMode::tryFrom((string) ($query['pricing_mode'] ?? '')),
            isActive: array_key_exists('is_active', $query) && $query['is_active'] !== null
                ? filter_var($query['is_active'], FILTER_VALIDATE_BOOLEAN)
                : null,
        );
    }
}
