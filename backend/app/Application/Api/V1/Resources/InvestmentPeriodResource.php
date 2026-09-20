<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One accounting period.
 *
 * **The snapshot is published only when it exists.** An open period has no net profit, no closing
 * cash and no applied percentages — those are written at the close — so they come back as null
 * rather than as zeros. A zero is a figure somebody will draw; a null is a screen that knows not to.
 *
 * @mixin InvestmentPeriod
 */
class InvestmentPeriodResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investment_pool_id' => (int) $this->investor_deal_id,

            'starts_on' => $this->starts_on?->toDateString(),
            'ends_on' => $this->ends_on?->toDateString(),

            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'is_open' => $this->isOpen(),

            // **Reported, never enforced.** A period past its end goes on accruing correctly; what
            // stops being true is only that its dates describe its contents. Nothing here closes
            // anything — see InvestmentPeriod::isOverdue().
            'is_overdue' => $this->isOverdue(),
            'days_overdue' => $this->daysOverdue(),

            // What would refuse the close if somebody pressed it now. Attached by the controller
            // for the open period alone: the question is asked of the **pool**, not the period, so
            // answering it per row would be one query per period on a pool with a year of them.
            'blocked_by_returned_goods' => (bool) ($this->blockedByReturnedGoods ?? false),

            'closed_at' => $this->closed_at?->toIso8601String(),

            // Written once, at the close. Null on an open period, always.
            'snapshot' => $this->status->acceptsActivity() ? null : [
                'opening_cash' => (string) $this->opening_cash,
                'closing_cash' => (string) $this->closing_cash,
                'opening_stock_cost' => (string) $this->opening_stock_cost,
                'closing_stock_cost' => (string) $this->closing_stock_cost,
                'realized_margin' => (string) $this->realized_margin,
                'deductible_expenses' => (string) $this->deductible_expenses,
                'damage_cost' => (string) $this->damage_cost,
                'shortage_cost' => (string) $this->shortage_cost,
                'net_profit' => (string) $this->net_profit,
                'investor_share_percent_applied' => (string) $this->investor_share_percent_applied,
                'investor_capital_weight_applied' => (string) $this->investor_capital_weight_applied,
                'total_pool_capital' => (string) $this->total_pool_capital,
                'total_investor_capital' => (string) $this->total_investor_capital,
            ],

            'notes' => $this->notes,
        ];
    }
}
