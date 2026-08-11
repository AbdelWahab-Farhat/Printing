<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

use App\Domain\Vendor\DTOs\StockArrivalItemData;

final readonly class PurchaseOrderItemData
{
    public function __construct(
        public int $productVariantId,
        /** Always positive, normalised to three decimal places — see {@see quantityOrdered()}. */
        public string $quantityOrdered,
        /**
         * The negotiated vendor cost, per unit. There is no catalogue price for what *we* pay a
         * vendor, so this always comes from the request — never derived, unlike
         * `OrderItemData::unitPrice`, which the catalogue overrides whenever one exists.
         */
        public string $unitCost,
        /** Present when updating an existing line; null when creating a new one. */
        public ?int $id = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated  One entry from the request's `items` array.
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            quantityOrdered: self::quantityOrdered($validated['quantity_ordered']),
            unitCost: self::quantityOrdered($validated['unit_cost']),
            id: isset($validated['id']) ? (int) $validated['id'] : null,
        );
    }

    /**
     * Cast through string, never left as a float — the same reasoning
     * {@see StockArrivalItemData} carries.
     */
    private static function quantityOrdered(mixed $value): string
    {
        return number_format((float) $value, 3, '.', '');
    }
}
