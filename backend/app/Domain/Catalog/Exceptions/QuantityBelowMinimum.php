<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Exceptions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Support\DecimalText;
use App\Support\Exceptions\DomainException;

/**
 * The requested quantity is under the product's minimum order.
 */
final class QuantityBelowMinimum extends DomainException
{
    /**
     * **The product is named because a basket has more than one line.**
     *
     * [self::fieldErrors()] reports against a bare `quantity` — it is thrown from the catalogue,
     * which prices one line and has never been told which position in a request that line came
     * from. On the quote screen there is only one product and the name costs nothing; in an
     * order of six it is the whole message, because «الحد الأدنى للطلب هو ١٠٠٠» against a basket
     * says nothing a customer can act on.
     */
    public static function make(string $requested, string $minimum, PricingUnit $unit, ?string $product = null): self
    {
        return new self(sprintf(
            'الحد الأدنى لطلب %s هو %s %s، والكمية المطلوبة %s',
            $product === null ? 'هذا المنتج' : sprintf('«%s»', $product),
            DecimalText::trim($minimum),
            $unit->label(),
            DecimalText::trim($requested),
        ));
    }

    /**
     * Reported against the field the client actually sent, so the app can show it inline.
     *
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['quantity' => [$this->getMessage()]];
    }
}
