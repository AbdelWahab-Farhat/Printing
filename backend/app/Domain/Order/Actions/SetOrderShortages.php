<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Exceptions\OrderItemsAreLocked;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Writes what is missing from an order, and re-prices it.
 *
 * **The only place `shortage_quantity` is ever written**, which is the whole point of the class:
 * the number moves money now — see {@see OrderItem::billableQuantity()} — so a second path that
 * set it without re-deriving the totals would leave an invoice quietly disagreeing with its own
 * lines. Three callers, one rule: entering «نواقص», leaving it, and correcting it afterwards
 * from the order screen.
 *
 * **The set is replaced, not merged.** Every line of the order is written from the map, and a
 * line the map does not mention is *cleared* rather than left alone. All three callers show the
 * whole order — the form does, and the sheet does — so "absent" always means "nothing missing
 * from this one", and treating it as "leave whatever was there" would make un-recording a
 * shortage impossible from the only screens that record one.
 *
 * **Reversible by construction.** Nothing is subtracted from anything: put a shortage back to
 * null and the line returns to the exact number it was, because the total is derived from the
 * ordered quantity and the price agreed on the day, neither of which this ever touches.
 */
final class SetOrderShortages
{
    public function __construct(private readonly RecalculateOrderTotals $recalculate) {}

    /**
     * @param  array<int|string, mixed>  $shortages  line id → what is missing from it; null or
     *                                               empty for nothing missing.
     *
     * @throws OrderItemsAreLocked
     */
    public function __invoke(Order $order, array $shortages): Order
    {
        // The same line the lines themselves close at: «جاهزة» means the run is made and
        // counted, so what is missing is no longer an estimate somebody corrects.
        if (! $order->itemsAreEditable()) {
            throw OrderItemsAreLocked::make($order->status);
        }

        return DB::transaction(function () use ($order, $shortages): Order {
            foreach ($order->items()->get() as $item) {
                $missing = $shortages[$item->getKey()] ?? null;
                $missing = $missing === null || $missing === '' ? null : (string) $missing;

                $item->forceFill(['shortage_quantity' => $missing]);
                $item->forceFill(['line_total' => $item->deriveLineTotal()])->save();
            }

            return ($this->recalculate)($order->load('items'));
        });
    }
}
