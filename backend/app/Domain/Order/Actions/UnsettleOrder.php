<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\OrderIsNotSettled;
use App\Domain\Order\Exceptions\SettledOrderMustBeUnsettledFirst;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * Takes an order back out of «تم التسوية» to «تم الاستلام», so money on it can be corrected.
 *
 * **Why this exists at all.** Money can come off an order in any status — a payment typed by
 * mistake is reversed, a bounced cheque is refunded, a write-off on the wrong order is undone —
 * and until now nothing stopped that happening under «تم التسوية», leaving an order that said it
 * was settled while it owed. {@see ReverseOrderPayment} and {@see RefundOrderPayment} now refuse
 * that ({@see SettledOrderMustBeUnsettledFirst}), and this is the door they point at.
 *
 * **Why it is not a status transition** — the reasoning {@see ReinstateCancelledOrder} gives for
 * «إلغاء تام» holds word for word. «تم التسوية» stays final on {@see OrderStatus}: `isFinal()`,
 * `allowedNext()` and `ChangeOrderStatus` go on treating it as the end of the line, and this is
 * an undo of one recorded move, not a road on the map. **Its destination is fixed**, because the
 * only move into «تم التسوية» is from «تم الاستلام».
 *
 * **A reason is required**, unlike a reinstatement's optional note. A cancellation undone is a
 * stray tap put right; a settlement undone reopens a record the books treated as closed, which is
 * the bar `ReverseOrderPayment` sets for taking money back.
 *
 * **What it clears and what it leaves.** `settled_at` and `collected_amount` describe the
 * settlement and go with it, as `cancelled_at` goes with a reinstated cancellation. The profit
 * does not move: it was final at «تم الاستلام» and still is — {@see OrderProfitFinalised} fired
 * on the way in and there is nothing for it to say on the way out. The investors' side reads
 * `paid_amount`, never this status, so it answers the payment that follows rather than this move.
 *
 * The timeline gains «تم التسوية → تم الاستلام» with its reason; the settlement stays above it.
 */
final class UnsettleOrder
{
    public function __construct(private readonly RecordStatusTransition $record) {}

    /**
     * @throws OrderIsNotSettled
     */
    public function __invoke(Order $order, string $reason, ?User $actor = null): Order
    {
        return DB::transaction(function () use ($order, $reason, $actor): Order {
            // Under the lock the payment actions take, so a reversal racing this reads either the
            // settled order and is refused, or the delivered one and passes — never half of each.
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status !== OrderStatus::Settled) {
                throw OrderIsNotSettled::make($locked->status);
            }

            $locked->forceFill([
                'status' => OrderStatus::Delivered,
                'settled_at' => null,
                'collected_amount' => null,
            ])->save();

            ($this->record)($locked, OrderStatus::Settled, OrderStatus::Delivered, trim($reason), $actor);

            return $locked->refresh();
        });
    }
}
