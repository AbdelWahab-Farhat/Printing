<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Models\Product;
use App\Domain\Order\Actions\ApplyManufacturingRates;
use App\Domain\Order\Enums\ManufacturingCostType;
use Database\Factories\ManufacturingCostRateFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * What a unit of production standard-costs at for one product, or for every product that has no
 * rate of its own.
 *
 * Reference data the business curates, the same shape `BusinessField` already is — a short list
 * edited from a screen, applied automatically rather than typed per job. See
 * {@see ApplyManufacturingRates}, the only reader.
 *
 * `product_id` null is the fallback: {@see ApplyManufacturingRates} tries the product-specific
 * rate first and falls back to the row with no product, never inventing a third answer.
 */
#[UseFactory(ManufacturingCostRateFactory::class)]
#[Fillable(['product_id', 'cost_type', 'rate_per_unit', 'is_active', 'notes'])]
class ManufacturingCostRate extends Model implements HasAuditTrail
{
    /** @use HasFactory<ManufacturingCostRateFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'cost_type' => ManufacturingCostType::class,
            'rate_per_unit' => 'decimal:3',
            'is_active' => 'boolean',
        ];
    }

    /**
     * The product this rate is specific to. Null means it is the fallback for its cost type.
     *
     * @return BelongsTo<Product, $this>
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
