<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin WarehouseStock
 */
class WarehouseStockResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'warehouse_id' => $this->warehouse_id,
            'product_variant_id' => $this->product_variant_id,

            // Strings, never numbers. A shelf count is compared against a ledger, and "1250.000"
            // survives a client's JSON parser intact where 1250.0 does not — the same reason
            // cities render their delivery price as a string.
            'quantity' => (string) $this->quantity,
            'low_stock_threshold' => $this->low_stock_threshold !== null
                ? (string) $this->low_stock_threshold
                : null,

            // Computed here rather than left to the client: "is this low" depends on a null
            // threshold meaning "nobody asked", which is exactly the sort of rule four different
            // clients would each get subtly wrong.
            'is_low_stock' => $this->isLowStock(),

            // A snapshot taken when this balance was first created — see ApplyStockChange::increase().
            'unit' => $this->unit->value,
            'unit_label' => $this->unit->label(),

            // Which size this is, and what it belongs to — a storekeeper reads "كيس شحن · 25*35",
            // not an id. Flattened rather than nested because the variant is only ever met
            // through a balance line here, and a client should not have to walk two levels for
            // a label.
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

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
