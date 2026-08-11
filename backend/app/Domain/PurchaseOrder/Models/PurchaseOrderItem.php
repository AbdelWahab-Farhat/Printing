<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\PurchaseOrder\Actions\CreatePurchaseOrder;
use App\Domain\PurchaseOrder\Actions\UpdatePurchaseOrder;
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
 *
 * `unit_cost` is typed by whoever raised the order — there is no catalogue price for what *we*
 * pay a vendor. `total_cost` is not fillable: it is `unit_cost * quantity_ordered`, computed once
 * by {@see CreatePurchaseOrder} /
 * {@see UpdatePurchaseOrder}, the same relationship
 * `OrderItem::unit_price`/`line_total` already have.
 *
 * `unit` is not fillable either: a snapshot of `productVariant->product->pricing_unit`, taken when
 * the line is created and never re-derived — for rendering only, the same treatment
 * `PurchaseOrder::warehouse()` documents.
 */
#[UseFactory(PurchaseOrderItemFactory::class)]
#[Fillable(['quantity_ordered', 'unit_cost'])]
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
            'unit_cost' => 'decimal:3',
            'total_cost' => 'decimal:2',
            'unit' => PricingUnit::class,
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
