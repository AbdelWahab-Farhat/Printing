<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Enums;

/**
 * What a quantity means for this product, and therefore what its price is *per*.
 */
enum PricingUnit: string
{
    case Piece = 'piece';
    case Kilogram = 'kilogram';

    public function label(): string
    {
        return match ($this) {
            self::Piece => 'قطعة',
            self::Kilogram => 'كيلوغرام',
        };
    }

    /**
     * Pieces are countable, so half a piece is meaningless; weight is not.
     * This is what stops an order for 2.5 shipping bags.
     */
    public function requiresWholeQuantities(): bool
    {
        return $this === self::Piece;
    }
}
