<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Order\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A parcel as Nawris knows it.
 *
 * @mixin NawrisParcel
 */
class NawrisParcelResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'reference' => $this->reference,
            'bar_code' => $this->bar_code,

            'government' => $this->government,
            'area' => $this->area,

            // Strings, never floats: money that a client re-serialises must survive the trip.
            'amount_to_collect' => (string) $this->amount_to_collect,
            'delivery_price_deducted' => (string) $this->delivery_price_deducted,
            'collected_amount' => $this->collected_amount !== null ? (string) $this->collected_amount : null,

            // Their fee and who pays it, as read from the webhook history — null until known.
            // `shipment_on_sender` is in their webhook numbering: 1 the customer, 2 us.
            'carrier_fee' => $this->carrier_fee !== null ? (string) $this->carrier_fee : null,
            'shipment_on_sender' => $this->shipment_on_sender,

            // Their latest door figure from any event, and whether our last change of money
            // reached them — when it did not, the courier is still collecting the old amount.
            'door_amount' => $this->door_amount !== null ? (string) $this->door_amount : null,
            'money_out_of_sync' => $this->moneyOutOfSync(),
            'sync_failed_at' => $this->sync_failed_at?->toIso8601String(),
            'sync_error' => $this->sync_error,

            // Their integer and their prose, both — the mapping is written against the first and
            // support reads the second.
            'remote_status_code' => $this->remote_status_code,
            'remote_status_text' => $this->remote_status_text,

            'is_open' => $this->isOpen(),
            'has_open_conflict' => $this->hasOpenConflict(),
            'conflict_raised_at' => $this->conflict_raised_at?->toIso8601String(),
            'conflict_resolved_at' => $this->conflict_resolved_at?->toIso8601String(),

            'dispatched_at' => $this->dispatched_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),

            // **The orders in it, each with its own share of the COD** — only where they were
            // loaded, which is the shared-parcel endpoint. Absent elsewhere rather than empty: a
            // parcel always holds at least one order, and `[]` would say it held none.
            'orders' => $this->whenLoaded('orders', fn () => $this->orders
                ->sortBy(fn (Order $order): int => (int) $order->getKey())
                ->values()
                ->map(fn (Order $order): array => [
                    'id' => $order->id,
                    'code' => $order->code,
                    'amount_to_collect' => (string) $order->pivot?->getAttribute('amount_to_collect'),
                ])
                ->all()),
        ];
    }
}
