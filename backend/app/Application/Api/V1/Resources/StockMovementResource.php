<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Inventory\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin StockMovement
 */
class StockMovementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'movement_type' => $this->movement_type->value,
            'movement_type_label' => $this->movement_type->label(),

            // Always positive. Which of the two warehouse fields is null is what says whether
            // this added or removed — see the migration for the four shapes.
            'quantity' => (string) $this->quantity,

            'product_variant_id' => $this->product_variant_id,
            'product_variant' => $this->whenLoaded('productVariant', fn (): array => [
                'id' => $this->productVariant->id,
                'label' => $this->productVariant->label,
                'product_id' => $this->productVariant->product_id,
                // The code, because it is what staff say out loud — «عندك P7؟» — and the one
                // thing on this row that is safe to read down a phone line. Free: the product
                // is already loaded for its name.
                'product_code' => $this->productVariant->product->code,
                'product_name' => $this->productVariant->product->name,
            ]),

            'from_warehouse_id' => $this->from_warehouse_id,
            'from_warehouse' => $this->whenLoaded(
                'fromWarehouse',
                fn (): ?array => $this->fromWarehouse === null ? null : [
                    'id' => $this->fromWarehouse->id,
                    'name' => $this->fromWarehouse->name,
                ],
            ),

            'to_warehouse_id' => $this->to_warehouse_id,
            'to_warehouse' => $this->whenLoaded(
                'toWarehouse',
                fn (): ?array => $this->toWarehouse === null ? null : [
                    'id' => $this->toWarehouse->id,
                    'name' => $this->toWarehouse->name,
                ],
            ),

            // The order this belongs to, once Orders lands. Null on everything today.
            'reference_id' => $this->reference_id,

            'employee_id' => $this->employee_id,
            'employee' => $this->whenLoaded('employee', fn (): array => [
                'id' => $this->employee->id,
                'name' => $this->employee->name,
                'employee_code' => $this->employee->employee_code,
            ]),

            'notes' => $this->notes,

            // No `updated_at`: a ledger entry is never updated, so publishing one would only
            // invite a client to believe it could be.
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
