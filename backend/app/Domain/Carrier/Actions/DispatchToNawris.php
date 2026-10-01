<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\Exceptions\CityHasNoNawrisMapping;
use App\Domain\Carrier\Exceptions\NawrisRejectedRequest;
use App\Domain\Carrier\Exceptions\OrderAlreadyHasAnOpenParcel;
use App\Domain\Carrier\Exceptions\OrderCannotBeDispatchedToNawris;
use App\Domain\Carrier\Exceptions\OrdersCannotShareAParcel;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Support\NawrisClient;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Hands one order to Nawris — or several sharing one parcel — and records the parcel that came
 * back.
 *
 * **Called from the Application layer after the status change has already committed**, never from
 * inside `ChangeOrderStatus`. Two reasons, and both matter: `Order` must not import `Carrier`
 * (dependencies run one way), and a carrier outage must never roll back a dispatch that
 * physically happened. The parcel is going out either way; whether Nawris has been told is a
 * separate fact — see {@see DispatchToNawris} in NAWRIS-INTEGRATION.md §8.
 *
 * **The API call is made before the transaction, not inside it, and that is a considered
 * departure from the contract's advice.** Wrapping the HTTP call in the transaction would not
 * actually prevent what the contract fears — a shipment at the carrier with no row here — because
 * by the time a rollback happens the call has already succeeded. It would only hold a database
 * transaction open across a network round trip. So the call happens first, the rows are written
 * immediately after in one transaction, and the failure that remains — a successful call whose
 * rows could not be written — is logged loudly with the reference, which is the only thing that
 * makes it recoverable.
 *
 * The mirror failure, a dispatched order that was never lodged, is a *state* rather than an
 * error: the order stands at «جاري التوصيل» with no open parcel, and is retryable.
 */
final class DispatchToNawris
{
    public function __construct(
        private readonly NawrisClient $client,
        private readonly BuildNawrisPayload $payload,
        private readonly ResolveNawrisDestination $destination,
    ) {}

    /**
     * @throws OrderCannotBeDispatchedToNawris
     * @throws CityHasNoNawrisMapping
     * @throws OrderAlreadyHasAnOpenParcel
     * @throws NawrisRejectedRequest
     */
    public function __invoke(Order $order): NawrisParcel
    {
        return $this->send([$order]);
    }

    /**
     * Hands several orders to Nawris as one parcel.
     *
     * **Every order is checked before anything is sent, and one refusal refuses them all.** The
     * group was chosen as a group; lodging the orders that happen to pass and dropping the rest
     * would ship a parcel nobody asked for.
     *
     * **No status moves, here or anywhere in this class.** Lodging a parcel is not the goods
     * leaving — the order stays at «جاهزة» until Nawris reports a courier holding it, and their
     * webhook then moves every order in the parcel together. So a carrier that is down leaves
     * nothing to undo: the orders are exactly where they were, and pressing again is the retry.
     *
     * @param  list<Order>  $orders
     *
     * @throws OrdersCannotShareAParcel
     * @throws OrderCannotBeDispatchedToNawris
     * @throws CityHasNoNawrisMapping
     * @throws OrderAlreadyHasAnOpenParcel
     * @throws NawrisRejectedRequest
     */
    public function group(array $orders): NawrisParcel
    {
        if (count($orders) < 2) {
            throw OrdersCannotShareAParcel::tooFew();
        }

        return $this->send($orders);
    }

    /**
     * @param  list<Order>  $orders
     */
    private function send(array $orders): NawrisParcel
    {
        // By id, so the label reads the same on create, on every edit and on a resend — each of
        // them rebuilds `receiver` from the parcel's orders in this same order.
        usort($orders, fn (Order $a, Order $b): int => $a->getKey() <=> $b->getKey());

        foreach ($orders as $order) {
            $this->guardDeliverable($order);
            $this->guardNotAlreadyOut($order);
        }

        $this->guardOneDoor($orders);

        // The first order speaks for the group: every one of them resolves to the same city and
        // region, which `guardOneDoor` has just made sure of.
        $destination = ($this->destination)($orders[0]);

        $body = $this->payload->forOrders($orders, $destination->government, $destination->area);

        $response = $this->client->addOrder($body);

        $code = $response->code();

        // **Only when a code actually came back.** Their envelope reports logical failures with a
        // 200, so `NawrisClient` has already refused those; this catches the remaining case of a
        // success-shaped answer carrying no identifier, which would leave a parcel row that can
        // never be edited, cancelled or matched to a webhook.
        if ($code === null) {
            throw NawrisRejectedRequest::make('إنشاء الشحنة', 'لم يصل رقم الطرد في الرد');
        }

        return $this->record($orders, $code, $response->barCode(), $destination, $body);
    }

