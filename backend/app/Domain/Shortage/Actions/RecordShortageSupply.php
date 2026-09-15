<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Order\DTOs\LineShortage;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Shortage\DTOs\ShortageSupplyData;
use App\Domain\Shortage\Enums\ShortageStatus;
use App\Domain\Shortage\Enums\SupplyKind;
use App\Domain\Shortage\Exceptions\ShortageIsClosed;
use App\Domain\Shortage\Exceptions\ShortageIsNotStockable;
use App\Domain\Shortage\Exceptions\ShortageWeightIsUnknown;
use App\Domain\Shortage\Exceptions\SupplyExceedsRemaining;
use App\Domain\Shortage\Exceptions\SupplyNeedsAWarehouse;
use App\Domain\Shortage\Exceptions\SupplyRequiresAnActor;
use App\Domain\Shortage\Models\Shortage;
use App\Domain\Shortage\Models\ShortageSupply;
use Illuminate\Support\Facades\DB;

/**
 * Records that some of a shortage came back, what it cost, and how it was paid for.
 *
 * **Four things happen in one transaction, and the order of them is the design:**
 *
 * 1. the goods are posted onto a shelf, opening a cost layer at what was paid for them;
 * 2. the entry is written to the ledger, naming that arrival;
 * 3. the caches on the shortage are restated from that ledger, which is what may close it;
 * 4. on an order-born shortage, the order line is told — which is what puts the goods back on
 *    the customer's invoice.
 *
 * **Step one is why this action exists rather than a money note.** An order cannot leave «نواقص»
 * until every `shortage_quantity` is zero, and the deduction that follows takes the **full**
 * ordered quantity off the shelf — `OrderItem::producedQuantity()` knows nothing about
 * shortages. So the sacks have to reach the warehouse or the order is refused at «جاهزة» with a
 * message about a balance that says nothing about the purchase somebody made last week. Posting
 * the arrival here means one purchase and one record, instead of this row plus a separate
 * document that nothing links to it — and because the order then draws the layer, the money
 * reaches `cost_of_goods_sold.material` in the P&L, which is the only road to that report that
 * exists before an accounting context does.
 *
 * **Nothing in Inventory changed to allow it.** The movement goes through
 * {@see InventoryService::recordMovement()} — the door every other context already uses — as an
 * ordinary `PurchaseArrival`. See {@see StockMovementData::shortagePurchase()} for why it is not
 * a movement type of its own.
 *
 * **A shortage with nothing behind it on a shelf skips step one**, and only that step: a roll of
 * tape nobody stocks is still a purchase worth recording. See
 * {@see App\Domain\Shortage\Models\Shortage::isStockable()}.
 *
 * **Step one needs no conversion, and that is by construction.** A shortage is denominated in the
 * unit its shelf is counted in — `shortages.unit` is copied from `OrderItem::stockUnit()`, not
 * from `pricing_unit` — so the quantity on this row is already the number the warehouse receives
 * and the number `unit_cost` is per. The invoice's share of it is a separate figure living on the
 * order line, apportioned in step four.
 *
 * **Step three is why this action reaches into Orders at all.** `order_items.shortage_quantity`
 * is subtracted from what the customer is billed, so goods bought to cover a shortage are goods
 * the customer must be charged for; leaving the line alone would mean the shop paid 750 د.ل for
 * sacks it then gave away. It goes through `OrderService::setShortages()` — the same door the
 * order screen uses — rather than writing the column, because that action re-prices the line in
 * the same breath and is the only writer there has ever been.
 *
 * **And that write fires `OrderShortagesRecorded`, which runs the sync, which lands back here.**
 * The loop is real and it terminates: the sync is declarative, so on its pass `required` is
 * recomputed as `shortage_quantity + Σ supplied` — the same number it already held — and nothing
 * changes. That is the property the formula exists for; an incremental reconciliation would
 * double every purchase on its own second pass. See SHORTAGES-DESIGN §٣.
 *
 * **The lock is the first statement inside the transaction**, the idiom the five money actions in
 * Orders already use. Two clerks each recording the last ten kilos of the same shortage otherwise
 * both pass the ceiling check before either commits, and the shortage ends up over-supplied with
 * two purchases against it — a refusal no index can catch, because a supply has no reversal to
 * collide with.
 */
