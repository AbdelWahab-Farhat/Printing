<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Delivery\DeliveryService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\FulfillmentRequiresAnActor;
use App\Domain\Order\Exceptions\OrderIsClosed;
use App\Domain\Order\Exceptions\PaymentRequiresAnActor;
use App\Domain\Order\Exceptions\SettlementRequiresFullPayment;
use App\Domain\Order\Exceptions\ShortageMustBeResolved;
use App\Domain\Order\Exceptions\ShortageNeedsAQuantity;
use App\Domain\Order\Exceptions\TransitionNotAllowed;
use App\Domain\Order\Exceptions\TransitionRequiresReason;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Order\Support\TransitionFields;
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
        // The only writer of `shortage_quantity`, and the one that re-prices what it wrote.
        private readonly SetOrderShortages $setShortages,
        // Through the module's front door, never `ShippingCompany::query()` — the same seam
        // every other cross-context read here goes through.
        private readonly DeliveryService $delivery,
        // The only writer of `warehouse_quantity`, run immediately before the deduction that
        // reads it — see its own docblock.
        private readonly SetOrderStockQuantities $setStockQuantities,
        // The first real link to Inventory — see DeductOrderStock's own docblock for why it is
        // its own class rather than inlined here.
        private readonly DeductOrderStock $deductStock,
        // Costs labour, machine runtime and overhead the same moment stock leaves the warehouse
        // — see its own docblock for why it shares DeductOrderStock's guard.
        private readonly ApplyManufacturingRates $applyManufacturingRates,
        // The وسيط twin of the line above: turns each line's snapshotted unit cost into what the
        // line cost, at the same moment and for the same reason — see its own docblock.
        private readonly ApplyOutsourcingCosts $applyOutsourcingCosts,
        private readonly RecalculateOrderCogs $recalculateCogs,
        // Undoes both of the above when a cancellation follows a deduction — see its own
        // docblock.
        private readonly ReverseOrderStockDeduction $reverseStockDeduction,
        // Puts the shelf right at «جاهزة» when the press used a different amount than the
        // warehouse pulled — see its own docblock for why a correction is a restatement rather
        // than a delta movement.
        private readonly RestateOrderStockDeduction $restateStock,
        // The ledger's own front door, used unchanged — see {@see recordPaymentForOrder()}. Money taken
        // at the counter gets the same lock, the same ceiling and the same row as money taken on
        // the payments screen, because it *is* the same event.
        private readonly RecordOrderPayment $recordPayment,
    ) {}

    /**
     * @param  array<string, mixed>  $fields  What the move asked for — see {@see TransitionFields}.
     *
     * @throws OrderIsClosed
     * @throws TransitionNotAllowed
     * @throws TransitionRequiresReason
     * @throws SettlementRequiresFullPayment
     * @throws ShortageMustBeResolved
     * @throws FulfillmentRequiresAnActor
     * @throws PaymentRequiresAnActor
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

        // **The order's own road, not the general one.** An order made entirely of goods that are
        // already made walks جديدة → جاهزة — see {@see OrderFlow} — and asking the map without
        // saying so would refuse the very move `Order::availableTransitionsFor()` had just told
        // the app it could make, leaving the short road drawn on screen and enforced nowhere.
        if (! $from->canMoveTo($target, $order->production_flow)) {
            throw TransitionNotAllowed::make($from, $target);
        }

        $reason = $reason !== null && trim($reason) !== '' ? trim($reason) : null;

        if ($target->requiresReason() && $reason === null) {
            throw TransitionRequiresReason::make($target);
        }

        return DB::transaction(function () use ($order, $from, $target, $reason, $actor, $fields): Order {
            // **Money first, because the guard below reads what this writes.** «تم الاستلام» and
            // «تم التسوية» each carry a box for what was just handed over, and an accountant who
            // types the remainder into it is settling the order *with* that payment — so it has
            // to land before the settlement rule looks at the balance. Everything is one
            // transaction, so a move that is then refused takes its entry back with it.
            $this->recordPaymentForOrder($order, $target, $fields, $actor);

            // **The last step on the line is the money, and it may not be skipped.** «تم التسوية»
            // is the statement that what the order was sent out to collect came back; an order
            // reaching it while its payment status still reads «غير مدفوعة» closes the order and
            // loses the debt in the same move. Read from the ledger's cached total rather than
            // taken on trust from the person pressing the button — see
            // {@see SettlementRequiresFullPayment}.
            if ($target === OrderStatus::Settled && $order->paymentStatus()->isOutstanding()) {
                throw SettlementRequiresFullPayment::make($order->remainingAmount());
            }

            // **Two statuses can be the one where stock leaves, and `stock_deducted_at` decides
            // which.** «جاهزة للطباعة» is the warehouse handing the goods to the press, and it is
            // the first stop for every printed order. An order of ready-made goods never passes
            // through it — see {@see OrderFlow} — so for that one «جاهزة» is still the first and
            // only deduction, exactly as before this status existed.
            //
            // Nothing returns to either — see `OrderStatus::allowedNext()` — and the column is
            // never cleared, so "at most once per order" holds without a second flag. The same
            // fact drives the form: {@see TransitionFields} offers the warehouse picker on
            // whichever of the two is still the deducting one, so what is asked for and what is
            // taken cannot disagree.
            //
            // **And one road takes nothing at all.** A وسيط order's goods are made by an outside
            // vendor and never sit on a shelf of ours, so «جاهزة» there means the vendor handed
            // them over — not that a warehouse gave anything up. Asked of the flow rather than
            // written out as a status test, so the day a fourth road arrives it answers for
            // itself; see {@see OrderFlow::deductsStock()}.
            $deductStock = ($target === OrderStatus::ReadyToPrint || $target === OrderStatus::Ready)
                && $order->production_flow->deductsStock()
                && $order->stock_deducted_at === null;

            // **The other half: «جاهزة» reached by an order whose stock already went.** The
            // warehouse weighed what it pulled; the press knows what the run actually used, and
            // the second figure is the true one. Only lines whose number moved are touched — see
            // {@see RestateOrderStockDeduction}.
            $restateStock = $target === OrderStatus::Ready && $order->stock_deducted_at !== null;

            // **Production is costed the first time an order is called ready, and the fact that
            // says so is now `ready_at`.** It used to be `stock_deducted_at`, because the two
            // happened in the same breath — but stock leaves at «جاهزة للطباعة» now, so every
            // printed order arrives here already deducted and that guard would cost nothing at
            // all. Read before the save below, which is what stamps the column.
            $costProduction = $target === OrderStatus::Ready && $order->ready_at === null;

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

            // **Before the status moves, for the same reason the artwork sometimes is.** What
            // arrived of a shortage is a fact about the order as it still stands in «نواقص»,
            // where its lines are open; the status it is heading for closes them. See the
            // method's own docblock.
            $this->recordArrivedShortages($order, $from, $target, $fields);

            // And judged immediately after, so the order is refused on what it actually still
            // owes rather than on what it owed before the delivery was counted in.
            $this->guardShortageIsResolved($order, $from, $target);

            $order->forceFill($attributes)->save();

            if (! $artworkGoesFirst) {
                $this->attachDesigns($order, $fields);
            }

            $this->recordDeclaredShortages($order, $target, $fields);

            $this->guardShortage($order, $target);

            if ($deductStock && isset($fields['warehouse_id'])) {
                // **Before the deduction, never after.** What leaves the shelf is
                // `warehouse_quantity ?? quantity`, so a figure written afterwards would be a
                // note about a movement that had already taken the wrong number.
                ($this->setStockQuantities)($order->loadMissing('items'), $fields);

                $this->deductStockForOrder($order, (int) $fields['warehouse_id'], $actor);
            }

            if ($restateStock) {
                $this->restateStockForOrder($order, $fields, $actor);
            }

            // **Costed at «جاهزة» on both roads, and never at «جاهزة للطباعة».** Labour, machine
            // runtime and overhead are the press running, which has not happened when the
            // warehouse hands the order over — and by the time it has, the figure the restatement
            // above just settled is the corrected one, which is the right basis to cost against.
            if ($costProduction) {
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
     * The money that came with the move, written into the ledger as an ordinary payment.
     *
     * **Nothing is invented here.** The amount is what a person typed and the method is what
     * they picked; an empty box records nothing, which is the right answer for an order that was
     * paid weeks ago. That is the whole distinction the payments spec draws — a server that
     * derives an entry from a settlement is writing a collection nobody made, while a server
     * that stores what the person holding the cash typed is doing what the ledger is for.
     *
     * **Through {@see RecordOrderPayment} rather than a `create()` here**, so this path inherits
     * every guard the payments screen has: the row lock that makes two clerks collecting at once
     * safe, the refusal of anything over the remainder, and the receipt rule. A second way to
     * write a payment would be a second set of rules to keep in step.
     *
     * A zero is treated as an empty box rather than refused. Somebody who types it means "none",
     * and answering that with «المبلغ يجب أن يكون أكبر من صفر» is a form arguing with a person
     * who has already said what they meant.
     *
     * @param  array<string, mixed>  $fields
     *
     * @throws PaymentRequiresAnActor
     */
    private function recordPaymentForOrder(Order $order, OrderStatus $target, array $fields, ?User $actor): void
    {
        $amount = $fields[TransitionFields::PAYMENT_AMOUNT] ?? null;

        if ($amount === null || $amount === '' || bccomp(Money::normalize($amount), '0', Money::SCALE) <= 0) {
            return;
        }

        if ($actor === null) {
            throw PaymentRequiresAnActor::make();
        }

        ($this->recordPayment)($order, OrderPaymentData::fromArray([
            'amount' => $amount,
            'method' => $fields[TransitionFields::PAYMENT_METHOD] ?? null,
            // The move's own note is the transition's, not the entry's: it explains why the
            // status changed, and copying it onto a payment row would put «المندوب خصم أجرة
            // التوصيل» beside a figure it does not describe.
            'notes' => "سُجِّلت مع نقل الطلبية إلى «{$target->label()}»",
            // Stored by the same action that stores one taken on the payments screen, into the
            // same five columns. Absent unless a file was actually attached — and a file
            // attached with no amount beside it reaches nothing, because the guard above has
            // already returned: a receipt with no entry to hang on would be an orphan.
            'receipt' => $fields[TransitionFields::PAYMENT_RECEIPT] ?? null,
        ]), $actor);

        // `RecordOrderPayment` recalculates against its own locked copy, so the instance this
        // action is holding still carries the old `paid_amount` — and the settlement guard three
        // lines down reads exactly that. Refreshing here rather than there keeps the reason
        // beside the write that caused it.
        $order->refresh();
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
     * What is missing, written against the line it is missing from — on the way in and on the
     * way out.
     *
     * **Two questions, one write.** Arriving asks «كم الناقص» per line, because asked of a whole
     * order it has no answer — it is a question about a size. Leaving asks «كم وصل منه», which
     * is the same fact from the other end: the stock turned up, and the invoice the shortage cut
     * has to come back with it. Both land in {@see SetOrderShortages}, so the money is re-derived
     * once however the number moved.
     *
     * Cancelling is deliberately neither. An order written off while short keeps the record of
     * what was short when it was written off; asking a clerk what arrived, of a job nobody is
     * going to do, would be a form standing between them and the decision.
     *
     * @param  array<string, mixed>  $fields
     */
    private function recordDeclaredShortages(Order $order, OrderStatus $target, array $fields): void
    {
        if ($target === OrderStatus::Shortage) {
            ($this->setShortages)($order, $this->declared($order, $fields));
        }
    }

    /**
     * What arrived of the shortage, written **before** the order leaves «نواقص».
     *
     * **The side of the status write this falls on is decided by the same rule the artwork
     * follows.** {@see SetOrderShortages} refuses an order whose lines are locked, and «نواقص» is
     * one of the four statuses where they are not — but «جاهزة للطباعة», the status this move
     * usually lands on, is not: the goods have been weighed and the stock has already left the
     * warehouse by then, so the lines close there on purpose. Recorded after the save, this would
     * refuse every delivery that resolved a shortage.
     *
     * So it is recorded while the order still stands in the status that permits it — exactly as
     * `$artworkGoesFirst` decides which side of the write the designs go on.
     *
     * @param  array<string, mixed>  $fields
     */
    private function recordArrivedShortages(Order $order, OrderStatus $from, OrderStatus $target, array $fields): void
    {
        if ($from === OrderStatus::Shortage && ! $target->isFinal()) {
            ($this->setShortages)($order, $this->remaining($order, $fields));
        }
    }

    /**
     * The shortages as the clerk typed them: absolute, one per line.
     *
     * @param  array<string, mixed>  $fields
     * @return array<int, mixed>
     */
    private function declared(Order $order, array $fields): array
    {
        $shortages = [];

        foreach ($order->items as $item) {
            $shortages[(int) $item->getKey()] = $fields["shortage_{$item->getKey()}"] ?? null;
        }

        return $shortages;
    }

    /**
     * What is *still* missing once the delivery has been counted in.
     *
     * The field asks what arrived rather than what is left, because that is the number the
     * person holding the delivery note has. An untouched field means the whole shortage arrived
     * — it is pre-filled with exactly that, so leaving it alone is an answer rather than a
     * silence — and the subtraction is done here so nobody does it in their head.
     *
     * @param  array<string, mixed>  $fields
     * @return array<int, mixed>
     */
    private function remaining(Order $order, array $fields): array
    {
        $shortages = [];

        foreach ($order->items as $item) {
            $short = (string) ($item->shortage_quantity ?? '0');
            $received = $fields["received_{$item->getKey()}"] ?? $short;
            $received = $received === null || $received === '' ? $short : (string) $received;

            $left = bcsub($short, $received, 3);
            $shortages[(int) $item->getKey()] = bccomp($left, '0', 3) > 0 ? $left : null;
        }

        return $shortages;
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

        ($this->deductStock)($order->loadMissing('items.product'), $warehouseId, (int) $actor->getKey());
    }

    /**
     * Standard-costs the labour, machine runtime and overhead behind whatever
     * {@see deductStockForOrder} just took off the shelf, then rolls both into the order's own
     * `total_cogs`.
     *
     * `$actor` is never null here: this only ever runs immediately after `deductStockForOrder`,
     * which already refused a null one.
     */
    private function costProductionForOrder(Order $order, ?User $actor): void
    {
        // It used to run only immediately after `deductStockForOrder()`, which had already
        // refused a null actor, so the parameter could be non-nullable. Costing now happens on
        // its own at «جاهزة» — after a *restatement* as well as after a first deduction — so the
        // refusal has to be stated here rather than inherited from a call site next door.
        if ($actor === null) {
            throw FulfillmentRequiresAnActor::make();
        }

        ($this->applyManufacturingRates)($order->loadMissing('items'), (int) $actor->getKey());

        // **Both, unconditionally, and neither asks about the road.** A printed order carries no
        // `unit_cost` on any line and a وسيط order has no rates to apply, so each action is a
        // no-op on the other's orders — and a mixed order, which the flow rules make unlikely
        // rather than impossible, is costed correctly line by line instead of one way or the
        // other. Asking `production_flow` here would be a third copy of a decision the lines
        // already carry.
        ($this->applyOutsourcingCosts)($order);

        ($this->recalculateCogs)($order);
    }

    /**
     * Puts the shelf right once the press knows what the run actually used.
     *
     * @param  array<string, mixed>  $fields
     *
     * @throws FulfillmentRequiresAnActor
     */
    private function restateStockForOrder(Order $order, array $fields, ?User $actor): void
    {
        if ($actor === null) {
            throw FulfillmentRequiresAnActor::make();
        }

        ($this->restateStock)($order->loadMissing('items'), $fields, (int) $actor->getKey());
    }

    /**
     * An order still short of something is not ready for the press.
     *
     * **Only on the way into «جاهزة للطباعة», and only from «نواقص».** That move is a promise to
     * another department that the goods are all here; every other move an order short of stock
     * can make — being written off, having the shortage corrected — is left alone, because none
     * of them tells anybody the order is complete.
     *
     * Reads the lines fresh: `recordShortages()` has just written to them on this same move, and
     * the whole point is to judge the order as it stands *after* that.
     *
     * @throws ShortageMustBeResolved
     */
    private function guardShortageIsResolved(Order $order, OrderStatus $from, OrderStatus $target): void
    {
        if ($from !== OrderStatus::Shortage || $target !== OrderStatus::ReadyToPrint) {
            return;
        }

        $stillShort = $order->load('items')->unresolvedShortages();

        if ($stillShort !== []) {
            throw ShortageMustBeResolved::make($stillShort);
        }
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
}
