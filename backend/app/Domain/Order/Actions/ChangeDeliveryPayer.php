<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Exceptions\DeliveryPayerCannotChange;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * «التوصيل على: المستلم / علينا» — on one order, and nothing about the carrier.
 *
 * **Telling the carrier is the caller's half**, the way a payment's is: Orders does not know a
 * carrier exists. The API changes every order of a shared Nawris parcel through this, then sends
 * the parcel's edit once — see `OrderController::changeDeliveryPayer()`. A flip that Nawris made
 * on their side comes back through here too, from the webhook, with nothing to send.
 *
 * **The money is worked out again in the same transaction** when the cost moved: the order's
 * profit, the investors' share of it once delivered, and the fund's cash from it — the road
 * `UpdateOrder::reworkTheMoney()` takes for a late discount, for the same reason.
 */
final class ChangeDeliveryPayer
{
    public function __construct(
        private readonly RecalculateDeliveryCost $recalculateCost,
        private readonly RecalculateOrderPayments $recalculatePayments,
    ) {}

    /**
     * @throws DeliveryPayerCannotChange
     */
    public function __invoke(Order $order, DeliveryPayer $payer): Order
    {
        return DB::transaction(function () use ($order, $payer): Order {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->delivery_paid_by === $payer) {
                return $locked;
            }

            if (! $locked->deliveryPayerIsEditable()) {
                throw DeliveryPayerCannotChange::make($locked->status);
            }

            $locked->forceFill(['delivery_paid_by' => $payer])->save();

            if (($this->recalculateCost)($locked)) {
                OrderProfitFinalised::dispatch((int) $locked->getKey());

                ($this->recalculatePayments)($locked);
            }

            return $locked->refresh();
        });
    }
}
