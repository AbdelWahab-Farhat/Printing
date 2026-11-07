<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\PurchaseOrder\Models\PurchaseOrderCostRefund;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PurchaseOrderCostRefund
 */
class PurchaseOrderCostRefundResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'amount' => (string) $this->amount,
            'reason' => $this->reason,
            'recorded_by_name' => $this->whenLoaded('recorder', fn (): ?string => $this->recorder?->name),
            'created_at' => $this->created_at?->toIso8601String(),
            'is_reversed' => $this->isReversed(),
            'reversal_reason' => $this->reversal_reason,
        ];
    }
}
