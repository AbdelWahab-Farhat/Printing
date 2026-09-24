<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Investor\InvestorService;
use App\Domain\Order\Events\OrderDeliveryUndone;

/**
 * Takes back the profit a mistaken delivery credited to the deals that financed its stock.
 *
 * **Synchronous, never queued** — the bargain {@see UnwindEarningsWhenOrderIsDeleted} makes: it
 * runs inside the transaction `UndoOrderDelivery` opened, so the order goes back and the earnings
 * come off together or not at all. The next delivery posts them again through
 * {@see PostEarningsWhenOrderIsFinalised}.
 */
final class UnwindEarningsWhenDeliveryIsUndone
{
    public function __construct(private readonly InvestorService $investors) {}

    public function handle(OrderDeliveryUndone $event): void
    {
        $this->investors->unwindEarningsForUndoneDelivery($event->orderId);
    }
}