    /**
     * @param  list<Order>  $orders
     * @param  array<string, mixed>  $body
     */
    private function record(
        array $orders,
        string $code,
        ?string $barCode,
        NawrisDestination $destination,
        array $body,
    ): NawrisParcel {
        $amount = $this->payload->amountToCollectFor($orders);

        return DB::transaction(function () use ($orders, $code, $barCode, $destination, $body, $amount): NawrisParcel {
            $parcel = new NawrisParcel;

            // Assigned, never mass-assigned: none of this comes from a request, and a fillable
            // `code` or `amount_to_collect` would let one claim a parcel exists.
            $parcel->forceFill([
                'code' => $code,
                'reference' => (string) $body['remote_order_id'],
                'bar_code' => $barCode,
                'government' => $destination->government,
                'area' => $destination->area,
                'amount_to_collect' => $amount,
                // **Nothing is deducted any more, so this is `0.00` on every new parcel.** The
                // delivery fee left `grand_total` — see `RecalculateOrderTotals` — and the
                // courier bills it to the customer at the door on their own account. The column
                // stays because parcels dispatched under the old arrangement carry a real figure
                // in it, and the settlement that reads it must keep reading theirs correctly.
                'delivery_price_deducted' => '0.00',
                'shipping_company_id' => $destination->shippingCompanyId,
                'dispatched_at' => now(),
            ])->save();

            foreach ($orders as $order) {
                $link = new NawrisParcelOrder;
                $link->forceFill([
                    'nawris_parcel_id' => $parcel->getKey(),
                    'order_id' => $order->getKey(),
                    // **This order's share, not the parcel's figure.** It is what the delivery
                    // webhook pays this order with, so a shared collection lands on each order
                    // as exactly what that order owed — see `ApplyNawrisStatus::settleMoney()`.
                    'amount_to_collect' => $this->payload->amountToCollect($order),
                ])->save();
            }

            return $parcel;
        }, attempts: 3);
    }

    /**
     * One customer, one door, one phone.
     *
     * The parcel is delivered or returned as a whole — Nawris has no partial delivery — so orders
     * that differ on any of these would put one customer's goods at the mercy of another's
     * refusal. The phone is compared as it would be *sent*, so «0912…» and «+218912…» are the same
     * recipient.
     *
     * @param  list<Order>  $orders
     *
     * @throws OrdersCannotShareAParcel
     */
    private function guardOneDoor(array $orders): void
    {
        $first = $orders[0];
        $phone = $this->payload->phone($first);
        $seen = [];

        foreach ($orders as $order) {
            $code = (string) $order->code;

            if (isset($seen[$order->getKey()])) {
                throw OrdersCannotShareAParcel::repeated($code);
            }

            $seen[$order->getKey()] = true;

            if ($order->customer_id !== $first->customer_id) {
                throw OrdersCannotShareAParcel::differentCustomer($code);
            }

            if ($order->city_id !== $first->city_id || $order->region_id !== $first->region_id) {
                throw OrdersCannotShareAParcel::differentDestination($code);
            }

            if ($this->payload->phone($order) !== $phone) {
                throw OrdersCannotShareAParcel::differentPhone($code);
            }
        }
    }

    /**
     * @throws OrderCannotBeDispatchedToNawris
     */
    private function guardDeliverable(Order $order): void
    {
        if ($order->fulfilment_type !== FulfilmentType::Delivery) {
            throw OrderCannotBeDispatchedToNawris::notADelivery((string) $order->code);
        }

        // **"On the road, or one step from it" — asked of the machine rather than listed here.**
        // «جاهزة» is where the button lives and «إعادة إرسال» is the same moment for an order
        // that came back; both are one move from «جاري التوصيل», so the state machine already
        // knows the answer and a hand-written list of statuses could only drift from it. An order
        // already out is included on purpose: that is the retry the not-lodged queue exists for,
        // and refusing it would strip the one screen built to fix a failed hand-over.
        $onTheRoad = $order->status === OrderStatus::OutForDelivery;

        // The column's own default, spelled out: a model built and not refreshed carries no flow
        // yet, and the road this asks about is the standard one in every case but «وسيط».
        $flow = $order->production_flow ?? OrderFlow::Standard;

        if (! $onTheRoad && ! $order->status->canMoveTo(OrderStatus::OutForDelivery, $flow)) {
            throw OrderCannotBeDispatchedToNawris::notOnItsWay(
                (string) $order->code,
                $order->status->label(),
            );
        }
    }

    /**
     * At most one *open* parcel per order.
     *
     * Reads `closed_at` rather than a list of terminal statuses, so a status added later cannot
     * forget to update this rule.
     *
     * @throws OrderAlreadyHasAnOpenParcel
     */
    private function guardNotAlreadyOut(Order $order): void
    {
        $open = NawrisParcel::query()
            ->whereNull('closed_at')
            ->whereHas('links', fn ($q) => $q->where('order_id', $order->getKey()))
            ->first();

        if ($open !== null) {
            throw OrderAlreadyHasAnOpenParcel::make((string) $order->code, $open->code);
        }
    }

    /**
     * A successful call whose rows could not be written.
     *
     * Not reachable from a guard — it is what the transaction failing would mean — and logged
     * with the reference because that string is the only way to find the orphaned shipment at
     * their end afterwards.
     */
    public static function logOrphan(string $reference, string $code): void
    {
        Log::channel('nawris')->error('nawris.orphan', [
            'message' => 'a parcel exists at the carrier with no local row',
            'reference' => $reference,
            'code' => $code,
        ]);
    }
}
