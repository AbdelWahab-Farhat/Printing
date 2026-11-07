<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\DTOs\NawrisSettlementPreview;
use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Order\DTOs\TransitionField;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * ما ستفعله الدفعة، قبل أن تُفعل.
 *
 * @mixin NawrisSettlementPreview
 */
class NawrisSettlementPreviewResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'summary' => [
                'rows_count' => $this->rowsCount,
                'orders_count' => count($this->lines),
                'settled_count' => $this->count(NawrisSettlementOutcome::Settled),
                'skipped_count' => $this->count(NawrisSettlementOutcome::AlreadySettled),
                'rejected_count' => $this->count(NawrisSettlementOutcome::Rejected),
                'warnings_count' => $this->warningsCount(),
            ],
            // ما عند النورس للطلبيات التي ستُسوّى وحدها — لا لكل الملف.
            'total_held' => $this->totalHeld(),
            'known_fees' => $this->knownFees(),
            // ما تفتح به خانة «المبلغ المستلم».
            'expected_received' => $this->expectedReceived(),
            // يُعاد مع «تنفيذ»: إن تغيّر شيء منذ هذه المعاينة رُفض التنفيذ.
            'fingerprint' => $this->fingerprint(),
            // الحسابات التي تسألها شاشة «تم التسوية» عن هذه الطلبيات، بشكل حقول الحركة نفسه.
            'fields' => array_map(fn (TransitionField $field): array => $field->toArray(), $this->fields),
            'lines' => NawrisSettlementLineResource::collection($this->lines),
        ];
    }
}
