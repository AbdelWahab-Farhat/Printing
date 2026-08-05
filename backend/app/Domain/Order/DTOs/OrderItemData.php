<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

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
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated, int $index = 0): self
    {
        $price = $validated['unit_price'] ?? null;

        return new self(
            productId: (int) $validated['product_id'],
            productVariantId: (int) $validated['product_variant_id'],
            quantity: (string) $validated['quantity'],
            unitPrice: $price !== null && $price !== '' ? (string) $price : null,
            notes: isset($validated['notes']) && $validated['notes'] !== ''
                ? (string) $validated['notes']
                : null,
            sortOrder: (int) ($validated['sort_order'] ?? $index),
        );
    }
}
