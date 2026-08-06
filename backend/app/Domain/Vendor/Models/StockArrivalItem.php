<?php

declare(strict_types=1);

namespace App\Domain\Vendor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Vendor\Actions\RecordStockArrival;
use Database\Factories\StockArrivalItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One line inside a {@see StockArrival} — a size and how much of it arrived.
 *
 * No `/logs` route of its own — like `WarehouseStock`, its history is read through the document
 * that owns it, via `StockArrival::auditTrailSubjects()`.
 *
 * `stock_movement_id` is not fillable and not the thing that moves the balance: the movement it
 * points at already did that, under `InventoryService`'s own lock. It is written once, by
 * {@see RecordStockArrival}, as a forward pointer to the ledger row
 * this line produced.
 */
#[UseFactory(StockArrivalItemFactory::class)]
#[Fillable(['quantity'])]
class StockArrivalItem extends Model
{
    /** @use HasFactory<StockArrivalItemFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            // A string, never a float — the same reasoning `WarehouseStock::quantity` and
            // `StockMovement::quantity` carry: this number is compared and summed against a
            // ledger, and binary drift here is a discrepancy nobody could ever explain.
            'quantity' => 'decimal:3',
        ];
    }

    /**
     * @return BelongsTo<StockArrival, $this>
     */
    public function stockArrival(): BelongsTo
    {
        return $this->belongsTo(StockArrival::class);
    }

    /**
     * The size that arrived. Read-only, for rendering — see the note on
     * {@see StockArrival::warehouse()} for why this context holds the relation but never decides
     * anything from it.
     *
     * @return BelongsTo<ProductVariant, $this>
     */
    public function productVariant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }

    /**
     * The ledger row this line produced.
     *
     * @return BelongsTo<StockMovement, $this>
     */
    public function stockMovement(): BelongsTo
    {
        return $this->belongsTo(StockMovement::class);
    }
}
