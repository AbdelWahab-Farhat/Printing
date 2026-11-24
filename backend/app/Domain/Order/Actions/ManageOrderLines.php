<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\ManagedOrderLine;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Events\OrderShortagesRecorded;
use App\Domain\Order\Exceptions\OrderLineNotOnOrder;
use App\Domain\Order\Exceptions\OrderLinesAreNotManageable;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * «إدارة الطلبية»: a line's quantity and its price, for a holder of `orders.edit_fully`, in every
 * status {@see Order::linesAreManageable()} opens (owner's decision, 2026-11-24).
 *
 * **Nothing else moves.** No line is added or removed, and the address, discount, notes and every
 * other field are not part of the request at all. The owner opens further fields one at a time;
 * each is a deliberate addition here, never a lock lifted wholesale.
 *
 * **The quantity goes through SyncOrderItems**, so a line whose stock has already left the shelf
 * is re-drawn exactly as the ordinary edit would re-draw it, with every stock guard standing. The
 * grant stands in only for the two drawn-line grants that edit asks.
 *
 * **The price is the one typed**, for a product with listed prices too: SyncOrderItems writes it
 * as sent in this mode and never asks the catalogue, so a quantity outside every tier is not a
 * refusal either.
 */
final class ManageOrderLines
{
    public function __construct(
        private readonly SyncOrderItems $syncItems,
        private readonly RecalculateOrderTotals $recalculate,
    ) {}

    /**
     * @param  list<ManagedOrderLine>  $lines  only the lines the screen sent; any other line on
     *                                         the order is left exactly as it is
     *
     * @throws OrderLinesAreNotManageable
     * @throws OrderLineNotOnOrder
     */
    public function __invoke(Order $order, array $lines, User $actor): Order
    {
        $updated = DB::transaction(function () use ($order, $lines, $actor): Order {
            // The lock UpdateOrder and ChangeOrderStatus take first, for the same reason: this
            // can move stock, and so can a status move, and the two must not interleave.
            Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();
            $order->refresh();

            // Asked on the locked row, so a delivery or cancellation that landed while the screen
            // was open is refused rather than edited around.
            if (! $order->linesAreManageable()) {
                throw OrderLinesAreNotManageable::make($order->status);
            }

            /** @var Collection<int, OrderItem> $existing */
            $existing = $order->items()->get()->keyBy('id');

            $sent = [];

            foreach ($lines as $line) {
                if (! $existing->has($line->id)) {
                    throw OrderLineNotOnOrder::make($line->id);
                }

                $sent[$line->id] = $line;
            }

            // Every line goes to SyncOrderItems, because a line it is not sent is a line it
            // removes. The ones this screen did not mention go back exactly as they stand.
            $items = $existing
                ->map(fn (OrderItem $item): OrderItemData => new OrderItemData(
                    productId: (int) $item->product_id,
                    productVariantId: (int) $item->product_variant_id,
                    quantity: isset($sent[$item->id]) ? $sent[$item->id]->quantity : (string) $item->quantity,
                    unitPrice: $sent[$item->id]->unitPrice ?? null,
                    notes: $item->notes,
                    sortOrder: (int) $item->sort_order,
                    id: (int) $item->id,
                    warehouseQuantity: $sent[$item->id]->warehouseQuantity ?? null,
                ))
                ->values()
                ->all();

            // `managing` writes each kept line's quantity and price as sent, never from the
            // catalogue, and answers the drawn-stock grant question with `orders.edit_fully`.
            ($this->syncItems)($order, $items, $actor, managing: true);

            return ($this->recalculate)($order->load('items'))->refresh();
        });

        // **After the commit, as UpdateOrder does.** On an order parked on «نواقص» the shortage
        // rows mirror the lines, and a changed quantity is the listener's to mirror.
        if ($updated->status === OrderStatus::Shortage) {
            OrderShortagesRecorded::dispatch(
                (int) $updated->getKey(),
                ShortageRevision::Corrected,
                (int) $actor->getKey(),
            );
        }

        return $updated;
    }
}
