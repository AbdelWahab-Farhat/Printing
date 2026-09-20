<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A line can only be financed by pool money if its material belongs to a pool.
 *
 * Nobody chooses a container any more — the material decides, through `investment_pool_items`. So
 * «fund this line from the pool» has no answer when the shelf is in no pool, and inventing one
 * would mean picking a pool on the buyer's behalf and putting somebody's money into a material he
 * never agreed to.
 *
 * The remedy is to add the shelf to a pool first, which is a decision with its own screen.
 */
final class StockItemHasNoPool extends DomainException
{
    public static function make(string $stockItem): self
    {
        return new self("المادة «{$stockItem}» لا تتبع أي صندوق — أضفها إلى صندوق أولاً");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['stock_item_ids' => [$this->getMessage()]];
    }
}
