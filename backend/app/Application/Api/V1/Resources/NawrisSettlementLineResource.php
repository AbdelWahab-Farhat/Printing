<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\DTOs\NawrisSettlementLine;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * سطر من المعاينة. بشكل {@see NawrisSettlementImportItemResource} نفسه: الشاشة ترسمهما بعنصر واحد.
 *
 * @mixin NawrisSettlementLine
 */
class NawrisSettlementLineResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'row_number' => $this->row->number,
            'raw_status' => $this->row->status,
            'raw_code' => $this->row->code,
            'raw_receiver' => $this->row->receiver,
            'order_id' => $this->orderId,
            'order_code' => $this->orderCode,
            'previous_status' => $this->previousStatus?->value,
            'previous_status_label' => $this->previousStatus?->label(),
            'outcome' => $this->outcome->value,
            'outcome_label' => $this->outcome->label(),
            'reason_code' => $this->rejection?->value,
            'reason' => $this->reason,
            'warnings' => array_map(fn (array $warning): array => [
                'code' => $warning['code']->value,
                'message' => $warning['message'],
            ], $this->warnings),
            'held_amount' => $this->heldAmount,
            'fee_amount' => $this->knownFee,
        ];
    }
}
