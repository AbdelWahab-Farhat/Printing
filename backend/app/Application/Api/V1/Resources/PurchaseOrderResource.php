<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PurchaseOrder
 */
class PurchaseOrderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'vendor_id' => $this->vendor_id,
            'vendor' => $this->whenLoaded('vendor', fn (): array => [
                'id' => $this->vendor->id,
                'name' => $this->vendor->name,
            ]),

            'warehouse_id' => $this->warehouse_id,
            'warehouse' => $this->whenLoaded(
                'warehouse',
                fn (): ?array => $this->warehouse === null ? null : [
                    'id' => $this->warehouse->id,
                    'name' => $this->warehouse->name,
                ],
            ),

            'status' => $this->status->value,
            'status_label' => $this->status->label(),

            'order_date' => $this->order_date?->toDateString(),
            'expected_date' => $this->expected_date?->toDateString(),
            'notes' => $this->notes,

            // Null on an order raised before cost tracking existed — see RecalculatePurchaseOrderTotal.
            // Already inclusive of total_additional_cost: each line's final_total_cost (summed
            // into this figure) already carries its allocated share.
            'total_amount' => $this->total_amount !== null ? (string) $this->total_amount : null,
            'total_additional_cost' => $this->total_additional_cost !== null ? (string) $this->total_additional_cost : null,

            // The deals financing this order, each with the lines it claims and the partners in
            // it — the money each put in beside the percentage it produced. Present on the single
            // order only, and an empty list on the ordinary one the company paid for itself.
            // `isset` rather than a read: strict mode throws on an attribute that was never
            // set, and this one is attached by the show endpoint alone — the list never carries
            // it. Same shape as `InvestorDealResource::$balances`.
            'investor_funding' => $this->when(
                isset($this->investor_funding),
                fn (): array => $this->investor_funding,
            ),

            // The share a deal struck on this order would be born with — the company default,
            // published so the funding screen can show it rather than imply it.
            'default_investor_profit_share_percent' => $this->when(
                isset($this->default_investor_profit_share_percent),
                fn (): string => $this->default_investor_profit_share_percent,
            ),

            'items' => PurchaseOrderItemResource::collection($this->whenLoaded('items')),
            'additional_costs' => PurchaseOrderAdditionalCostResource::collection($this->whenLoaded('additionalCosts')),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
