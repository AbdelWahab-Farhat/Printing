<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\NawrisParcelTerms;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Support\NawrisClient;
use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * Tells Nawris the COD changed.
 *
 * **Money is the only thing that can change on a live parcel, so this has exactly one trigger.**
 * `Order::destinationIsEditable()` is false at «جاري التوصيل», so the address and the recipient's
 * phone are frozen by our own domain for precisely the window a parcel is out — and `receiver` is
 * the order code rather than a person's name, so even a name change alters nothing we would send.
 * What is left is a deposit, an installment or a write-off recorded after dispatch — and, since
 * 2026-11-13, who pays the courier's fee, which the order says and every edit repeats.
 *
 * **The destination is replayed off the parcel, never re-derived.** An edit carrying a different
 * area moves the parcel; re-reading the city at edit time is how that happens by accident.
 *
 * **The payload is rebuilt whole.** A field left out is left *untouched* at their end rather than
 * cleared, so a partial edit is a silent no-op dressed as an instruction.
 *
 * **Rebuilt from the parcel, not from the order that triggered it.** A payment on one order of a
 * shared parcel changes that order's share and nothing else, but the edit still sends every
 * order: an edit built from the triggering order alone would rewrite the parcel as if its
 * siblings did not exist, and Nawris would collect one order's money for three orders' goods.
 */
final class EditNawrisParcel
{
    public function __construct(
        private readonly NawrisClient $client,
        private readonly BuildNawrisPayload $payload,
    ) {}

    public function __invoke(NawrisParcel $parcel): NawrisParcel
    {
        // Fresh rather than `loadMissing`: the caller's parcel may have been loaded before the
        // payment that triggered this, and the whole point is the figures as they stand now.
        $parcel->load('orders');

        // By id — the order dispatch sent them in, so `receiver` replays unchanged.
        $orders = $parcel->orders->sortBy(fn (Order $order): int => (int) $order->getKey())->values()->all();

        if ($orders === [] || $parcel->code === null) {
            return $parcel;
        }

        $payer = $this->payerFor($parcel, $orders);

        $body = $this->payload->forOrders(
            $orders,
            $parcel->government,
            $parcel->area,
            $parcel->code,
            NawrisParcelTerms::apiValueFor($payer),
        );

        // The reference never changes: changing it detaches the shipment from this record.
        $body['remote_order_id'] = $parcel->reference;

        $this->client->editOrder($body);

        // They took it, so who pays is now what we sent — kept with its moment, because their
        // webhook for our own edit may or may not say so. See ReadNawrisParcelTerms.
        if ($payer !== null) {
            $parcel->forceFill([
                'payer_sent' => $payer,
                'payer_sent_at' => now(),
                'shipment_on_sender' => $payer,
            ])->save();
        }

        return $this->recordAccepted($parcel);
    }

    /**
     * Who pays their fee, in their webhook numbering: **what the orders say** (DELIVERY-PAYER.md).
     *
     * **Except once every order has been delivered** — the fee was paid at the door by whoever
     * paid it, our answer can no longer change, and a late edit (a payment typed after delivery)
     * must not re-open the question. Then the parcel's own last value is replayed, as before.
     *
     * @param  list<Order>  $orders
     */
    private function payerFor(NawrisParcel $parcel, array $orders): ?int
    {
        $open = array_filter($orders, fn (Order $order): bool => $order->deliveryPayerIsEditable());

        if ($open === []) {
            return $parcel->shipment_on_sender;
        }

        $first = array_values($open)[0];

        return NawrisParcelTerms::webhookValueFor($first->delivery_paid_by ?? DeliveryPayer::Recipient);
    }

    /**
     * What Nawris now holds, written on our side: the parcel's figure, each order's share, and an
     * older refusal put right.
     *
     * After a successful edit — and when their webhook shows someone at Nawris corrected the amount
     * by hand to exactly what we would have sent, which is the same fact arrived by another road.
     */
    public function recordAccepted(NawrisParcel $parcel): NawrisParcel
    {
        $parcel->load('orders');

        $orders = $parcel->orders->sortBy(fn (Order $order): int => (int) $order->getKey())->values()->all();

        if ($orders === []) {
            return $parcel;
        }

        $amount = $this->payload->amountToCollectFor($orders);

        return DB::transaction(function () use ($parcel, $orders, $amount): NawrisParcel {
            // Rewritten on every successful edit, so what we believe they are collecting stays
            // what we actually asked for.
            $parcel->forceFill([
                'amount_to_collect' => $amount,
                'sync_failed_at' => null,
                'sync_error' => null,
            ])->save();

            // Each order's own share, one row at a time: a mass update fires no model events, and
            // every row here is audited.
            foreach ($orders as $order) {
                $parcel->links()
                    ->where('order_id', $order->getKey())
                    ->get()
                    ->each(fn (NawrisParcelOrder $link) => $link->forceFill([
                        'amount_to_collect' => $this->payload->amountToCollect($order),
                    ])->save());
            }

            return $parcel;
        }, attempts: 3);
    }
}
