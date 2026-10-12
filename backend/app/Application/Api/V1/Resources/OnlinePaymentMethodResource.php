<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One EzonePay method as the shop set it: on or off, and its limits per customer.
 *
 * @mixin OnlinePaymentMethod
 */
class OnlinePaymentMethodResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'method' => $this->method->value,
            'label' => $this->method->label(),
            'flow' => $this->method->flow()->value,
            'is_active' => (bool) $this->is_active,
            'daily_limit' => $this->daily_limit === null ? null : (string) $this->daily_limit,
            'monthly_limit' => $this->monthly_limit === null ? null : (string) $this->monthly_limit,
            'yearly_limit' => $this->yearly_limit === null ? null : (string) $this->yearly_limit,
        ];
    }
}
