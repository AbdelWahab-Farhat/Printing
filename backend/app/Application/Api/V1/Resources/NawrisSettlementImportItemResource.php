<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\Models\NawrisSettlementImportItem;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * سطر من دفعة نُفّذت.
 *
 * @mixin NawrisSettlementImportItem
 */
class NawrisSettlementImportItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'row_number' => $this->row_number,
            'raw_status' => $this->raw_status,
            'raw_code' => $this->raw_code,
            'raw_receiver' => $this->raw_receiver,
            'order_id' => $this->order_id,
            'order_code' => $this->order_code,
            'previous_status' => $this->previous_status,
            'previous_status_label' => $this->previous_status === null
                ? null
                : OrderStatus::tryFrom($this->previous_status)?->label(),
            'outcome' => $this->outcome->value,
            'outcome_label' => $this->outcome->label(),
            'reason_code' => $this->reason_code,
            'reason' => $this->reason,
            'warnings' => $this->warnings ?? [],
            'held_amount' => (string) $this->held_amount,
            'fee_amount' => (string) $this->fee_amount,
        ];
    }
}
