<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Delivery\DeliveryService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\DesignRequiredBeforeDesigning;
use App\Domain\Order\Exceptions\FulfillmentRequiresAnActor;
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
        // The first real link to Inventory — see DeductOrderStock's own docblock for why it is
        // its own class rather than inlined here.
        private readonly DeductOrderStock $deductStock,
        // Costs labour, machine runtime and overhead the same moment stock leaves the warehouse
        // — see its own docblock for why it shares DeductOrderStock's guard.
        private readonly ApplyManufacturingRates $applyManufacturingRates,
        private readonly RecalculateOrderCogs $recalculateCogs,
        // Undoes both of the above when a cancellation follows a deduction — see its own
        // docblock.
        private readonly ReverseOrderStockDeduction $reverseStockDeduction,
    ) {}

    /**
     * @param  array<string, mixed>  $fields  What the move asked for — see {@see TransitionFields}.
     *
     * @throws OrderIsClosed
     * @throws TransitionNotAllowed
     * @throws TransitionRequiresReason
     * @throws DesignRequiredBeforeDesigning
     * @throws FulfillmentRequiresAnActor
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
            // Decided before anything below touches the row: `printing` is re-enterable (a
            // reprint goes `ready`/`shortage` back to `printing`), and stock may leave the
            // warehouse exactly once per order — see DeductOrderStock.
            $deductStock = $target === OrderStatus::Printing && $order->stock_deducted_at === null;

            // The mirror image: a cancellation only has anything to undo if stock genuinely left
            // — `stock_deducted_at` is never cleared by a reversal, so this reads the same fact
            // `deductStock` above already relies on, not a second copy of it.
            $reverseStock = $target === OrderStatus::Cancelled && $order->stock_deducted_at !== null;

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

            // Stamped here so it lands in the same save as the status change — trusted the same
            // way `shipping_company_id` is trusted on `OutForDelivery`: TransitionFields already
            // required this field for exactly this case, so a caller that skipped that layer
            // (a console command, an importer) simply does not get a deduction, rather than the
            // domain re-deriving what the request already settled.
            if ($deductStock && isset($fields['warehouse_id'])) {
                $attributes['stock_deducted_at'] = now();
                $attributes['fulfillment_warehouse_id'] = (int) $fields['warehouse_id'];
            }

            $order->forceFill($attributes)->save();

            // **The status is written first, and the order matters.** Artwork may only be
            // attached to an order in a status that allows it — see `designsAreEditable()` —
            // and the commonest case of a move carrying artwork is the correction path, «قيد
            // الطباعة» back to «قيد التصميم», where the *old* status forbids it and the new one
            // is the whole point. Everything here is one transaction, so a design that turns
            // out to belong to somebody else takes the status change back with it: there is no
            // order left holding a version it should never have had.
            $this->attachDesigns($order, $fields);
            $this->recordShortages($order, $target, $fields);

            $this->guardDesigning($order, $target);
            $this->guardShortage($order, $target);

            if ($deductStock && isset($fields['warehouse_id'])) {
                $this->deductStockForOrder($order, (int) $fields['warehouse_id'], $actor);
                $this->costProductionForOrder($order, $actor);
            }

            if ($reverseStock) {
                $this->reverseStockForOrder($order, $actor);
            }

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

    /**
     * Hands off to {@see DeductOrderStock} with the order's lines loaded — strict-mode lazy
     * loading is on outside production, so `items` has to be fetched explicitly here rather than
     * left for `DeductOrderStock` to touch cold, the same reason {@see recordShortages()} never
     * runs for a target that does not need the relation.
     *
     * @throws FulfillmentRequiresAnActor
     */
    private function deductStockForOrder(Order $order, int $warehouseId, ?User $actor): void
    {
        if ($actor === null) {
            throw FulfillmentRequiresAnActor::make();
        }

        ($this->deductStock)($order->loadMissing('items'), $warehouseId, (int) $actor->getKey());
    }

    /**
     * Standard-costs the labour, machine runtime and overhead behind whatever
     * {@see deductStockForOrder} just took off the shelf, then rolls both into the order's own
     * `total_cogs`.
     *
     * `$actor` is never null here: this only ever runs immediately after `deductStockForOrder`,
     * which already refused a null one.
     */
    private function costProductionForOrder(Order $order, User $actor): void
    {
        ($this->applyManufacturingRates)($order->loadMissing('items'), (int) $actor->getKey());
        ($this->recalculateCogs)($order);
    }

    /**
     * Hands off to {@see ReverseOrderStockDeduction} with the order's lines loaded — the same
     * eager-loading reasoning `deductStockForOrder()` already carries.
     *
     * @throws FulfillmentRequiresAnActor
     */
    private function reverseStockForOrder(Order $order, ?User $actor): void
    {
        if ($actor === null) {
            throw FulfillmentRequiresAnActor::make();
        }

        ($this->reverseStockDeduction)($order->loadMissing('items'), (int) $actor->getKey());
    }

    /**
     * «قيد التصميم» means there is artwork to look at.
     *
     * The field that asks for it refuses the empty payload with a friendlier message; this is
     * the same rule for every other caller — a queue worker, an importer, a future endpoint.
     *
     * **This is a rule about entering the step, not about reaching the press.** Nothing forces
     * an order through design at all: plain (سادة) bags and jobs whose artwork was settled
     * beforehand go «جديدة» straight to «قيد الطباعة». But an order that *is* sent to design is
     * being sent there to have something looked at, and a design queue full of orders carrying
     * nothing is a queue nobody can work.
     *
     * @throws DesignRequiredBeforeDesigning
     */
    private function guardDesigning(Order $order, OrderStatus $target): void
    {
        if ($target !== OrderStatus::Designing) {
            return;
        }

        if ($order->designs()->exists()) {
            return;
        }

        throw DesignRequiredBeforeDesigning::make();
    }
}
