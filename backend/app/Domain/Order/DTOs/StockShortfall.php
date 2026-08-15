<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Exceptions\OrderStockShortfall;

/**
 * One size an order asks a warehouse for more of than it holds.
 *
 * Carries the name as well as the two numbers, because that is the whole point of it: a refusal
 * that says only «(0.000) لا تكفي لـ (50.000)» sends whoever pressed the button back to the
 * order to work out which of its sizes it meant. See {@see OrderStockShortfall}.
 */
final readonly class StockShortfall
{
    public function __construct(
        /** The line's own snapshot — «كيس شحن — 25*35» — never the live catalogue name. */
        public string $name,

        /** What the shelf holds, as a string for the same reason a balance is one. */
        public string $available,

        /** Everything this order asks of that shelf, all its lines added together. */
        public string $required,
    ) {}
}
