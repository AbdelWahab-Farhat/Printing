<?php

declare(strict_types=1);

namespace App\Domain\Investor\DTOs;

/**
 * One line of a purchase order, bought with pool money.
 *
 * `printingSalePrice` is **سعر السادة for this lorry** — what the press will pay the pool for a
 * unit of this plain stock when a printed line takes it. Null is the ordinary answer and means
 * «nobody said»: those goods ride the sale itself instead, and their pool is paid out of the
 * delivered order's profit.
 *
 * Agreed here rather than on the pool, because a pool outlives every lorry it buys and one frozen
 * price would either go stale or silently re-cut goods already on the shelf.
 */
final readonly class PoolPurchaseLineData
{
    public function __construct(
        public int $stockItemId,
        public ?string $printingSalePrice = null,
    ) {}
}
