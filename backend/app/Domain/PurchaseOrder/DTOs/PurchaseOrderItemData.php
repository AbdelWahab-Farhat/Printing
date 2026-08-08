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
