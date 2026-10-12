<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A line's new quantity is smaller than what is recorded as missing from it.
 *
 * **The shortage is part of the quantity, never more than it** — the same ceiling
 * `SetOrderShortagesRequest` puts on the shortage from the other side. Lowering the quantity
 * under it would leave «النواقص» chasing more bags than the customer ordered.
 */
final class LineQuantityBelowItsShortage extends DomainException
{
    public static function make(string $variantLabel, string $shortage): self
    {
        return new self(
            "الكمية الجديدة لـ«{$variantLabel}» أقل من الناقص المسجّل عليه ({$shortage}) — صحّح النواقص أولاً"
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
