<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Order\Models\OrderItem;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin OrderItem
 */
class OrderItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            // The keys are here for opening the live catalogue entry; the names beside them are
            // the snapshot, and they are what an old order must display.
            'product_id' => $this->product_id,
            'product_variant_id' => $this->product_variant_id,
            'product_name' => $this->product_name,
            'variant_label' => $this->variant_label,

            // What is missing from this line, in this line's own unit. Null until somebody has
            // counted, which is not the same as nothing being missing.
            'shortage_quantity' => $this->shortage_quantity === null
                ? null
                : (string) $this->shortage_quantity,

            'pricing_unit' => $this->pricing_unit->value,
            'pricing_unit_label' => $this->pricing_unit->label(),

            // Strings, never numbers: "1.100" survives a client's JSON parser as the price the
            // catalogue printed, where 1.1 has already stopped being it.
            'quantity' => (string) $this->quantity,
            'unit_price' => (string) $this->unit_price,
            'line_total' => (string) $this->line_total,

            'notes' => $this->notes,
            'sort_order' => $this->sort_order,

            // Null unless the employee said the sales unit and the warehouse unit differ — see
            // the class docblock on OrderItem.
            'warehouse_quantity' => $this->warehouse_quantity === null ? null : (string) $this->warehouse_quantity,

            // What this line cost to produce, on the accrual side that mirrors `line_total` on
            // the revenue side — every one of the four null until the line has actually reached
            // printing. See DeductOrderStock and ApplyManufacturingRates.
            'material_cost' => $this->material_cost === null ? null : (string) $this->material_cost,
            'labor_cost' => $this->labor_cost === null ? null : (string) $this->labor_cost,
            'overhead_cost' => $this->overhead_cost === null ? null : (string) $this->overhead_cost,
            'cogs' => $this->cogs === null ? null : (string) $this->cogs,
        ];
    }
}
