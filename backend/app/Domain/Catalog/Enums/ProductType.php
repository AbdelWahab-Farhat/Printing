<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Enums;

/**
 * How a bag is made and billed: printed bags priced per piece by size, and plain (سادة) bags
 * sold by the kilo.
 *
 * **«النوع», and it used to be called «التصنيف».** That was the wrong word for it: this says how
 * the thing is produced, while a *category* says where it stands in the catalogue — أكياس, علب
 * وكراتين, ستيكرات. The catalogue sense now belongs to {@see ProductCategory}, which is a table
 * the business curates; see PRODUCT-CATEGORIES.md.
 *
 * **The wire did not move with the name.** The column is still `category` and so is the API key,
 * because renaming those would break every consumer — the public catalogue site included — to
 * tidy an identifier nobody outside this codebase reads. Hence the cast in {@see Product} that
 * maps `category` onto this enum.
 *
 * Kept separate from {@see PricingUnit} on purpose. Today every General bag happens to be sold
 * by the kilo, but "plain rather than printed" is what the customer is choosing, and "by weight
 * rather than by count" is how it is billed. Collapsing the two would make a plain bag sold per
 * piece impossible to express.
 */
enum ProductType: string
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
