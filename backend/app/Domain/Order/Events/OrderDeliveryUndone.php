<?php

declare(strict_types=1);

namespace App\Domain\Order\Events;

use App\Domain\Order\Actions\UndoOrderDelivery;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A delivery was recorded by mistake and has been taken back — the profit it made final is not
 * final any more.
 *
 * **The counterpart of {@see OrderProfitFinalised}**, for the one road that walks an order back
 * out of «تم الاستلام». Not {@see OrderProfitUnwound}: that one means the order left the books,
 * and a listener of it closes the order's shortages; this order is still very much alive and will
 * be delivered again. Investment reverses the earnings the delivery posted, and posts them afresh
 * when {@see OrderProfitFinalised} fires on the next delivery.
 *
 * Dispatched inside {@see UndoOrderDelivery}'s transaction, so the order going back and the
 * earnings coming off are one atomic fact.
 */
final readonly class OrderDeliveryUndone
{
    use Dispatchable;

    public function __construct(public int $orderId) {}
}
