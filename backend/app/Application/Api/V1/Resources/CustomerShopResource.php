<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Customer\Models\CustomerShop;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin CustomerShop
 */
class CustomerShopResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            // Numbers, not strings — a map SDK can use these directly. Null only for shops
            // recorded before coordinates were introduced.
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'page_url' => $this->page_url,

            // The id for a form to preselect, and the whole field for a screen to render —
            // sending the id alone would make every client fetch the list to translate one
            // number. Null for a shop recorded without a trade, which is most of the old ones.
            'business_field_id' => $this->business_field_id,
            'business_field' => $this->whenLoaded(
                'businessField',
                fn () => new BusinessFieldResource($this->businessField),
            ),
        ];
    }
}
