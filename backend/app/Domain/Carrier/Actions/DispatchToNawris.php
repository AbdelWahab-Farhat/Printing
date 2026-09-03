<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\Exceptions\CityHasNoNawrisMapping;
use App\Domain\Carrier\Exceptions\NawrisRejectedRequest;
use App\Domain\Carrier\Exceptions\OrderAlreadyHasAnOpenParcel;
use App\Domain\Carrier\Exceptions\OrderCannotBeDispatchedToNawris;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Support\NawrisClient;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Hands one order to Nawris and records the parcel that came back.
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
        $this->guardDeliverable($order);
        $this->guardNotAlreadyOut($order);

        $destination = ($this->destination)($order);

        $body = $this->payload->forOrder($order, $destination->government, $destination->area);

        $response = $this->client->addOrder($body);

        $code = $response->code();

        // **Only when a code actually came back.** Their envelope reports logical failures with a
        // 200, so `NawrisClient` has already refused those; this catches the remaining case of a
        // success-shaped answer carrying no identifier, which would leave a parcel row that can
        // never be edited, cancelled or matched to a webhook.
        if ($code === null) {
            throw NawrisRejectedRequest::make('إنشاء الشحنة', 'لم يصل رقم الطرد في الرد');
        }

        return $this->record($order, $code, $response->barCode(), $destination, $body);
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function record(
        Order $order,
        string $code,
        ?string $barCode,
        NawrisDestination $destination,
        array $body,
    ): NawrisParcel {
        $amount = $this->payload->amountToCollect($order);

        return DB::transaction(function () use ($order, $code, $barCode, $destination, $body, $amount): NawrisParcel {
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
                // Frozen here so the returning figure stays explicable after a tariff change.
                'delivery_price_deducted' => (string) $order->delivery_price,
                'shipping_company_id' => $destination->shippingCompanyId,
                'dispatched_at' => now(),
            ])->save();

            $link = new NawrisParcelOrder;
            $link->forceFill([
                'nawris_parcel_id' => $parcel->getKey(),
                'order_id' => $order->getKey(),
                // This order's share. Equal to the parcel's own figure while one order is one
                // parcel; recorded anyway, because splitting a consolidated collection back
                // across orders is unrecoverable if it was never written down.
                'amount_to_collect' => $amount,
            ])->save();

            return $parcel;
        }, attempts: 3);
    }

    /**
     * @throws OrderCannotBeDispatchedToNawris
     */
    private function guardDeliverable(Order $order): void
    {
        if ($order->fulfilment_type !== FulfilmentType::Delivery) {
            throw OrderCannotBeDispatchedToNawris::notADelivery((string) $order->code);
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
