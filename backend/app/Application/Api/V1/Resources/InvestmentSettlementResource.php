<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestmentSettlement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One signed statement of where a pool's money was on a day.
 *
 * **`drift` and `has_drift` are what a screen leads with.** Everything else here can be read off
 * the pool's live figures at any time; the drift is the only thing that could not, because it is a
 * comparison of two derivations that never consult each other — and a screen that buries it under
 * eleven reassuring totals is a screen that turns a finding into decoration.
 *
 * @mixin InvestmentSettlement
 */
class InvestmentSettlementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'investment_pool_id' => (int) $this->investor_deal_id,

            'period_from_id' => $this->period_from_id,
            'period_to_id' => $this->period_to_id,
            'settled_on' => $this->settled_on?->toDateString(),

            'approved_by' => $this->approved_by,
            'approved_by_name' => $this->whenLoaded('approvedBy', fn (): ?string => $this->approvedBy?->name),

            'total_capital' => (string) $this->total_capital,
            'investor_capital' => (string) $this->investor_capital,
            'company_capital' => (string) $this->company_capital,

            'deployable_cash' => (string) $this->deployable_cash,
            'stock_at_cost' => (string) $this->stock_at_cost,
            // Real money, and deliberately never added to `deployable_cash` here. The two are
            // printed side by side and never as a total — the same rule the pool's own screen
            // follows for undrawn profit.
            'undeployed_current_profit' => (string) $this->undeployed_current_profit,

            'receivables' => (string) $this->receivables,
            'liabilities' => (string) $this->liabilities,

            'distributed_profit_to_date' => (string) $this->distributed_profit_to_date,
            'damage_to_date' => (string) $this->damage_to_date,
            'shortage_to_date' => (string) $this->shortage_to_date,

            'reconstructed_cash' => (string) $this->reconstructed_cash,
            'drift' => (string) $this->drift,
            'has_drift' => $this->hasDrift(),

            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
