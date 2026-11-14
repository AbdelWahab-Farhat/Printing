<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Investor\Actions\PostFundProceedsForOrder;
use App\Domain\Order\Events\OrderDeliveryUndone;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Events\OrderProfitUnwound;
use App\Domain\Order\Events\OrderStockRedrawn;
use App\Domain\Order\OrderService;

/**
 * Pays the fund back for a compensation order's goods when it is delivered, and takes that back
 * when the delivery is undone or the order is archived.
 *
 * **Compensation orders only.** An ordinary order's fund cash follows its payments
 * ({@see PostFundProceedsWhenPaymentsMove}); a compensation order has none, so its cash follows
 * delivery instead (ORDER-COMPENSATION.md §5). Asking first keeps every ordinary order's
 * behaviour exactly as it was. Synchronous, inside the transaction that moved the status, like
 * its siblings.
 */
final class PostCompensationCoverWhenDeliveryMoves
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly PostFundProceedsForOrder $post,
    ) {}

    /**
     * `OrderStockRedrawn` is the restore of an archived order: its goods leave the shelf again,
     * and a delivered compensation must pay the fund for them again.
     */
    public function handle(OrderProfitFinalised|OrderDeliveryUndone|OrderProfitUnwound|OrderStockRedrawn $event): void
    {
        if ($this->orders->isCompensation($event->orderId)) {
            ($this->post)($event->orderId);
        }
    }
}
