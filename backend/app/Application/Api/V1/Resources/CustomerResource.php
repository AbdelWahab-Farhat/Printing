<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Customer\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Customer
 */
class CustomerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'phone' => $this->phone,
            'is_active' => $this->is_active,
            // whenLoaded keeps this resource honest: a caller that forgot to eager-load gets
            // no `shops` key rather than a silent query per row.
            'shops' => CustomerShopResource::collection($this->whenLoaded('shops')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
