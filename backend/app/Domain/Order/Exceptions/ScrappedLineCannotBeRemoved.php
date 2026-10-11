<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A line with spoilage recorded against it cannot be taken off the order.
 *
 * **The spoilage is a cost of this order, and it is carried on the line.** Its
 * `production_cost_entries` row names the line, and the order's cost is summed over the lines it
 * still has — so removing the line would make the spoiled bags vanish from what the order cost.
 * Its quantity can still change; only its removal is refused.
 */
final class ScrappedLineCannotBeRemoved extends DomainException
{
    public static function make(string $variantLabel): self
    {
        return new self("سُجِّل تلف على «{$variantLabel}»، فلا يُحذف من الطلبية — يمكن تعديل كميته فقط");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
