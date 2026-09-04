<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Changing a shelf's unit writes its balance off first.
 *
 * `SetStockItemUnit::discardBalances()` posts a real decreasing adjustment for every warehouse
 * holding the item before relabelling it — which would FIFO-consume a deal's entire holding and
 * book it as a loss nobody caused.
 */
final class StockItemIsFundedByADeal extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكن تغيير وحدة قياس مادة يموّلها مستثمر وما زال لها رصيد');
    }
}
