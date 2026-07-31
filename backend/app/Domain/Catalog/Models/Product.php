<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductCategory;
use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A bag type in the catalogue.
 *
 * As with customers, soft deleting does not open a destroy route — a product is deactivated so
 * that past orders keep pointing at it. It is the guarantee underneath: nothing can remove the
 * row an order refers to, whatever calls `delete()`.
 */
#[UseFactory(ProductFactory::class)]
#[Fillable([
    'slug', 'name', 'description', 'features', 'category',
    'pricing_unit', 'pricing_mode', 'min_order_quantity', 'is_active', 'sort_order',
])]
class Product extends Model implements HasAuditTrail
{
    /** @use HasFactory<ProductFactory> */
    use Auditable, HasFactory, SoftDeletes;

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

    /**
     * Primary first, then by explicit order — the sequence a gallery should render.
     *
     * @return HasMany<ProductImage, $this>
     */
    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class)
            ->orderByDesc('is_primary')
            ->orderBy('sort_order')
            ->orderBy('id');
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

    /**
     * A product's history is the whole aggregate's: the sizes, the prices and the photos too.
     *
     * "Who put the price of 25*35 up?" is the single most likely question this endpoint will be
     * asked, and the answer lives on `product_price_tiers`. Making the client fetch four
     * histories and merge them would push the shape of our tables into its code.
     *
     * Two queries, not four: the tier ids come from the variant ids already in hand.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        $variantIds = $this->variants()->withTrashed()->pluck('id')->all();

        return [
            $this->getMorphClass() => [$this->getKey()],
            (new ProductVariant)->getMorphClass() => $variantIds,
            (new ProductPriceTier)->getMorphClass() => ProductPriceTier::query()
                ->withTrashed()
                ->whereIn('product_variant_id', $variantIds)
                ->pluck('id')
                ->all(),
            (new ProductImage)->getMorphClass() => $this->images()->withTrashed()->pluck('id')->all(),
        ];
    }
}
