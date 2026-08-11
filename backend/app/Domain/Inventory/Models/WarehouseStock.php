<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Actions\ApplyStockChange;
use Database\Factories\WarehouseStockFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * How much of one size is in one warehouse, right now.
 *
 * **`quantity` is not fillable, and that is the central rule of this context.** Every change to
 * it comes from {@see ApplyStockChange}, under a row lock, inside the transaction that also
 * writes the {@see StockMovement} explaining it. Making it mass-assignable would mean a payload
 * could move stock without leaving a reason behind — which is the one thing this whole design
 * exists to prevent.
 *
 * `low_stock_threshold` *is* fillable, because it is the opposite kind of thing: a preference
 * someone sets, not a fact the business observed.
 *
 * `unit` is not fillable: a snapshot of `productVariant->product->pricing_unit`, written once by
 * {@see ApplyStockChange::increase()} the first time this (warehouse, variant) pair gets a
 * balance, and never touched again — the same treatment `purchase_order_items.unit` gets.
 */
#[UseFactory(WarehouseStockFactory::class)]
#[Fillable(['low_stock_threshold'])]
class WarehouseStock extends Model
{
    /** @use HasFactory<WarehouseStockFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            // Strings, never floats. These are counted, compared and summed against a ledger,
            // and binary drift in a shelf count is a discrepancy nobody can ever explain.
            'quantity' => 'decimal:3',
            'low_stock_threshold' => 'decimal:3',
            'unit' => PricingUnit::class,
        ];
    }

    /**
     * @return BelongsTo<Warehouse, $this>
     */
    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    /**
     * The size this balance is of.
     *
     * **Read-only, and the only cross-context relation in the codebase.** Inventory may depend
     * on Catalog (never the other way round), but the rule in RULES.md §3 is that decisions
     * cross a context boundary through its Service — so this relation exists purely to
     * eager-load a label for rendering. Anything Inventory needs to *decide* about a variant —
     * does it exist, may it be moved in fractions — is asked of `CatalogService`, never of this
     * relation.
     *
     * @return BelongsTo<ProductVariant, $this>
     */
    public function productVariant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }

    /**
     * Whether this line has fallen to or below the level someone asked to be warned about.
     *
     * A null threshold is not "zero" — it means nobody asked, so nothing is low.
     */
    public function isLowStock(): bool
    {
        if ($this->low_stock_threshold === null) {
            return false;
        }

        return bccomp((string) $this->quantity, (string) $this->low_stock_threshold, 3) <= 0;
    }
}
