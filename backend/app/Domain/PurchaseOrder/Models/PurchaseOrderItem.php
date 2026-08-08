<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Models\ProductVariant;
use Database\Factories\PurchaseOrderItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One line inside a {@see PurchaseOrder} — a size, how much was ordered, and how much of it has
 * arrived so far.
 *
 * No `/logs` route of its own — like `StockArrivalItem`, its history is read through the
 * document that owns it, via `PurchaseOrder::auditTrailSubjects()`.
 *
 * `quantity_received` is not fillable and is never touched by a request directly: it is
 * incremented only by {@see ReceivePurchaseOrder}, once a {@see StockArrival} has actually
 * posted the stock it describes — the same rule that keeps `StockArrivalItem::stock_movement_id`
 * out of the fillable list.
 */
#[UseFactory(PurchaseOrderItemFactory::class)]
#[Fillable(['quantity_ordered'])]
class PurchaseOrderItem extends Model
{
    /** @use HasFactory<PurchaseOrderItemFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            // Strings, never floats — the same reasoning `StockArrivalItem::quantity` carries:
            // these numbers are compared and summed against each other, and binary drift here is
            // a discrepancy nobody could ever explain.
            'quantity_ordered' => 'decimal:3',
            'quantity_received' => 'decimal:3',
        ];
    }

    /**
     * @return BelongsTo<PurchaseOrder, $this>
     */
    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class);
    }

    /**
     * The size on order. Read-only, for rendering — see the note on
     * {@see PurchaseOrder::warehouse()} for why this context holds the relation but never
     * decides anything from it.
     *
     * @return BelongsTo<ProductVariant, $this>
     */
    public function productVariant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }
}
