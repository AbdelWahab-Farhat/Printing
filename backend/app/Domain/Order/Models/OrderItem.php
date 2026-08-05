<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
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
 * Audited; its entries are read through the order that owns it.
 */
#[UseFactory(OrderItemFactory::class)]
#[Fillable([
    'product_id', 'product_variant_id', 'product_name', 'variant_label', 'pricing_unit',
    'quantity', 'notes', 'sort_order',
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
}
