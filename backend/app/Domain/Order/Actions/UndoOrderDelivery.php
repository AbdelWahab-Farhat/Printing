<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderDeliveryUndone;
use App\Domain\Order\Exceptions\DeliveryCannotBeUndone;
use App\Domain\Order\Exceptions\OrderIsNotDelivered;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * Takes an order back out of «تم الاستلام» to the status it was delivered from, for a delivery
 * recorded by mistake.
 *
 * **Not a status transition**, for the reasons {@see ReinstateCancelledOrder} gives. «تم الاستلام»
 * keeps its one road forward on {@see OrderStatus}; this is an undo of one recorded move, and
 * **its destination is read from the timeline, never chosen** — «جاري التوصيل», «استلام مكتب» or
 * «راجع مكتب», whichever the order actually came from.
 *
 * **What comes off with it.** `delivered_at`, which describes the delivery. And the investors'
 * profit: the delivery is what made it final ({@see OrderProfitFinalised}), so
 * {@see OrderDeliveryUndone} tells Investment to reverse it — in the order's own period while
 * that still takes entries, in the open one once it has closed — and the next delivery posts it
 * afresh. The order also counts as out of the building again, so a period waiting on its orders
 * waits for this one too.
 *
 * **What stays.** Money taken at the door stays on the ledger: the cash was really handed over,
 * and whoever decides it was not reverses that entry where it was made. Stock does not move — the
 * bags are with the courier or on the counter either way.
 *
 * **What it refuses.** An order in «تم التسوية» — the settlement comes off first
 * ({@see UnsettleOrder}). A partial delivery — the invoice shrank and bags went back to a shelf,
 * which a button should not quietly redo. A delivery the carrier reported is refused one layer up,
 * in the controller, because Orders may not know that a carrier exists.
 */
final class UndoOrderDelivery
{
    public function __construct(private readonly RecordStatusTransition $record) {}

    /**
     * @throws OrderIsNotDelivered
     * @throws DeliveryCannotBeUndone
     */
    public function __invoke(Order $order, string $reason, ?User $actor = null): Order
    {
        return DB::transaction(function () use ($order, $reason, $actor): Order {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status !== OrderStatus::Delivered) {
                throw OrderIsNotDelivered::make($locked->status);
            }

            if ($locked->wasDeliveredPartly()) {
                throw DeliveryCannotBeUndone::becauseItWasPartial();
            }

            $target = $locked->statusBeforeDelivery();

            if ($target === null) {
                throw DeliveryCannotBeUndone::becauseTheTimelineIsSilent();
            }

            $locked->forceFill([
                'status' => $target,
                'delivered_at' => null,
            ])->save();

            ($this->record)($locked, OrderStatus::Delivered, $target, trim($reason), $actor);

            OrderDeliveryUndone::dispatch((int) $locked->getKey());

            return $locked->refresh();
        });
    }
}