final class RecordShortageSupply
{
    public function __construct(
        private readonly RecalculateShortageTotals $recalculate,
        // Through the front door, never `OrderItem::query()`. Shortage depends on Order; Order
        // does not know this context exists.
        private readonly OrderService $orders,
        // And the same arrangement with Inventory: one public door, nothing of its internals.
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @throws ShortageIsClosed
     * @throws SupplyExceedsRemaining
     * @throws SupplyNeedsAWarehouse
     * @throws ShortageIsNotStockable
     * @throws SupplyRequiresAnActor
     */
    public function __invoke(
        Shortage $shortage,
        ShortageSupplyData $data,
        ?User $actor = null,
    ): ShortageSupply {
        return DB::transaction(function () use ($shortage, $data, $actor): ShortageSupply {
            $locked = Shortage::query()
                ->whereKey($shortage->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            // Judged on the locked row, never on the one that was bound before the lock: that
            // model's totals are what was true when the request started.
            if ($locked->status === ShortageStatus::Completed) {
                throw ShortageIsClosed::make();
            }

            // **Before the ceiling is even read, because the ceiling is in the wrong unit.** A
            // shortage whose weight nobody has stated is still counted in the unit the customer
            // was billed in — the bags were missing, so there was nothing to weigh — and what is
            // about to be recorded was bought by the kilo. Subtracting one from the other is not
            // arithmetic anybody can do. See the exception, and `OrderItem::shortageWeightIsUnknown()`.
            $this->guardTheUnit($locked);

            $remaining = $locked->remainingQuantity();

            if (bccomp($data->quantity, $remaining, 3) > 0) {
                throw SupplyExceedsRemaining::make($data->quantity, $remaining);
            }

            // **Before the money row, so the row can name it.** A failure here — no stock item
            // behind the size, a warehouse that has been retired — takes the whole transaction
            // with it, which is the point: a purchase recorded without the goods arriving is
            // exactly the state this action exists to make impossible.
            $movement = $this->postArrival($locked, $data, $actor);

            $supply = $locked->supplies()->make();

            $supply->forceFill([
                // Stamped, not fillable: a payload that could set `kind` could write a purchase
                // carrying no money and slip past the CHECK that demands it.
                'kind' => SupplyKind::Purchased,
                // **Already in the shelf's unit**, because that is what a shortage is
                // denominated in — see `OrderLineShortage`. One number reaches the warehouse, the
                // ledger and the cost layer alike; the invoice's share of it is apportioned on
                // the order line and never stored here.
                'quantity' => $data->quantity,
                'amount' => $data->amount,
                'method' => $data->method,
                'reference' => $data->reference,
                'occurred_on' => $data->occurredOn,
                'notes' => $data->notes,
                'warehouse_id' => $movement?->to_warehouse_id,
                'stock_movement_id' => $movement?->getKey(),
                'recorded_by_user_id' => $actor?->getKey(),
            ])->save();

            // **Before the totals are restated.** A shortage that had been abandoned is being
            // chased again the moment something is bought against it, and «مكتمل» — if this entry
            // finishes the job — must win over that. Restating second is what makes it win.
            $reopened = $locked->status->reopensTo();

            if ($reopened !== null) {
                $locked->forceFill(['status' => $reopened])->save();
            }

            ($this->recalculate)($locked->refresh());

            $this->creditTheOrderLine($locked, $data->quantity, $actor);

            return $supply;
        });
    }

    /**
     * Refuses anything at all until the shortage is counted in the unit it will be bought in.
     *
     * **An order-born shortage on a size the warehouse weighs starts in the invoice's unit**, and
     * that is not a defect: «ناقص ٣٠ قطعة» is the only fact that exists when the bags are missing,
     * since goods that do not exist cannot be put on a scale and no catalogue factor converts the
     * count. `OrderService::shortageLinesFor()` sends `pricing_unit` while that is so.
     *
     * A purchase, though, is made and received in the shelf's unit. Recording one against a
     * requirement still expressed in pieces would subtract kilograms from a count of bags — and
     * the result would go on to credit the customer's invoice through step four. So this is the
     * one gate, and it is the first statement inside the lock rather than a check on the form: the
     * weight can be filled in by another screen between a page load and a submit.
     *
     * Manual shortages and same-unit sizes pass straight through; they have only ever had one
     * unit, and `shortageWeightIsUnknown()` is false for both.
     *
     * @throws ShortageWeightIsUnknown
     */
    private function guardTheUnit(Shortage $shortage): void
    {
        if ($shortage->order_item_id === null) {
            return;
        }

        $item = OrderItem::query()->whereKey($shortage->order_item_id)->first();

        if ($item === null || ! $item->shortageWeightIsUnknown()) {
            return;
        }

        throw ShortageWeightIsUnknown::make(
            $item->stockUnit()->label(),
            $item->pricing_unit->label(),
        );
    }

    /**
     * Puts the sacks on a shelf, at what they cost.
     *
     * Null — and no movement at all — for a shortage the warehouse cannot hold. Everything else
     * must name a warehouse: `SupplyNeedsAWarehouse` is not a validation nicety but the thing
     * that stops an order failing a week later with a message about a balance.
     *
     * **The unit cost is derived, never accepted.** `amount ÷ quantity` at six places, rounded to
     * the ledger's three by the DTO — the same direction `PurchaseOrderItem` takes with
     * `base_total_cost`, and for the same reason: a person knows what they handed over, not what
     * one kilo of it worked out at, and asking for the second invites a figure that multiplies
     * back into a different total.
     *
     * @throws SupplyNeedsAWarehouse
     * @throws ShortageIsNotStockable
     * @throws SupplyRequiresAnActor
     */
    private function postArrival(
        Shortage $shortage,
        ShortageSupplyData $data,
        ?User $actor,
    ): ?StockMovement {
        if (! $shortage->isStockable()) {
            // A warehouse offered for something that cannot be stocked is a misunderstanding
            // worth naming, not one to ignore: the caller believes goods are about to move.
            if ($data->warehouseId !== null) {
                throw ShortageIsNotStockable::make();
            }

            return null;
        }

        if ($data->warehouseId === null) {
            throw SupplyNeedsAWarehouse::make();
        }

        if ($actor === null) {
            throw SupplyRequiresAnActor::make();
        }

        $shortage->loadMissing('productVariant');

        return $this->inventory->recordMovement(StockMovementData::shortagePurchase(
            // Through the service, which throws its own named refusal — naming the product — when
            // a size has no shelf behind it. A boolean here could not say which product.
            stockItemId: (int) $this->inventory->stockItemFor($shortage->productVariant)->getKey(),
            warehouseId: $data->warehouseId,
            // **The shortage's own unit is the shelf's unit**, so this posts as it stands. That
            // is the whole reason `shortages.unit` is copied from `OrderItem::stockUnit()` rather
            // than from `pricing_unit`: a supply recorded in the unit the customer was billed in
            // would add a tally of bags to a balance of kilograms.
            quantity: $data->quantity,
            unitCost: bcdiv($data->amount, $data->quantity, 6),
            employeeId: (int) $actor->getKey(),
            // The column's one meaning is «the order this belongs to» — null on a manual
            // shortage, which belongs to none.
            orderId: $shortage->order_id === null ? null : (int) $shortage->order_id,
            notes: 'توفير نقص '.$shortage->code,
        ));
    }

    /**
     * The other lines of the order, written back exactly as they already are.
     *
     * **The set is replaced wholesale**, so every line has to be named or it is cleared — see
     * {@see SetOrderShortages}. Rebuilding each untouched line from its own columns is what makes
     * «اشتريت لبندٍ واحد» leave the other four alone.
     */
    private function asItStands(OrderItem $item): LineShortage
    {
        if ($item->shortage_quantity === null) {
            return LineShortage::none();
        }

        return new LineShortage(
            quantity: (string) $item->shortage_quantity,
            warehouseQuantity: $item->shortage_warehouse_quantity === null
                ? null
                : (string) $item->shortage_warehouse_quantity,
        );
    }

    /**
     * Puts what was bought back on the customer's invoice.
     *
     * Manual shortages skip this entirely — there is no line to credit, and nobody is being
     * billed for the tape somebody bought for the workshop.
     *
     * **Absolute, not a delta.** `setShortages` replaces the whole set and expects what is *still*
     * missing, so the number handed over is the line's own shortage less what just came back —
     * computed here rather than in the caller for the reason `ChangeOrderStatus::remaining()`
     * gives about its own subtraction: so that nobody does it in their head.
     *
     * A line that has been deleted off its order simply is not in the map any more, and
     * `setShortages` writes every line it finds — so a shortage whose line went away credits
     * nothing and throws nothing.
     */
    private function creditTheOrderLine(Shortage $shortage, string $quantity, ?User $actor): void
    {
        if ($shortage->order_id === null || $shortage->order_item_id === null) {
            return;
        }

        $order = Order::withTrashed()->whereKey($shortage->order_id)->first();

        // **An archived order is not re-priced.** Its lines are closed and its money has been
        // reversed; the purchase still stands as an expense — SHORTAGES-DESIGN §٧٫٣ — but there
        // is no live invoice left to put the goods back on.
        if ($order === null || $order->trashed()) {
            return;
        }

        /*
         * **And neither is one whose lines have closed** — «جاهزة» onwards, where the run has been
         * made and the stock has left the warehouse. `SetOrderShortages` refuses those outright,
         * so calling it here would turn «اشتريت ١٠ كجم» into a 422 about order lines: the employee
         * would be refused permission to write down a purchase they have already made, by a rule
         * about a screen they are not on.
         *
         * The purchase is recorded either way and the invoice is left as it stands. That is the
         * right way round — a shortage still open after its order has been dispatched was, by
         * definition, not billed for, and re-billing it after the fact is a decision for whoever
         * talks to the customer rather than a side effect of a purchase being logged.
         */
        if (! $order->itemsAreEditable()) {
            return;
        }

        $shortages = [];

        foreach ($order->items()->get() as $item) {
            // **The arrival is in the shelf's unit, so the line is credited by apportionment.**
            // `$quantity` is what the warehouse received; what comes off the invoice is its share
            // of the pair the shortage was declared with, which is the only bridge between the
            // two units that exists — see {@see OrderItem::creditForStockArrival()}. Exact on a
            // full arrival, which is the ordinary case.
            $shortages[(int) $item->getKey()] = (int) $item->getKey() === $shortage->order_item_id
                ? LineShortage::afterStockArrival($item, $quantity)
                : $this->asItStands($item);
        }

        $this->orders->setShortages($order, $shortages, $actor);
    }
}
