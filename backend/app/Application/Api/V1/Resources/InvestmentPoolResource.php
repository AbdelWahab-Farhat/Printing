<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Support\MinimumTerm;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A صندوق as a screen needs it.
 *
 * **Deliberately narrower than {@see InvestorDealResource}.** Every frozen column that resource
 * publishes — `company_stake`, `investor_funded_percent`, `purchase_order_id`,
 * `printing_sale_price` — is meaningless on a pool: the company's stake is now its capital weight
 * and is recomputed at each close, there is no one purchase order, and سعر السادة is agreed per
 * lorry. Publishing them as nulls would invite a screen to draw a field that will never fill.
 *
 * **No money here either, and that is not an omission.** Capital, deployable cash and unsettled
 * profit arrive with their own slices; a resource that guessed at them before the ledger could
 * answer would be a number somebody trusts.
 *
 * @mixin InvestorDeal
 */
class InvestmentPoolResource extends JsonResource
{
    /**
     * One partner's weight in the pool as it stands now, as a percentage string.
     *
     * Zero when the pool holds no capital at all — which is every pool on the day it opens, and a
     * division nobody should be asked to perform.
     */
    private function weightOf(int $investorId): string
    {
        $total = (string) ($this->poolCapital ?? '0.00');

        if (bccomp($total, '0', 2) <= 0) {
            return '0.0000';
        }

        $his = (string) ($this->memberCapital[$investorId]['capital'] ?? '0.00');

        return number_format((float) bcdiv(bcmul($his, '100', 8), $total, 8), 4, '.', '');
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,

            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),

            // The investors' share of this pool's period profit — copied from the company default
            // when the pool was opened and never re-read for it, so editing the default cannot
            // re-cut a pool anybody is already in.
            'investor_profit_share_percent' => (string) $this->investor_profit_share_percent,

            // The shelves this pool owns. Each belongs to no other pool — a database guarantee,
            // not a convention — so a screen may treat this as the complete answer to «what does
            // this pool buy?».
            'stock_items' => $this->whenLoaded('poolItems', fn (): array => $this->poolItems
                ->map(fn ($item): array => [
                    'stock_item_id' => (int) $item->stock_item_id,
                    'name' => $item->stockItem?->displayName(),
                ])
                ->values()
                ->all()),

            'investors' => $this->whenLoaded('shares', fn (): array => $this->shares
                ->map(fn ($share): array => [
                    'investor_id' => (int) $share->investor_id,
                    'name' => $share->investor?->name,
                    'joined_at' => $share->joined_at?->toIso8601String(),
                    // **When his capital may be asked back**, or null when it already may.
                    //
                    // Null covers the three cases a screen treats the same way — no minimum is
                    // set, he holds nothing here, and the term has already run — because in all
                    // three there is nothing to tell him. Computed by the same function that then
                    // refuses an early exit, so the date shown and the date enforced are one.
                    'is_company' => (bool) ($share->investor?->is_company ?? false),
                    // **What he actually has in here**, walked from the ledger — not the
                    // `committed_amount` beside it, which is a pledge and which nothing in any
                    // profit or capital computation reads. A roster without amounts answers «من
                    // معنا؟» and leaves «بكم؟» to a second screen.
                    'capital' => $this->memberCapital[(int) $share->investor_id]['capital'] ?? '0.00',
                    // **His weight as it stands today**, derived on this read and stored nowhere.
                    //
                    // Not the same thing as the figure on a closed period: this moves whenever
                    // anybody's capital moves, and it is what the next close *would* use if it
                    // happened now. What he was actually paid last month is frozen on that period
                    // and read from `investment-periods/{id}/shares`.
                    'share_percent' => $this->weightOf((int) $share->investor_id),
                    // Null for the company, which the term does not bind — it is the operator,
                    // not a partner who might take a month's profit and leave. Same answer the
                    // action gives, so the screen cannot promise a date the server ignores.
                    'capital_free_on' => ($share->investor?->is_company ?? false)
                        ? null
                        : MinimumTerm::freeOn(
                            (int) $share->investor_id,
                            (int) $this->id,
                            $this->minimumTermMonths ?? 0,
                        )?->toDateString(),
                ])
                ->values()
                ->all()),

            // **What an investor must be told before he commits money** — when the window shuts,
            // and the day his money would actually start working if he pressed the button now.
            // Computed by the same function the action then obeys, so the promise and the
            // behaviour cannot disagree. See GraceWindow.
            'capital_timing' => $this->when(
                isset($this->capitalTiming),
                fn (): array => $this->capitalTiming,
            ),

            'opened_on' => $this->opened_on?->toDateString(),
            'notes' => $this->notes,

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
