<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

final readonly class ReceivePurchaseOrderItemData
{
    public function __construct(
        public int $productVariantId,
        /** Always positive, normalised to three decimal places — see {@see quantity()}. */
        public string $quantity,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            quantity: self::quantity($validated['quantity']),
        );
    }

    private static function quantity(mixed $value): string
    {
        return number_format((float) $value, 3, '.', '');
    }
}
