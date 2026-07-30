<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Catalog\Models\ProductVariant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ProductVariant
 */
class ProductVariantResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'label' => $this->label,
            'width_cm' => $this->width_cm,
            'height_cm' => $this->height_cm,
            'is_active' => $this->is_active,
            'sort_order' => $this->sort_order,
            'price_tiers' => ProductPriceTierResource::collection($this->whenLoaded('priceTiers')),
        ];
    }
}
