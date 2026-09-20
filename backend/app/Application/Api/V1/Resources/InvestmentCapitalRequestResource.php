<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestmentCapitalRequest;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One investor's capital waiting at a boundary — or the record that it no longer is.
 *
 * `applied_entry_id` is what a screen should key «تمّت» off, not the status alone: it is the wallet
 * row this became, and its presence is the only proof the money actually moved.
 *
 * @mixin InvestmentCapitalRequest
 */
class InvestmentCapitalRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investment_pool_id' => (int) $this->investor_deal_id,
            'investor_id' => (int) $this->investor_id,
            'investor' => $this->whenLoaded('investor', fn (): ?array => $this->investor === null ? null : [
                'id' => (int) $this->investor->id,
                'name' => $this->investor->name,
            ]),

            'direction' => $this->direction->value,
            'direction_label' => $this->direction->label(),

            'amount' => (string) $this->amount,

            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'can_be_cancelled' => $this->isCancellable(),

            'requested_at' => $this->requested_at?->toIso8601String(),

            // Null while pending — the period it will join does not exist yet, and naming a row
            // that has not been created would be a promise this cannot keep.
            'effective_period_id' => $this->effective_period_id,
            'applied_entry_id' => $this->applied_entry_id,

            'notes' => $this->notes,
        ];
    }
}
