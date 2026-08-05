<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Order
 */
class OrderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            // What a person says on the phone. Plain digits, unlike the customer's C7 and the
            // product's P7 — an order number is said on its own, so a prefix would be a
            // syllable to spell out for no information.
            'code' => $this->code,

            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            // Two questions, and «تم الاستلام» answers them differently: nothing about the order
            // may be edited any more (`is_closed`), but it still owes its settlement, so it is
            // not finished (`is_final`).
            'is_final' => $this->status->isFinal(),
            'is_closed' => $this->status->isClosed(),

            // **The whole point of gating the app on the server.** The moves this order may
            // make, already narrowed to the ones *this* user may make, so the app draws exactly
            // the buttons that will work instead of keeping its own copy of the rules and
            // offering one the server will refuse.
            //
            // `fields` carries that same idea one step further: what a move *asks for* travels
            // with the move, so the app renders a form it was handed rather than one it wrote,
            // and a new field on a path is a change here alone. See {@see TransitionFields}.
            'available_transitions' => array_map(
                fn (OrderStatus $target) => [
                    'status' => $target->value,
                    'label' => $target->label(),
                    'requires_reason' => $target->requiresReason(),
                    'fields' => array_map(
                        fn (TransitionField $field) => $field->toArray(),
                        TransitionFields::for($this->resource, $target),
                    ),
                ],
                $this->availableTransitionsFor($request->user()),
            ),

            // The journey, in the domain's own order. Shipped with the order for the same
            // reason `available_transitions` is: which status follows which is knowledge this
            // API refuses to let a client keep a second copy of.
            'progress' => $this->progress(),

            // Three different lines, and the app draws each section from the one that governs
            // it rather than keeping its own copy of where they fall. They are deliberately not
            // the same line: a quantity may be corrected while the press runs, the artwork may
            // not, and the address freezes later still.
            'items_are_editable' => $this->itemsAreEditable(),
            'designs_are_editable' => $this->designsAreEditable(),
            'destination_is_editable' => $this->destinationIsEditable(),

            'customer_id' => $this->customer_id,
            'customer' => new CustomerResource($this->whenLoaded('customer')),
            'customer_shop_id' => $this->customer_shop_id,
            // The snapshot, for the same reason city_name is one.
            'customer_shop_name' => $this->customer_shop_name,
            'shop' => new CustomerShopResource($this->whenLoaded('shop')),

            'city_id' => $this->city_id,
            'region_id' => $this->region_id,
            // The snapshot, not the live map: this is what the order said on the day, and it
            // survives the city being renamed or removed.
            'city_name' => $this->city_name,
            'region_name' => $this->region_name,

            'fulfilment_type' => $this->fulfilment_type->value,
            'fulfilment_type_label' => $this->fulfilment_type->label(),
            'is_office_pickup' => $this->fulfilment_type->isOfficePickup(),

            'design_source' => $this->design_source->value,
            'design_source_label' => $this->design_source->label(),

            'recipient_name' => $this->recipient_name,
            'recipient_phone' => $this->recipient_phone,
            'address_details' => $this->address_details,
            'notes' => $this->notes,

            // Strings: money that is summed must reach the client exactly as it was stored.
            'items_total' => (string) $this->items_total,
            'design_fee' => (string) $this->design_fee,
            'delivery_price' => (string) $this->delivery_price,
            'discount' => (string) $this->discount,
            'grand_total' => (string) $this->grand_total,

            // What the parcel weighs, recorded on the way into «جاهزة». Null until it has been
            // on a scale — «not weighed» and «weighs nothing» are different facts.
            'weight_kg' => $this->weight_kg === null ? null : (string) $this->weight_kg,

            // Null on every settlement that went to plan: the order was settled at its own
            // total. A value here is a discrepancy, deliberately.
            'collected_amount' => $this->collected_amount === null ? null : (string) $this->collected_amount,

            'shipping_company' => $this->shipping_company,
            'tracking_number' => $this->tracking_number,
            'courier_name' => $this->courier_name,

            'placed_at' => $this->placed_at?->toIso8601String(),
            'design_started_at' => $this->design_started_at?->toIso8601String(),
            'printing_started_at' => $this->printing_started_at?->toIso8601String(),
            'ready_at' => $this->ready_at?->toIso8601String(),
            'dispatched_at' => $this->dispatched_at?->toIso8601String(),
            'delivered_at' => $this->delivered_at?->toIso8601String(),
            'settled_at' => $this->settled_at?->toIso8601String(),
            'returned_at' => $this->returned_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'cancellation_reason' => $this->cancellation_reason,

            'items_count' => $this->whenCounted('items'),
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'designs' => OrderDesignResource::collection($this->whenLoaded('designs')),
            'transitions' => OrderStatusTransitionResource::collection($this->whenLoaded('transitions')),

            'created_by' => $this->whenLoaded('creator', fn () => $this->creator === null ? null : [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
