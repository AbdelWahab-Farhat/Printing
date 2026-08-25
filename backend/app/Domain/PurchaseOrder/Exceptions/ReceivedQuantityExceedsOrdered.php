<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A line's total received quantity, this receipt included, would pass what was ordered. Refused
 * rather than capped: a shipment bigger than the order is a discrepancy someone needs to look
 * at, not a number this endpoint should quietly shrink.
 */
final class ReceivedQuantityExceedsOrdered extends DomainException
{
    public static function make(int $stockItemId, string $ordered, string $alreadyReceived, string $incoming): self
    {
        return new self(
            "الكمية المستلمة للمقاس رقم {$stockItemId} ({$alreadyReceived} + {$incoming}) ".
            "تتجاوز الكمية المطلوبة ({$ordered})",
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
