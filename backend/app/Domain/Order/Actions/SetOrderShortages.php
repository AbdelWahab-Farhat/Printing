<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\LineShortage;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Events\OrderShortagesRecorded;
use App\Domain\Order\Exceptions\OrderItemsAreLocked;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Writes what is missing from an order, and re-prices it.
 *
 * **The only place `shortage_quantity` — or the warehouse figure beside it — is ever written**,
 * which is the whole point of the class:
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
 *
 * **And it announces itself, once.** {@see OrderShortagesRecorded} fires after the write, which
 * is what lets the Shortages section mirror all three of those paths from a single hook — see
 * Docs/shortages/SHORTAGES-DESIGN.md §٣. Being the only writer is what makes one announcement
 * enough, and it is also why the announcement belongs here rather than at the three call sites.
 */
final class SetOrderShortages
{
    public function __construct(private readonly RecalculateOrderTotals $recalculate) {}

    /**
     * @param  array<int|string, LineShortage|string|int|float|null>  $shortages  line id → what
     *              is missing from it. A {@see LineShortage} states both units; a bare number is
     *              the shorthand for a line whose shelf counts the way the invoice does, which is
     *              most of them. Absent or null is nothing missing.
     * @param  User|null  $actor  who moved it, so whoever did is not told that they did. Null
     *                            when nobody did: a console command, a seeder, the sync itself.
     * @param  ShortageRevision  $reason  why the set is being rewritten — see the enum for why a
     *                                    listener cannot work this out from the numbers.
     *
     * @throws OrderItemsAreLocked
     */
    public function __invoke(
        Order $order,
        array $shortages,
        ?User $actor = null,
        ShortageRevision $reason = ShortageRevision::Corrected,
    ): Order {
        // The same line the lines themselves close at: «جاهزة» means the run is made and
        // counted, so what is missing is no longer an estimate somebody corrects.
        if (! $order->itemsAreEditable()) {
            throw OrderItemsAreLocked::make($order->status);
        }

        $updated = DB::transaction(function () use ($order, $shortages): Order {
            foreach ($order->items()->get() as $item) {
                $missing = self::normalise($shortages[$item->getKey()] ?? null);

                // **Both columns or neither**, which is what the
                // `shortage_warehouse_quantity_needs_a_shortage` CHECK insists on: a weight left
                // standing beside a cleared shortage would leave «النواقص» chasing goods the
                // customer has already been billed for.
                $item->forceFill($missing->isNothing() ? [
                    'shortage_quantity' => null,
                    'shortage_warehouse_quantity' => null,
                ] : [
                    'shortage_quantity' => $missing->quantity,
                    // Null where the shelf counts in the unit the line was sold in — see the DTO.
                    'shortage_warehouse_quantity' => $missing->warehouseQuantity,
                ]);

                $item->forceFill(['line_total' => $item->deriveLineTotal()])->save();
            }

            return ($this->recalculate)($order->load('items'));
        });

        // **After the commit, never inside it.** The listener is a mirror rather than a money
        // move, and mirroring a transaction that then rolled back would leave the shortages
        // section chasing a sack nobody is short of. The three money events in this domain make
        // the opposite trade on purpose — see the event's own docblock.
        OrderShortagesRecorded::dispatch(
            (int) $updated->getKey(),
            $reason,
            $actor === null ? null : (int) $actor->getKey(),
        );

        return $updated;
    }

    /**
     * Accepts either shape a caller may hold.
     *
     * **A bare number is not a legacy wart, it is the honest form for most lines.** A size sold
     * and stocked in the same unit has one gap, not two, and `LineShortage` says so by leaving
     * `warehouseQuantity` null — so a scalar and the pair it expands to are the same statement.
     * Demanding the object everywhere would make every console command, seeder and same-unit
     * caller build a DTO to express «ناقص ثلاثون».
     *
     * Where the two units *do* differ, a bare number is still accepted here and means «the gap is
     * that many of the shelf's unit too». That is a real possibility the domain cannot rule out,
     * and it is not this action's job to refuse it: the place that knows a human is guessing is
     * the form, and `SetOrderShortagesRequest` demands the second figure there — named in prose
     * rather than imported, because Domain does not point at Application.
     */
    private static function normalise(mixed $value): LineShortage
    {
        if ($value instanceof LineShortage) {
            return $value;
        }

        return $value === null || $value === ''
            ? LineShortage::none()
            : new LineShortage(quantity: (string) $value);
    }
}
