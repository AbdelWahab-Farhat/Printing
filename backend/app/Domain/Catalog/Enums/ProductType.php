<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Enums;

/**
 * The catalogue's own split: printed bags priced per piece by size, and plain (سادة) bags sold
 * by the kilo.
 *
 * Kept separate from {@see PricingUnit} on purpose. Today every General bag happens to be sold
 * by the kilo, but "plain rather than printed" is what the customer is choosing, and "by weight
 * rather than by count" is how it is billed. Collapsing the two would make a plain bag sold per
 * piece impossible to express.
 */
enum ProductCategory: string
{
    case Printed = 'printed';
    case General = 'general';

    public function label(): string
    {
        return match ($this) {
            self::Printed => 'مطبوعة',
            self::General => 'سادة',
        };
    }
}
