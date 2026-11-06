<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\Models\NawrisSettlementImport;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * دفعة نُفّذت. `items` في التفاصيل وحدها.
 *
 * @mixin NawrisSettlementImport
 */
class NawrisSettlementImportResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'file_name' => $this->file_name,
            'imported_by' => $this->whenLoaded('importer', fn () => [
                'id' => $this->importer->id,
                'name' => $this->importer->name,
            ]),
            'summary' => [
                'rows_count' => $this->rows_count,
                'orders_count' => $this->orders_count,
                'settled_count' => $this->settled_count,
                'skipped_count' => $this->skipped_count,
                'rejected_count' => $this->rejected_count,
                'left_out_count' => $this->left_out_count,
                'warnings_count' => $this->warnings_count,
            ],
            'total_held' => (string) $this->total_held,
            'received_amount' => (string) $this->received_amount,
            'fee_total' => (string) $this->fee_total,
            'difference_reason' => $this->difference_reason,
            'created_at' => $this->created_at?->toIso8601String(),
            'items' => NawrisSettlementImportItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
