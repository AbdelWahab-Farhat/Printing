<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Catalog\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Product
 */
class ProductResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'name' => $this->name,
            'description' => $this->description,
            'features' => $this->features ?? [],

            // Each enum ships its value *and* its Arabic label, so the app never has to keep its
            // own translation table in step with the backend's.
            'category' => $this->category->value,
            'category_label' => $this->category->label(),
            'pricing_unit' => $this->pricing_unit->value,
            'pricing_unit_label' => $this->pricing_unit->label(),
            'pricing_mode' => $this->pricing_mode->value,
            'pricing_mode_label' => $this->pricing_mode->label(),

            // Tells the client whether to render a price or a "request a quote" button, without
            // it having to interpret the enum itself.
            'has_listed_prices' => $this->pricing_mode->hasListedPrices(),

            'min_order_quantity' => (string) $this->min_order_quantity,
            'is_active' => $this->is_active,
            'sort_order' => $this->sort_order,

            'variants' => ProductVariantResource::collection($this->whenLoaded('variants')),
            'images' => ProductImageResource::collection($this->whenLoaded('images')),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
