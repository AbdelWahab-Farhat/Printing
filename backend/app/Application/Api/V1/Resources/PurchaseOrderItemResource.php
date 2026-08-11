<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PurchaseOrderItem
 */
class PurchaseOrderItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'product_variant_id' => $this->product_variant_id,
            'product_variant' => $this->whenLoaded('productVariant', fn (): array => [
                'id' => $this->productVariant->id,
                'label' => $this->productVariant->label,
                'product_id' => $this->productVariant->product_id,
                'product_code' => $this->productVariant->product->code,
                'product_name' => $this->productVariant->product->name,
            ]),

            // Always positive — see StockArrivalItemResource for the same shape.
            'quantity_ordered' => (string) $this->quantity_ordered,
            'quantity_received' => (string) $this->quantity_received,

            // Derived rather than trusted from either column alone, so a client never has to
            // subtract two decimal strings itself.
            'quantity_remaining' => (string) bcsub(
                (string) $this->quantity_ordered,
                (string) $this->quantity_received,
                3,
            ),

            // Null only on a line written before cost tracking existed.
            'unit_cost' => $this->unit_cost !== null ? (string) $this->unit_cost : null,
            'total_cost' => $this->total_cost !== null ? (string) $this->total_cost : null,

            'unit' => $this->unit?->value,
            'unit_label' => $this->unit?->label(),
        ];
    }
}
