<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Actions\SetStockItemUnit;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Order\Actions\DeductOrderStock;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;
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
 * **It is asked for on the way into «جاهزة», not when the order is taken.** A clerk agreeing
 * «٥٠٠ قطعة» with a customer on the phone has not been near a scale, and the parcel does not
 * exist yet; the foreman who shelves it has both. See {@see TransitionFields}.
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
            // The copy of what this size cost us on the day — see the migration that added it.
            // Three places, like the price it sits beside, so the two round the same way.
            'unit_cost' => 'decimal:3',
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
     * The unit this line's stock is counted in on the shelf.
     *
     * **The shelf's, not the line's, and not the product's any more.** This used to read
     * `products.stock_unit`; that column is gone, and the unit now belongs to the
     * {@see StockItem} the size draws on — see
     * {@see SetStockItemUnit}. The move is the whole point of
     * stock items: «كيس شحن سادة» and «كيس شحن مطبوع» at one size are one pile, and while each
     * product answered this question separately the two could insist that one heap was counted
     * two different ways.
     *
     * `pricing_unit` is untouched by any of it — what the customer was billed in — and the two
     * still need not agree, which is exactly what {@see isStockedInAnotherUnit()} is about.
     *
     * Falls back to the selling unit when the variant, its shelf, or the link between them is
     * missing — a quote-only size is never stocked, and an invoice keeps its own copy of
     * everything it needs. Guessing that the units *differ* would be the worse of the two
     * mistakes: it would demand a measurement for a line that needs none.
     */
    public function stockUnit(): PricingUnit
    {
        return $this->variant?->stockItem?->unit ?? $this->pricing_unit;
    }

    /**
     * Whether this line leaves the shelf in a unit other than the one it was sold in.
     *
     * **The whole reason {@see $warehouse_quantity} has to be asked for.** «٥٠٠ قطعة» sold off a
     * shelf counted in kilograms has no automatic answer: bags of one size differ in weight,
     * which is why that shelf is weighed rather than counted, and no factor the catalogue holds
     * converts the one into the other. A line whose units agree needs nothing typed — what was
     * sold is what leaves.
     */
    public function isStockedInAnotherUnit(): bool
    {
        return $this->stockUnit() !== $this->pricing_unit;
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

    /**
     * What one unit off the shelf cost in material — «كم تكلفتنا القطعة؟» answered.
     *
     * **Derived, never stored, and never a column.** {@see $material_cost} is a FIFO draw of the
     * cost layers this line actually consumed, so the rate behind it is that draw over what left
     * the warehouse — and a line that ate two layers at different prices has a weighted average
     * no single `stock_batches.unit_cost` row states. Storing it would be a second answer to a
     * question `material_cost` and {@see producedQuantity()} already answer together.
     *
     * **Per {@see producedQuantity()}, so the figure is in the *shelf's* unit** — see
     * {@see stockUnit()}. 300 bags weighing 12.5 kilograms together cost what those kilograms
     * cost; dividing by 300 would invent a per-bag material cost out of a scale reading, which is
     * the very conversion COST-TRACKING-UNIT-CONVERSION.md §4 refuses to make. Whoever draws this
     * must say the unit beside it.
     *
     * Three decimals, matching `unit_price` rather than the two-place money columns: the two
     * rates are read in one glance, and a rate rounded to piastres is 0.00 on a bag.
     *
     * Null when the line has not been costed — and null too when nothing left the shelf, which
     * is the only division there is no answer to.
     */
    public function unitMaterialCost(): ?string
    {
        if ($this->material_cost === null) {
            return null;
        }

        $produced = $this->producedQuantity();

        return bccomp($produced, '0', 3) <= 0
            ? null
            : bcdiv((string) $this->material_cost, $produced, 3);
    }
}
