<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Exceptions;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Support\Exceptions\DomainException;

/**
 * The requested quantity is under the product's minimum order.
 */
final class QuantityBelowMinimum extends DomainException
{
    public static function make(string $requested, string $minimum, PricingUnit $unit): self
    {
        $trim = static fn (string $value): string => rtrim(rtrim($value, '0'), '.');

        return new self(sprintf(
            'الحد الأدنى للطلب هو %s %s، والكمية المطلوبة %s',
            $trim($minimum),
            $unit->label(),
            $trim($requested),
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
