<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Support\Exceptions\DomainException;

/**
 * A line sold in one unit and stocked in another changed after the stock left, and nobody said
 * what should leave the shelf for it now.
 *
 * {@see LineNeedsAMeasuredStockQuantity}'s rule asked again on the edit screen: «٥٠٠ قطعة» has no
 * automatic answer on a shelf counted in kilograms, and falling back to the ordered quantity
 * would take the piece count off a kilogram shelf. Keyed by the line's position in the request
 * so the app can open the box under that line.
 */
final class EditedLineNeedsAStockQuantity extends DomainException
{
    private function __construct(string $message, private readonly int $index)
    {
        parent::__construct($message);
    }

    public static function make(int $index, string $variantLabel, PricingUnit $stockUnit, PricingUnit $soldIn): self
    {
        return new self(
            "«{$variantLabel}» يُخزَّن بال{$stockUnit->label()} ويُباع بال{$soldIn->label()}"
            .' — أدخل الكمية التي تخرج من المخزن',
            $index,
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ["items.{$this->index}.warehouse_quantity" => [$this->getMessage()]];
    }
}
