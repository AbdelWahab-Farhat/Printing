<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\DTOs\StockShortfall;
use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Events\OrderStockDrawn;
use App\Domain\Order\Exceptions\EditedLineNeedsAStockQuantity;
use App\Domain\Order\Exceptions\EditingDrawnLinesRequiresPermission;
use App\Domain\Order\Exceptions\FulfillmentRequiresAnActor;
use App\Domain\Order\Exceptions\FulfillmentWarehouseIsDeleted;
use App\Domain\Order\Exceptions\LineQuantityBelowItsShortage;
use App\Domain\Order\Exceptions\OrderItemsAreLocked;
use App\Domain\Order\Exceptions\OrderLineNotOnOrder;
use App\Domain\Order\Exceptions\OrderNeedsAtLeastOneItem;
use App\Domain\Order\Exceptions\OrderStockShortfall;
use App\Domain\Order\Exceptions\RedrawnOrderLinesAreLocked;
use App\Domain\Order\Exceptions\ScrappedLineCannotBeRemoved;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;
use Illuminate\Database\Eloquent\Collection;

/**
 * Edits an order's lines to match the set that was sent — adding, removing and changing them in
 * place. See Docs/orders/ORDER-LINES-ADD-REMOVE.md.
 *
 * **By line id, not by replacing the set.** A line whose `id` comes back is the same line: it
 * keeps its id, its price, its shortage and — once the stock has left — its draw. Only a line
 * whose quantity changed is priced again, at the new quantity. A line without an id is new; an
 * existing id left out is removed. Replacing the whole set used to throw all of that away on
 * every save: «نواقص» lost what was missing, a «حسب الطلب» line lost its price, and every line
 * was re-priced at today's catalogue whether anybody touched it or not.
 *
 * **Removals go one at a time.** `$order->items()->delete()` would remove the rows and record
 * nothing, leaving a hole in the history exactly where somebody will look for "who took the
 * 25*35 off this order?".
 *
 * **After the stock has left, an edit is a stock movement too** (`stock_deducted_at` set — from
 * «جاهزة للطباعة» to the press). Each changed line goes through {@see RedrawOrderLineStock}: a
 * removed line puts its draw back, a changed one is drawn again at the new figure, an added one
 * draws for the first time. The investors who sold the plain stock are re-posted once at the end
 * through {@see OrderStockDrawn} — **before** the removed lines are deleted, because
 * `PostDealStockPurchases` only sweeps lines that still exist, and a line deleted first would
 * leave its payment standing against goods that are back on the investor's own shelf.
 */
