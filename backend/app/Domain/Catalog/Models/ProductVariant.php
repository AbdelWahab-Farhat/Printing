<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use Database\Factories\ProductVariantFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * One buyable form of a product — a size such as 25*35, or the single سادة variant that a
 * per-kilo product carries.
 */
#[UseFactory(ProductVariantFactory::class)]
#[Fillable(['label', 'width_cm', 'height_cm', 'is_active', 'sort_order'])]
class ProductVariant extends Model
{
    /** @use HasFactory<ProductVariantFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'width_cm' => 'integer',
            'height_cm' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<Product, $this>
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * @return HasMany<ProductPriceTier, $this>
     */
    public function priceTiers(): HasMany
    {
        return $this->hasMany(ProductPriceTier::class)->orderBy('min_quantity');
    }

    /**
     * The price that applies to `$quantity`: the highest tier whose floor it reaches.
     *
     * Resolved in PHP over the already-loaded relation rather than with a query, so quoting a
     * whole catalogue page does not fire one statement per row. Callers must eager-load
     * `priceTiers` — with strict mode on, forgetting to throws rather than silently degrading.
     */
    public function priceTierFor(string $quantity): ?ProductPriceTier
    {
        return $this->priceTiers
            ->filter(fn (ProductPriceTier $tier) => bccomp($quantity, (string) $tier->min_quantity, 3) >= 0)
            ->sortByDesc(fn (ProductPriceTier $tier) => (float) $tier->min_quantity)
            ->first();
    }
}
