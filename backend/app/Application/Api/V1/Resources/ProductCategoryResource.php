<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ProductCategory
 */
class ProductCategoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'sort_order' => $this->sort_order,

            // How many products sit under this heading. It is what makes the management screen
            // worth opening — and it is the same number that decides whether a delete will be
            // refused, so the screen can say so before the button is pressed.
            'products_count' => $this->whenCounted('products'),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
