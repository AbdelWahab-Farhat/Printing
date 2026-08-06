<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Vendor\Models\StockArrivalItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StockArrivalItem
 */
class StockArrivalItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            // Always positive — see StockMovementResource for the same shape.
            'quantity' => (string) $this->quantity,

            'product_variant_id' => $this->product_variant_id,
            'product_variant' => $this->whenLoaded('productVariant', fn (): array => [
                'id' => $this->productVariant->id,
                'label' => $this->productVariant->label,
                'product_id' => $this->productVariant->product_id,
                'product_code' => $this->productVariant->product->code,
                'product_name' => $this->productVariant->product->name,
            ]),

            // The ledger row this line produced.
            'stock_movement_id' => $this->stock_movement_id,
        ];
    }
}
