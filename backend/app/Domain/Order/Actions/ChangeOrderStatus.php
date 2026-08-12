<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Delivery\DeliveryService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\OrderIsClosed;
use App\Domain\Order\Exceptions\ShortageNeedsAQuantity;
use App\Domain\Order\Exceptions\TransitionNotAllowed;
use App\Domain\Order\Exceptions\TransitionRequiresReason;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * Moves an order, or refuses to.
 *
 * The only way a status changes. Everything the machine promises is enforced here — the map,
 * the reason a cancellation owes, the quantity a shortage owes, the stamp each milestone leaves
 * and the row in the timeline — so no caller can get half of it right.
 *
 * **The destination decides which way "out" means.** A clerk presses one button; whether that
 * lands on «استلام مكتب» or «جاري التوصيل» is read from the order's own fulfilment type rather
 * than taken from the request. A payload naming the wrong one of the two is corrected rather
 * than refused: the clerk did not choose it, so there is nothing to tell them off for.
 */
final class ChangeOrderStatus
{
    public function __construct(
        private readonly RecordStatusTransition $record,
        private readonly AddOrderDesign $addDesign,
        // Through the module's front door, never `ShippingCompany::query()` — the same seam
        // every other cross-context read here goes through.
        private readonly DeliveryService $delivery,
    ) {}

    /**
     * @param  array<string, mixed>  $fields  What the move asked for — see {@see TransitionFields}.
     *
     * @throws OrderIsClosed
     * @throws TransitionNotAllowed
     * @throws TransitionRequiresReason
     */
    public function __invoke(
        Order $order,
        OrderStatus $target,
        ?string $reason = null,
        ?User $actor = null,
        array $fields = [],
    ): Order {
        $from = $order->status;

        if ($from->isFinal()) {
            throw OrderIsClosed::make($from);
        }

        $target = $this->resolve($order, $target);

        if (! $from->canMoveTo($target)) {
            throw TransitionNotAllowed::make($from, $target);
        }

        $reason = $reason !== null && trim($reason) !== '' ? trim($reason) : null;

        if ($target->requiresReason() && $reason === null) {
            throw TransitionRequiresReason::make($target);
        }

        return DB::transaction(function () use ($order, $from, $target, $reason, $actor, $fields): Order {
            $attributes = ['status' => $target];

            if ($column = $target->timestampColumn()) {
                $attributes[$column] = now();
            }

            if ($target === OrderStatus::Cancelled) {
                $attributes['cancellation_reason'] = $reason;
            }

            // Who took it. The name is snapshotted beside the key for the same reason the
            // city's is: what an order says carried it is a fact about that day, and it must
            // survive the company being renamed or removed from the list.
            if ($target === OrderStatus::OutForDelivery && isset($fields['shipping_company_id'])) {
                $carrier = $this->delivery->findShippingCompany((int) $fields['shipping_company_id']);

                $attributes['shipping_company_id'] = $carrier->getKey();
                $attributes['shipping_company'] = $carrier->name;
                $attributes['courier_phone'] = $fields['courier_phone'] ?? null;
            }

            // Weighed on the way onto the shelf. Kept even when the order later moves on: it is
            // what the parcel weighs, not a note about one moment.
            if ($target === OrderStatus::Ready && isset($fields['weight_kg'])) {
                $attributes['weight_kg'] = $fields['weight_kg'];
            }

            // Only when it differs from the invoice — see {@see TransitionFields}. An empty
            // field settles the order at its own total and leaves the column null, so a value
            // here always means somebody counted something different.
            if ($target === OrderStatus::Settled) {
                $collected = $fields['collected_amount'] ?? null;

                $attributes['collected_amount'] = $collected === null || $collected === ''
                    ? null
                    : $collected;
            }

            // **The artwork is attached while the order stands in the status that accepts it.**
            // Only «قيد التصميم» does — see `designsAreEditable()` — and a move carrying artwork
            // is either arriving there or leaving it, so which side of the status write the
            // attachment falls on is decided by the order, not fixed in the code:
            //
            // - Leaving design for the press: the *old* status is the permitting one, so the
            //   versions go on before the move is written. This is the designer finishing.
            // - Arriving in design — «جديدة» forward, or the correction path back from «قيد
            //   الطباعة» — the *new* status is the permitting one, so the move is written first.
            //
            // Everything here is one transaction either way, so a design that turns out to
            // belong to somebody else takes the status change back with it: there is no order
            // left holding a version it should never have had, and none left in a status it was
            // only moved to in order to carry one.
            $artworkGoesFirst = $order->designsAreEditable();

            if ($artworkGoesFirst) {
                $this->attachDesigns($order, $fields);
            }

            $order->forceFill($attributes)->save();

            if (! $artworkGoesFirst) {
                $this->attachDesigns($order, $fields);
            }

            $this->recordShortages($order, $target, $fields);

            $this->guardShortage($order, $target);

            ($this->record)($order, $from, $target, $reason, $actor);

            return $order->refresh();
        });
    }

    /**
     * Either dispatch status means "it is leaving"; the city says which one that is.
     */
    private function resolve(Order $order, OrderStatus $target): OrderStatus
    {
        return $target->isDispatch()
            ? OrderStatus::dispatchFor($order->fulfilment_type)
            : $target;
    }

    /**
     * Versions of the artwork that came with the move.
     *
     * Each goes through {@see AddOrderDesign}, so a design belonging to another customer is
     * refused by the one place that knows the rule, and the version numbers are allocated the
     * same way they are when a design is added on its own.
     *
     * @param  array<string, mixed>  $fields
     */
    private function attachDesigns(Order $order, array $fields): void
    {
        foreach ((array) ($fields['design_ids'] ?? []) as $designId) {
            ($this->addDesign)($order, (int) $designId);
        }
    }

    /**
     * What is missing, written against the line it is missing from.
     *
     * Each line's own field, because «كم الناقص» asked of an order has no answer — it is a
     * question about a size. A line left alone is cleared rather than left holding what a
     * previous visit to «نواقص» recorded: an order bounces in and out of this status, and a
     * stale number is worse than none.
     *
     * @param  array<string, mixed>  $fields
     */
    private function recordShortages(Order $order, OrderStatus $target, array $fields): void
    {
        if ($target !== OrderStatus::Shortage) {
            return;
        }

        foreach ($order->items as $item) {
            $missing = $fields["shortage_{$item->getKey()}"] ?? null;

            $item->forceFill([
                'shortage_quantity' => $missing === null || $missing === '' ? null : $missing,
            ])->save();
        }
    }

    /**
     * A «نواقص» that does not say what is missing is a status nobody can act on.
     *
     * The fields are each optional — most shortages are one size out of several, and marking
     * them all required would have staff typing zeros to get past the form — so the rule that
     * matters is this one: at least one line short by something.
     *
     * @throws ShortageNeedsAQuantity
     */
    private function guardShortage(Order $order, OrderStatus $target): void
    {
        if ($target !== OrderStatus::Shortage) {
            return;
        }

        $recorded = $order->items()
            ->whereNotNull('shortage_quantity')
            ->where('shortage_quantity', '>', 0)
            ->exists();

        if (! $recorded) {
            throw ShortageNeedsAQuantity::make();
        }
    }
}
