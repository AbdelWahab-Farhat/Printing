<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An edit named a line id that is not one of this order's lines.
 *
 * Asked by the action rather than the request because only the order knows its lines: a rule
 * in the request would need the order bound before validation, and `exists:order_items,id` would
 * happily accept a line from somebody else's order.
 */
final class OrderLineNotOnOrder extends DomainException
{
    public static function make(int $lineId): self
    {
        return new self("البند رقم {$lineId} ليس من بنود هذه الطلبية — أعد فتح الطلبية وحاول مرة أخرى");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
