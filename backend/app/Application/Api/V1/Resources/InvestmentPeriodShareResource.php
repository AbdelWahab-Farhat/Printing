<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestmentPeriodShare;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * What one participant's capital was worth in one closed period, and what he was paid for it.
 *
 * **Frozen the day the period closed, and never recomputed.** This is the answer to «لماذا أخذت
 * هذا المبلغ في سبتمبر؟» — asked in December, after three more months of capital moving, when the
 * live weights on the pool's screen bear no relation to the ones that were applied. Deriving it
 * again from today's ledger would answer a different question.
 *
 * `share_percent` on the company's row is 100 of its own side, which is what it is: the figure
 * that means something for the company is `net_share`, because its take is the residual of the
 * division rather than a slice of the investors' half.
 *
 * @mixin InvestmentPeriodShare
 */
class InvestmentPeriodShareResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investment_period_id' => (int) $this->investment_period_id,

            'investor_id' => (int) $this->investor_id,
            'investor_name' => $this->whenLoaded('investor', fn (): ?string => $this->investor?->name),
            'is_company' => (bool) $this->is_company,

            /** What he had in the pool when the period closed. */
            'capital' => (string) $this->capital,

            /** His weight of the investors' half, as applied. */
            'share_percent' => (string) $this->share_percent,

            /** What the division actually gave him — negative in a losing period. */
            'net_share' => (string) $this->net_share,
        ];
    }
}
