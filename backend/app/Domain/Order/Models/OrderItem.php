<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Order\Actions\DeductOrderStock;
use Database\Factories\OrderItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One line of an order, priced at what it cost on the day.
 *
 * The name, the label and the unit are copied rather than joined: renaming a product must not
 * rewrite an invoice issued last year. `unit_price` and `line_total` are not fillable — both
 * come from `CatalogService::quote()` by way of the action, never from a request.
 *
 * `warehouse_quantity` is the exception to "nothing here is typed by a clerk without the
 * catalogue's say-so": there is no catalogue rule that converts a sales unit into a warehouse
 * unit, so an employee reads it off a scale and types the total for the whole line directly —
 * not a per-piece factor multiplied out, because a batch is weighed together, not counted. Null
 * is the common case — see {@see DeductOrderStock}, which deducts `quantity` unchanged when
 * absent.
 *
 * Audited; its entries are read through the order that owns it.
 */
#[UseFactory(OrderItemFactory::class)]
#[Fillable([
    'product_id', 'product_variant_id', 'product_name', 'variant_label', 'pricing_unit',
    'quantity', 'notes', 'sort_order', 'warehouse_quantity',
])]
class OrderItem extends Model
{
    /** @use HasFactory<OrderItemFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'pricing_unit' => PricingUnit::class,
            // Strings all the way: a quantity is multiplied by a price, and that is precisely
            // where a float stops being the number the catalogue printed.
            'quantity' => 'decimal:3',
            // What is missing from this line, in this line's own unit. Null until somebody has
            // counted — «nothing recorded» is not «nothing missing».
            'shortage_quantity' => 'decimal:3',
            'unit_price' => 'decimal:3',
            'line_total' => 'decimal:2',
            // Null means "same unit as the warehouse" — see the class docblock.
            'warehouse_quantity' => 'decimal:3',
        ];
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<Product, $this>
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * @return BelongsTo<ProductVariant, $this>
     */
    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id');
    }

    /**
     * The ledger row this line's own stock deduction produced. Null until the line reaches
     * printing; read back by `ReverseOrderStockDeduction` to credit the exact cost layers it
     * drew from if the order is later cancelled.
     *
     * @return BelongsTo<StockMovement, $this>
     */
    public function fulfillmentStockMovement(): BelongsTo
    {
        return $this->belongsTo(StockMovement::class);
    }

    /**
     * What this line actually produced, physically — the same number {@see DeductOrderStock}
     * takes out of the warehouse.
     *
     * **The one basis every production-side cost is computed against.** Material cost is a FIFO
     * draw of exactly this quantity; manufacturing rates (see `ApplyManufacturingRates`) are
     * applied against it too — never against `quantity` directly when `warehouse_quantity` is
     * set, or a line's `cogs` would sum two costs computed on different physical amounts for the
     * same line.
     */
    public function producedQuantity(): string
    {
        return $this->warehouse_quantity === null
            ? (string) $this->quantity
            : (string) $this->warehouse_quantity;
    }
}
