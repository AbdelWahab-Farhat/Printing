<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Investor\InvestorService;
use App\Domain\Order\Events\OrderStockReturned;

/**
 * A cancelled order gave its material back — ask whether it is still usable.
 *
 * The listener half of the one-way dependency: Orders announces, Investment listens, and Orders goes
 * on knowing nothing about pools. Synchronous on purpose, inside the transaction that cancelled the
 * order, so the goods and the question about them land together or not at all.
 *
 * Does nothing at all for the ordinary cancellation — one with no printed line drawing unpriced
 * pool material, which is most of them.
 */
final class AskAboutReturnedGoods
{
    public function __construct(private readonly InvestorService $investors) {}

    public function handle(OrderStockReturned $event): void
    {
        $this->investors->askAboutReturnedGoods($event->orderId);
    }
}
