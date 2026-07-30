<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use Database\Factories\ProductPriceTierFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * "From this quantity upward, one unit costs this much."
 */
#[UseFactory(ProductPriceTierFactory::class)]
#[Fillable(['min_quantity', 'unit_price'])]
class ProductPriceTier extends Model
{
    /** @use HasFactory<ProductPriceTierFactory> */
    use HasFactory;

    /**
     * decimal, never float — these values are multiplied by quantities and compared.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'min_quantity' => 'decimal:3',
            'unit_price' => 'decimal:3',
        ];
    }

    /**
     * @return BelongsTo<ProductVariant, $this>
     */
    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id');
    }
}
