<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Vendor\Models\StockArrival;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StockArrival
 */
class StockArrivalResource extends JsonResource
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

            // Which purchase order this shipment was fulfilling, if any — most arrivals are
            // unplanned and this is null. A plain scalar, not a nested object: the order itself
            // is read through GET /purchase-orders/{purchase_order}, the same way order_id
            // works everywhere else in this API.
            'purchase_order_id' => $this->purchase_order_id,

            'warehouse_id' => $this->warehouse_id,
            'warehouse' => $this->whenLoaded(
                'warehouse',
                fn (): ?array => $this->warehouse === null ? null : [
                    'id' => $this->warehouse->id,
                    'name' => $this->warehouse->name,
                ],
            ),

            'invoice_number' => $this->invoice_number,
            'notes' => $this->notes,

            'received_by' => $this->received_by,
            'received_by_user' => $this->whenLoaded('receivedByUser', fn (): array => [
                'id' => $this->receivedByUser->id,
                'name' => $this->receivedByUser->name,
            ]),

            'items' => StockArrivalItemResource::collection($this->whenLoaded('items')),

            // No `updated_at`: an arrival is never updated, so publishing one would only invite
            // a client to believe it could be.
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
