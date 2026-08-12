<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Order\Actions\DeductOrderStock;
use App\Domain\Order\Support\Money;
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
     * What this line is actually charged for: everything ordered, less whatever is missing.
     *
     * **The one place the shortage becomes money.** `quantity` is what the customer asked for
     * and never moves — an order that overwrote it would lose the question a shortage is the
     * answer to — so the number the invoice is built on is derived here instead, and every
     * caller that prices a line goes through it. That is also what makes the money reversible
     * without a reversing entry: put `shortage_quantity` back and this returns the number it
     * was, because it was never a written balance.
     *
     * Floored at zero. The bound belongs to validation, but a negative line total is bad enough
     * that the arithmetic refuses it too.
     */
    public function billableQuantity(): string
    {
        $billable = bcsub((string) $this->quantity, (string) ($this->shortage_quantity ?? '0'), 3);

        return bccomp($billable, '0', 3) < 0 ? '0.000' : $billable;
    }

    /**
     * What the line costs at the price it was agreed at.
     *
     * **`unit_price` is never re-quoted for the smaller quantity.** A run of 300 earned the
     * 300-tier rate; delivering 200 of it is our failure, and looking the price up again would
     * charge the customer *more* per bag because we came up short.
     */
    public function deriveLineTotal(): string
    {
        return Money::round(bcmul((string) $this->unit_price, $this->billableQuantity(), 6));
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
}
