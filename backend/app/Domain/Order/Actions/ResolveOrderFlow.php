<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;

/**
 * Reads which road an order walks off its own lines, and stamps it.
 *
 * The flow twin of {@see ResolveOrderDestination}: a fact about the order the server *derives*
 * rather than accepts, so no request can post `production_flow` and no clerk can put an order on
 * the short road by hand. Both run at intake, and both write a snapshot.
 *
 * **Every line, or none of them.** An order is put on the short road only when all of its lines
 * are goods that are already made. One printed bag among five plain ones means the press really
 * does have to run, and an order that skipped «قيد الطباعة» would be an order claiming work had
 * been done to a line nobody had touched. The rule is deliberately not «any line», which reads as
 * the generous choice and is the one that loses a print job.
 *
 * **A line that cannot prove it skips the press does not get to.** A product with no category —
 * the column is nullable, see PRODUCT-CATEGORIES.md on why — is production work as far as this is
 * concerned. The unknown case takes the road that asks more of the shop, never the one that asks
 * less.
 */
final class ResolveOrderFlow
{
    public function __invoke(Order $order): Order
    {
        // **Only «جديدة», and this is the guard that makes the snapshot true.** Lines stay
        // editable through «قيد التصميم»، «قيد الطباعة» and «نواقص» (see
        // {@see Order::itemsAreEditable()}), so without this an order already at the press could
        // have its last printed line removed and land on a main line with no printing step on
        // it — `mainLinePosition()` would answer null and a perfectly ordinary order would draw
        // itself as a detour, from the status it is actually standing in.
        //
        // Which road an order walks is a decision taken when it is taken. After that it is
        // history, exactly like the city name beside it.
        if ($order->status !== OrderStatus::New) {
            return $order;
        }

        $flow = $this->readFromItems($order);

        if ($order->production_flow === $flow) {
            return $order;
        }

        // `forceFill`, because `production_flow` is deliberately absent from the model's fillable
        // list — a request that could post it could put a printed order on the short road and
        // skip the press on paper.
        $order->forceFill(['production_flow' => $flow])->save();

        return $order;
    }

    /**
     * What the lines say, read once with the whole chain loaded.
     *
     * `parent` is in the eager set because `ProductCategory::skipsProduction()` reads it — a
     * heading's answer reaches the headings under it — and strict mode turns a relation touched
     * cold into an exception rather than a query per line.
     */
    private function readFromItems(Order $order): OrderFlow
    {
        $order->loadMissing('items.product.productCategory.parent');

        // An order with no lines cannot be created (see {@see CreateOrder}), but this is asked
        // before that is guaranteed on every path — and «nothing is printed here» is not a thing
        // an empty order gets to say.
        if ($order->items->isEmpty()) {
            return OrderFlow::Standard;
        }

        $everyLineSkips = $order->items->every(
            fn (OrderItem $item) => $item->product?->productCategory?->skipsProduction() ?? false,
        );

        return $everyLineSkips ? OrderFlow::NoProduction : OrderFlow::Standard;
    }
}
