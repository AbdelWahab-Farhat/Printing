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

            // **Which road this order walks**, so a client can *explain* a five-step bar rather
            // than leaving one that looks truncated. It is not a second copy of the rules —
            // `available_transitions` and `progress` below already have the answers baked in —
            // it is the reason for them, which is the one thing a screen cannot derive from
            // either.
            'production_flow' => $this->production_flow->value,
            'production_flow_label' => $this->production_flow->label(),
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
                        // The signed-in user, because one field depends on them: money may only
                        // be taken by somebody trusted to record it, and the box is withheld
                        // from a driver rather than the move being withheld.
                        TransitionFields::for($this->resource, $target, $request->user()),
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
            // Beside the discount and never folded into it: an order's total is read as «هذا ما
            // أُضيف وهذا ما خُصم», and one net figure explains neither. The reason travels with
            // its label for the same reason `design_source` does — a client that translated the
            // code itself would be keeping a second copy of a list this API owns.
            'additional_cost' => (string) $this->additional_cost,
            'additional_cost_reason' => $this->additional_cost_reason?->value,
            'additional_cost_reason_label' => $this->additional_cost_reason?->label(),
            'additional_cost_note' => $this->additional_cost_note,
            'grand_total' => (string) $this->grand_total,

            // The cost side, null until the order has reached printing — see the order_items
            // migration and DeductOrderStock/ApplyManufacturingRates. `gross_profit` is computed
            // here from the two cached figures beside it, never stored itself.
            'total_cogs' => $this->total_cogs === null ? null : (string) $this->total_cogs,
            'gross_profit' => $this->grossProfit(),

            // **The three numbers a screen puts side by side**, all three computed here. A
            // client subtracting `grand_total - paid_amount` itself would be a second answer to
            // one question, and its answer is the one made of doubles — and since a debt can
            // also be closed by writing it off, that subtraction is no longer even the right
            // one. `remainingAmount()` is.
            //
            // `paid_amount` is the ledger's running total — see the `order_payments` migration
            // for why the entries are the truth and this is their sum. `remaining_amount` goes
            // negative on an overpaid order rather than flooring, so a screen can say «زائد ٥٠»
            // and somebody can refund it.
            'paid_amount' => (string) $this->paid_amount,
            // The fourth number, and usually zero: what was closed without being collected. It
            // stays out of `paid_amount` so that column never stops meaning cash — see
            // OrderPaymentType::WriteOff.
            'written_off_amount' => (string) $this->written_off_amount,
            'remaining_amount' => $this->remainingAmount(),
            'payment_status' => $this->paymentStatus()->value,
            'payment_status_label' => $this->paymentStatus()->label(),

            // **An order that finished without its money accounted for.** Settling an order
            // writes no ledger entry — nothing records a payment except the person who took it —
            // so this is how that gap is surfaced rather than papered over with an entry nobody
            // made. See Order::hasUnrecordedMoney().
            'has_unrecorded_money' => $this->hasUnrecordedMoney(),

            // Null on every settlement that went to plan: the order was settled at its own
            // total. A value here is a discrepancy, deliberately.
            'collected_amount' => $this->collected_amount === null ? null : (string) $this->collected_amount,

            // The snapshot beside the key, like the city's: what the order said carried it,
            // which survives the company being renamed or removed from the list.
            'shipping_company_id' => $this->shipping_company_id,
            'shipping_company' => $this->shipping_company,
            'courier_phone' => $this->courier_phone,
            'tracking_number' => $this->tracking_number,

            // Where this order's stock came out of, and when — both null until the order first
            // enters `printing`. See DeductOrderStock.
            'fulfillment_warehouse_id' => $this->fulfillment_warehouse_id,
            'stock_deducted_at' => $this->stock_deducted_at?->toIso8601String(),

            'placed_at' => $this->placed_at?->toIso8601String(),
            // When the warehouse finished and handed the order to the press — null for every
            // order taken before that step existed, which is the honest answer for them.
            'ready_to_print_at' => $this->ready_to_print_at?->toIso8601String(),
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

            // **The ledger itself is deliberately not here.** It has its own endpoint behind its
            // own permission — `GET /orders/{order}/payments`, `orders.payments.view` — and
            // including the entries in this payload would hand them to everybody holding
            // `orders.view`, which is the printer.
            //
            // The four summary fields above stay, and the line between them is meant: what an
            // order costs and what is outstanding on it are properties of the order, at the same
            // sensitivity as `grand_total`, which this payload has always carried. Who took the
            // money, by what method, against which receipt, and which entries were cancelled —
            // that is the ledger, and it is a different question with a different grant.

            'created_by' => $this->whenLoaded('creator', fn () => $this->creator === null ? null : [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