final class SyncOrderItems
{
    public function __construct(
        private readonly AddOrderItem $addItem,
        private readonly RedrawOrderLineStock $redraw,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @param  list<OrderItemData>  $items
     *
     * @throws OrderItemsAreLocked
     * @throws OrderNeedsAtLeastOneItem
     * @throws OrderLineNotOnOrder
     * @throws LineQuantityBelowItsShortage
     * @throws EditingDrawnLinesRequiresPermission
     * @throws RedrawnOrderLinesAreLocked
     * @throws ScrappedLineCannotBeRemoved
     * @throws EditedLineNeedsAStockQuantity
     * @throws OrderStockShortfall
     */
    public function __invoke(Order $order, array $items, ?User $actor = null): Order
    {
        if (! $order->itemsAreEditable()) {
            throw OrderItemsAreLocked::make($order->status);
        }

        if ($items === []) {
            throw OrderNeedsAtLeastOneItem::make();
        }

        /** @var Collection<int, OrderItem> $existing */
        $existing = $order->items()
            ->with(['variant.stockItem', 'product.productCategory.parent'])
            ->get()
            ->keyBy('id');

        foreach ($items as $data) {
            if ($data->id !== null && ! $existing->has($data->id)) {
                throw OrderLineNotOnOrder::make($data->id);
            }
        }

        $kept = array_filter($items, fn (OrderItemData $data): bool => $data->id !== null);
        $added = array_filter($items, fn (OrderItemData $data): bool => $data->id === null);
        $removed = $existing->except(array_map(fn (OrderItemData $data): int => (int) $data->id, $kept))->values();

        $changed = array_filter(
            $kept,
            fn (OrderItemData $data): bool => $this->quantityMoved($existing[$data->id], $data->quantity),
        );

        $movesStock = $order->stock_deducted_at !== null
            && ($added !== [] || $removed->isNotEmpty() || $changed !== [] || $this->weightsMoved($existing, $kept));

        if ($movesStock) {
            $this->guardStockMayMove($order, $existing, $actor);
        }

        $this->guardRemovals($removed);

        foreach ($changed as $data) {
            $this->guardTheShortageFits($existing[$data->id], $data->quantity);
        }

        /** @var array<int, OrderItem> $new keyed by the line's position in the request */
        $new = [];

        foreach ($added as $index => $data) {
            $new[$index] = ($this->addItem)($order, $data)
                ->load(['variant.stockItem', 'product.productCategory.parent']);
        }

        // **Before the kept lines take their new quantities**, because a draw is put back at
        // what the line says it drew — `producedQuantity()` — and that has to be the old figure.
        if ($movesStock) {
            $this->moveStock($order, $existing, $kept, $changed, $new, $removed, $items, (int) $actor?->getKey());
        }

        foreach ($kept as $data) {
            $this->editLine($existing[$data->id], $data);
        }

        $removed->each(fn (OrderItem $item) => $item->delete());

        return $order->load('items');
    }

    /**
     * @throws LineQuantityBelowItsShortage
     */
    private function guardTheShortageFits(OrderItem $item, string $quantity): void
    {
        if ($item->shortage_quantity !== null && bccomp($quantity, (string) $item->shortage_quantity, 3) < 0) {
            throw LineQuantityBelowItsShortage::make((string) $item->variant_label, (string) $item->shortage_quantity);
        }
    }

    /**
     * A kept line's own edit — quantity, price, vendor cost, notes, position — without touching
     * its stock.
     *
     * **Priced again only when its quantity moved**, or when a «حسب الطلب» line was sent a new
     * price. A line nobody touched keeps the price it was taken at, even if the catalogue has
     * moved since: the customer agreed to that figure.
     */
    private function editLine(OrderItem $item, OrderItemData $data): void
    {
        // The line's own product and size, not the request's: a line is the size it was taken
        // as, and swapping it is a removal and an addition, which is what the app sends.
        $data = new OrderItemData(
            productId: (int) $item->product_id,
            productVariantId: (int) $item->product_variant_id,
            quantity: $data->quantity,
            unitPrice: $data->unitPrice,
            notes: $data->notes,
            sortOrder: $data->sortOrder,
            id: $data->id,
            warehouseQuantity: $data->warehouseQuantity,
            unitCost: $data->unitCost,
        );

        $quantityMoved = $this->quantityMoved($item, $data->quantity);

        $priceMoved = $data->unitPrice !== null
            && ! $item->product->hasListedPrices()
            && ($item->unit_price === null || bccomp($data->unitPrice, (string) $item->unit_price, 3) !== 0);

        if ($quantityMoved || $priceMoved) {
            $this->addItem->reprice($item, $data);

            return;
        }

        $item->fill(['notes' => $data->notes, 'sort_order' => $data->sortOrder]);

        // **A new vendor figure on its own is not a reason to price the line again** — the
        // customer's price stays what they agreed. Only a وسيط line takes one; see
        // {@see AddOrderItem}, which applies the same rule when the quantity moved too.
        $costMoved = $data->unitCost !== null
            && $item->productionMode() === ProductionMode::Outsourced
            && ($item->unit_cost === null || bccomp($data->unitCost, (string) $item->unit_cost, 3) !== 0);

        if ($costMoved) {
            $item->forceFill(['unit_cost' => $data->unitCost]);
        }

        if ($item->isDirty()) {
            $item->save();
        }
    }

    /**
     * Refuses a stock-moving edit the order cannot safely take.
     *
     * @param  Collection<int, OrderItem>  $existing
     *
     * @throws EditingDrawnLinesRequiresPermission
     * @throws RedrawnOrderLinesAreLocked
     */
    private function guardStockMayMove(Order $order, Collection $existing, ?User $actor): void
    {
        if ($actor === null) {
            throw FulfillmentRequiresAnActor::make();
        }

        if (! $actor->can(PermissionName::MoveOrderToReadyToPrint->value)) {
            throw EditingDrawnLinesRequiresPermission::make();
        }

        // **A restore drew this order a second time**, beside a first draw the ledger settled —
        // re-posting the lines would correct that settled payment. See the exception.
        if ($order->stock_redrawn_at !== null) {
            throw RedrawnOrderLinesAreLocked::make();
        }

        // **And a reinstated cancellation left its lines pointing at draws already put back.**
        // Redrawing one would reverse a reversed movement — the partial UNIQUE refuses that with
        // a raw 500 — and the order has no stock on it to move in the first place.
        $drawn = $existing->filter(fn (OrderItem $item): bool => $item->fulfillment_stock_movement_id !== null);

        if ($drawn->count() !== $order->linesWithStockStillDrawn()->count()) {
            throw RedrawnOrderLinesAreLocked::make();
        }

        if (! $order->fulfillmentWarehouse()->exists()) {
            throw FulfillmentWarehouseIsDeleted::make((string) $order->code);
        }
    }

    /**
     * @param  Collection<int, OrderItem>  $removed
     *
     * @throws ScrappedLineCannotBeRemoved
     */
    private function guardRemovals(Collection $removed): void
    {
        if ($removed->isEmpty()) {
            return;
        }

        $scrapped = ProductionCostEntry::query()
            ->whereIn('order_item_id', $removed->modelKeys())
            ->where('cost_type', ManufacturingCostType::ScrapLoss)
            ->whereNull('reverses_entry_id')
            ->whereDoesntHave('reversal')
            ->value('order_item_id');

        if ($scrapped !== null) {
            throw ScrappedLineCannotBeRemoved::make((string) $removed->firstWhere('id', $scrapped)?->variant_label);
        }
    }

    /**
     * Moves the stock behind every changed line, then re-posts the investors.
     *
     * **Put back before taking.** Removals first, then lines that shrank, then lines that grew
     * and new ones — so a size swapped for another on the same shelf frees its bags before the
     * new line asks for them. The whole plan is weighed against the shelf first, so a shortfall
     * is refused by name before anything has moved; {@see RedrawOrderLineStock}'s own movement is
     * still the real guard, under its lock.
     *
     * @param  Collection<int, OrderItem>  $existing
     * @param  array<int, OrderItemData>  $kept
     * @param  array<int, OrderItemData>  $changed  the kept lines whose quantity moved
     * @param  array<int, OrderItem>  $new
     * @param  Collection<int, OrderItem>  $removed
     * @param  list<OrderItemData>  $items
     *
     * @throws EditedLineNeedsAStockQuantity
     * @throws OrderStockShortfall
     */
    private function moveStock(
        Order $order,
        Collection $existing,
        array $kept,
        array $changed,
        array $new,
        Collection $removed,
        array $items,
        int $employeeId,
    ): void {
        /** @var list<array{item: OrderItem, figure: string}> $plan */
        $plan = [];

        foreach ($removed as $item) {
            $plan[] = ['item' => $item, 'figure' => '0'];
        }

        foreach ($kept as $index => $data) {
            $figure = $this->stockFigure($existing[$data->id], $index, $data, isset($changed[$index]));

            if ($figure !== null) {
                $plan[] = ['item' => $existing[$data->id], 'figure' => $figure];
            }
        }

        foreach ($new as $index => $item) {
            $plan[] = ['item' => $item, 'figure' => (string) $this->stockFigure($item, $index, $items[$index], true)];
        }

        $this->guardTheShelfCovers($order, $plan);

        // Shrinking draws before growing ones; `usort` is stable, so equal deltas keep their order.
        usort($plan, fn (array $a, array $b): int => bccomp(
            bcsub($a['figure'], $this->drawnNow($a['item']), 3),
            bcsub($b['figure'], $this->drawnNow($b['item']), 3),
            3,
        ));

        foreach ($plan as $step) {
            ($this->redraw)($order, $step['item'], $step['figure'], $employeeId);
        }

        // Once, after every line points at the draw that will stand, and while the removed lines
        // still exist — see the class docblock.
        OrderStockDrawn::dispatch((int) $order->getKey());
    }

    /**
     * What should now leave the shelf for this line, in the shelf's unit — or null when its
     * draw stays as it is.
     *
     * @throws EditedLineNeedsAStockQuantity
     */
    private function stockFigure(OrderItem $item, int $index, OrderItemData $data, bool $quantityMoved): ?string
    {
        // The request's quantity, not the line's: a kept line has not taken its new one yet.
        if (! $item->isStockedInAnotherUnit()) {
            return $quantityMoved ? $data->quantity : null;
        }

        // A weight that came back unchanged is somebody confirming it, not a new figure.
        if ($data->warehouseQuantity !== null
            && bccomp($data->warehouseQuantity, $this->drawnNow($item), 3) !== 0) {
            return $data->warehouseQuantity;
        }

        if ($quantityMoved) {
            throw EditedLineNeedsAStockQuantity::make(
                $index,
                (string) $item->variant_label,
                $item->stockUnit(),
                $item->pricing_unit,
            );
        }

        return null;
    }

    /**
     * Weighs the whole plan against the order's warehouse before anything moves.
     *
     * Per shelf, like {@see DeductOrderStock}: two lines on one pile add up. What the plan puts
     * back counts as available, because it is put back first.
     *
     * @param  list<array{item: OrderItem, figure: string}>  $plan
     *
     * @throws OrderStockShortfall
     */
    private function guardTheShelfCovers(Order $order, array $plan): void
    {
        $shelves = [];
        $returned = [];
        $required = [];

        foreach ($plan as $step) {
            $shelf = $this->inventory->stockItemFor($step['item']->variant);
            $key = (int) $shelf->getKey();

            $shelves[$key] = $shelf;
            $returned[$key] = bcadd($returned[$key] ?? '0', $this->drawnNow($step['item']), 3);
            $required[$key] = bcadd($required[$key] ?? '0', $step['figure'], 3);
        }

        $balances = $this->inventory->balancesFor((int) $order->fulfillment_warehouse_id, array_keys($shelves));

        $shortfalls = [];

        foreach ($shelves as $key => $shelf) {
            $available = bcadd($balances[$key] ?? '0', $returned[$key], 3);

            if (bccomp($available, $required[$key], 3) >= 0) {
                continue;
            }

            $shortfalls[] = new StockShortfall(
                name: $shelf->displayName(),
                available: $available,
                required: $required[$key],
            );
        }

        if ($shortfalls !== []) {
            throw OrderStockShortfall::make($shortfalls, 'items');
        }
    }

    /** What this line has off the shelf right now — nothing for a line that never drew. */
    private function drawnNow(OrderItem $item): string
    {
        return $item->fulfillment_stock_movement_id === null ? '0' : $item->producedQuantity();
    }

    private function quantityMoved(OrderItem $item, string $quantity): bool
    {
        return bccomp((string) $item->quantity, $quantity, 3) !== 0;
    }

    /**
     * Whether any kept line came back with a different shelf figure than it drew — a weight
     * corrected on its own, with the quantity left alone.
     *
     * @param  Collection<int, OrderItem>  $existing
     * @param  array<int, OrderItemData>  $kept
     */
    private function weightsMoved(Collection $existing, array $kept): bool
    {
        foreach ($kept as $data) {
            $item = $existing[$data->id];

            if ($data->warehouseQuantity !== null
                && $item->isStockedInAnotherUnit()
                && bccomp($data->warehouseQuantity, $this->drawnNow($item), 3) !== 0) {
                return true;
            }
        }

        return false;
    }
}
