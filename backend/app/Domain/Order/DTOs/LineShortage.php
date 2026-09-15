<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Actions\SetOrderShortages;
use App\Domain\Order\Models\OrderItem;

/**
 * What is missing from one line, in both the units that have a claim on it.
 *
 * **Two numbers travel together because they are written together.** `quantity` is what comes off
 * the invoice, in the unit the customer was billed in; `warehouseQuantity` is what «النواقص»
 * chases and what the warehouse will receive, in the unit the shelf is counted in. Neither can be
 * computed from the other — there is no قطعة→كجم factor in the catalogue and deliberately none —
 * so they are stated as a pair and carried as one.
 *
 * Passing them as two parallel maps was the alternative and it was worse: two arrays keyed by
 * line id can fall out of step, and the one thing that must never happen is a line whose invoice
 * says one gap and whose chase says another.
 *
 * **`warehouseQuantity` null means «the same number»**, the convention
 * `order_items.warehouse_quantity` already set, so a line stocked in the unit it was sold in is
 * written exactly as it always was.
 *
 * Both null is «لا ينقص من هذا البند شيء», and {@see SetOrderShortages} clears the line.
 */
final readonly class LineShortage
{
    public function __construct(
        /** What comes off the invoice, in the line's `pricing_unit`. Null for nothing missing. */
        public ?string $quantity = null,

        /**
         * What the warehouse is short, in the shelf's unit — null where that is the same number.
         *
         * Meaningless without {@see $quantity}, and the `shortage_warehouse_quantity_needs_a_shortage`
         * CHECK refuses the pairing outright rather than leaving it to be noticed later.
         */
        public ?string $warehouseQuantity = null,
    ) {}

    /** Nothing missing from this line — the value an absent or cleared box means. */
    public static function none(): self
    {
        return new self;
    }

    public function isNothing(): bool
    {
        return $this->quantity === null || $this->quantity === '';
    }

    /**
     * The pair left standing once an arrival off the shelf has been counted in.
     *
     * **Both shrink, and they shrink in step** — see {@see OrderItem::creditForStockArrival()}
     * for why the ratio between them is the only honest way to split a partial. A full arrival
     * lands on exactly `none()`, which is what lets an order leave «نواقص» at all.
     */
    public static function afterStockArrival(OrderItem $item, string $arrived): self
    {
        $outstandingStock = $item->shortageStockQuantity();

        if ($outstandingStock === null || bccomp($arrived, $outstandingStock, 3) >= 0) {
            return self::none();
        }

        $billedLeft = bcsub(
            (string) ($item->shortage_quantity ?? '0'),
            $item->creditForStockArrival($arrived),
            3,
        );

        if (bccomp($billedLeft, '0', 3) <= 0) {
            return self::none();
        }

        return new self(
            quantity: $billedLeft,
            // Written only where it is genuinely a second number. Collapsing it back to null when
            // the units agree keeps the convention true for every row rather than only for rows
            // nobody has supplied against.
            warehouseQuantity: $item->shortage_warehouse_quantity === null
                ? null
                : bcsub($outstandingStock, $arrived, 3),
        );
    }
}
