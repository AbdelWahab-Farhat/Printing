<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductCategory;
use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A bag type in the catalogue.
 */
#[UseFactory(ProductFactory::class)]
#[Fillable([
    'slug', 'name', 'description', 'features', 'category',
    'pricing_unit', 'pricing_mode', 'min_order_quantity', 'is_active', 'sort_order',
])]
class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory;

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return [
            'features' => 'array',
            'category' => ProductCategory::class,
            'pricing_unit' => PricingUnit::class,
            'pricing_mode' => PricingMode::class,
            // String, not float: money and the quantities it is multiplied by must stay exact.
            'min_order_quantity' => 'decimal:3',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<ProductVariant, $this>
     */
    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class)->orderBy('sort_order')->orderBy('id');
    }

    public function hasListedPrices(): bool
    {
        return $this->pricing_mode->hasListedPrices();
    }

    /**
     * Compared as strings via bccomp so a quantity like 0.1 is not mangled by binary floats.
     */
    public function meetsMinimumOrder(string $quantity): bool
    {
        return bccomp($quantity, (string) $this->min_order_quantity, 3) >= 0;
    }
}
