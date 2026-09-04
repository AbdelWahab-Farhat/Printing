<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin InvestorDeal
 */
class InvestorDealResource extends JsonResource
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

            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'can_be_edited' => $this->status->isEditable(),

            // The investors' share of THIS deal's profit — copied from the company default when
            // the deal was created and frozen when it opened. Published so a screen never has to
            // fetch the setting to explain a number.
            'investor_profit_share_percent' => (string) $this->investor_profit_share_percent,

            'product_id' => $this->product_id,
            'product' => $this->whenLoaded('product', fn (): ?array => $this->product === null ? null : [
                'id' => $this->product->id,
                'name' => $this->product->name,
            ]),

            'opened_on' => $this->opened_on?->toDateString(),
            'opened_at' => $this->opened_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'cancellation_reason' => $this->cancellation_reason,
            'notes' => $this->notes,

            'items' => $this->whenLoaded('items', fn (): array => $this->items->map(fn ($item): array => [
                'id' => $item->id,
                'stock_item_id' => $item->stock_item_id,
                'stock_item' => $item->relationLoaded('stockItem') && $item->stockItem !== null ? [
                    'id' => $item->stockItem->id,
                    'code' => $item->stockItem->code,
                    'display_name' => $item->stockItem->displayName(),
                ] : null,
                'quantity_expected' => $item->quantity_expected === null ? null : (string) $item->quantity_expected,
                'expected_unit_cost' => $item->expected_unit_cost === null ? null : (string) $item->expected_unit_cost,
                'expected_unit_price' => $item->expected_unit_price === null ? null : (string) $item->expected_unit_price,
            ])->all()),

            'investors' => $this->whenLoaded('shares', fn (): array => $this->shares->map(fn ($share): array => [
                'id' => $share->id,
                'investor_id' => $share->investor_id,
                'investor' => $share->relationLoaded('investor') && $share->investor !== null ? [
                    'id' => $share->investor->id,
                    'code' => $share->investor->code,
                    'name' => $share->investor->name,
                ] : null,
                // The pledge, which may legitimately differ from what arrived. The money itself
                // is in `balances` below, and the two are never quietly reconciled.
                'committed_amount' => (string) $share->committed_amount,
                'share_percent' => (string) $share->share_percent,
                'joined_at' => $share->joined_at?->toIso8601String(),
            ])->all()),

            // Capital held and profit earned, per investor and in total — walked from the ledger
            // on the detail screen only.
            'balances' => $this->when(isset($this->balances), fn (): array => $this->balances),
            'stock' => $this->when(isset($this->stock), fn (): array => $this->stock),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
