<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestorWalletEntry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One line of an investor's statement.
 *
 * **The amount is published twice on purpose.** `amount` is what is written in the ledger and is
 * always positive; `signed_amount` is what this row did to whichever balance it moved, which is
 * what a statement column shows. Publishing only the first would make a withdrawal and a deposit
 * look identical; publishing only the second would hide that the ledger stores no signs.
 *
 * @mixin InvestorWalletEntry
 */
class InvestorWalletEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'type' => $this->type->value,
            // Named for the fund when the row sits in it, and a reversal names what it undid.
            'type_label' => $this->label(),
            // Which statement filter this row answers to; a reversal takes its original's.
            'category' => $this->category()?->value,

            'amount' => (string) $this->amount,
            'signed_amount' => $this->signedAmount(),
            // What it did to each of the four balances, so a screen never has to know the rules.
            'deltas' => $this->deltas(),

            'method' => $this->method,
            'reference' => $this->reference,

            'investor_deal_id' => $this->investor_deal_id,
            'deal' => $this->whenLoaded('deal', fn (): ?array => $this->deal === null ? null : [
                'id' => $this->deal->id,
                // No `name`: the column was dropped, and «D25» is the deal's only name now.
                'code' => $this->deal->code,
                'is_fund' => $this->deal->isTheFund(),
            ]),

            'period' => $this->whenLoaded('period', fn (): ?array => $this->period === null ? null : [
                'id' => $this->period->id,
                'code' => $this->period->code,
            ]),

            // A fund subscription's units, or a redemption's — what the money bought or gave up
            // at that day's price. Null for every row that did not touch the fund's units.
            'fund_units' => $this->whenLoaded('fundUnits', fn (): ?array => $this->fundUnits === null ? null : [
                'units' => (string) $this->fundUnits->units,
                'unit_price' => (string) $this->fundUnits->unit_price,
                'locked_until' => $this->fundUnits->locked_until?->toDateString(),
            ]),

            // Where the money came from — an order, an expense. This is «من أين جاء كل دينار»,
            // and it is the reason an earning is one row per source rather than a running delta.
            'source_type' => $this->source_type,
            'source_id' => $this->source_id,

            'reverses_entry_id' => $this->reverses_entry_id,
            'is_reversed' => $this->isReversed(),
            'can_be_reversed' => $this->isReversible(),

            'occurred_at' => $this->occurred_at?->toIso8601String(),
            'notes' => $this->notes,

            'recorded_by' => $this->whenLoaded('recordedBy', fn (): ?array => $this->recordedBy === null ? null : [
                'id' => $this->recordedBy->id,
                'name' => $this->recordedBy->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
