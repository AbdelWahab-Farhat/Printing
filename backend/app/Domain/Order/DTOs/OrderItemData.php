<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Actions\DeductOrderStock;

/**
 * One requested line, before it has been priced.
 *
 * `unitPrice` is the exception that keeps quote-on-request products orderable. The catalogue
 * carries products whose price «حسب الطلب» — the reinforced 3D paper bags — and refusing to
 * price them is exactly right for a quote endpoint but would make a whole category impossible
 * to sell. So a clerk may name a price for those, and **only** those: for a product with listed
 * prices this field is ignored and the catalogue wins, which is what stops a posted number
 * undercutting an agreed rate.
 */
final readonly class OrderItemData
{
    public function __construct(
        public int $productId,
        public int $productVariantId,
        public string $quantity,
        /** Honoured only when the product is priced on request. */
        public ?string $unitPrice = null,
        public ?string $notes = null,
        public int $sortOrder = 0,
        /**
         * The total this line takes out of the warehouse, in the warehouse's own unit, typed by
         * the employee only when the sales unit and the warehouse unit genuinely differ — read
         * off a scale for a batch, not derived from `$quantity`. Null is the common case — see
         * {@see DeductOrderStock}.
         */
        public ?string $warehouseQuantity = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated, int $index = 0): self
    {
        $price = $validated['unit_price'] ?? null;
        $warehouseQuantity = $validated['warehouse_quantity'] ?? null;

        return new self(
            productId: (int) $validated['product_id'],
            productVariantId: (int) $validated['product_variant_id'],
            quantity: (string) $validated['quantity'],
            unitPrice: $price !== null && $price !== '' ? (string) $price : null,
            notes: isset($validated['notes']) && $validated['notes'] !== ''
                ? (string) $validated['notes']
                : null,
            sortOrder: (int) ($validated['sort_order'] ?? $index),
            warehouseQuantity: $warehouseQuantity !== null && $warehouseQuantity !== ''
                ? (string) $warehouseQuantity
                : null,
        );
    }
}
