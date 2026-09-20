<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Models\InvestmentSettlement;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\SettlementSnapshot;
use Illuminate\Support\Facades\DB;

/**
 * Freezes a pool's position and signs it.
 *
 * **Nothing moves.** No wallet row, no stock movement, no period touched — a settlement is a review
 * and an approval, and a pool trades on through it exactly as before. That is the whole difference
 * between this and {@see CloseInvestmentPeriod}, which is an irreversible payout.
 *
 * ## Why the figures are written down at all
 *
 * Every one of them can be derived on demand, and the screens do derive them. Writing them here is
 * a **historical record**, not a cache: what somebody approved in March has to still read in
 * March's terms in December, after six more lorries have arrived and the shelf has turned over
 * twice. The same standing `investment_periods` gives its close columns.
 *
 * ## The drift is not corrected here, and must not be
 *
 * If the two derivations disagree, the difference is written down and left standing. There is a
 * strong pull towards posting an adjustment that makes it zero — and that would destroy the only
 * thing this table is for. A drift is a question about the goods on a shelf; it is answered by
 * somebody going and looking, not by a ledger row that makes the question stop being asked.
 */
final class RecordSettlement
{
    public function __construct(private readonly SettlementSnapshot $snapshot) {}

    public function __invoke(
        InvestorDeal $pool,
        ?string $settledOn = null,
        ?int $approvedBy = null,
        ?string $notes = null,
        ?int $actorId = null,
    ): InvestmentSettlement {
        return DB::transaction(function () use ($pool, $settledOn, $approvedBy, $notes, $actorId): InvestmentSettlement {
            // Locked for the read, not because anything here writes to the pool, but because the
            // snapshot walks eight tables and a lorry received halfway through would be counted on
            // one side of the identity and not the other — reported as a drift that never existed.
            $locked = InvestorDeal::query()->whereKey($pool->getKey())->lockForUpdate()->firstOrFail();

            $figures = ($this->snapshot)((int) $locked->getKey());

            $settlement = new InvestmentSettlement;
            $settlement->investor_deal_id = $locked->getKey();
            $settlement->period_from_id = $figures['period_from_id'];
            $settlement->period_to_id = $figures['period_to_id'];
            $settlement->settled_on = $settledOn ?? now()->toDateString();
            $settlement->approved_by = $approvedBy;

            $settlement->total_capital = $figures['total_capital'];
            $settlement->investor_capital = $figures['investor_capital'];
            $settlement->company_capital = $figures['company_capital'];
            $settlement->deployable_cash = $figures['deployable_cash'];
            $settlement->stock_at_cost = $figures['stock_at_cost'];
            $settlement->undeployed_current_profit = $figures['undeployed_current_profit'];
            $settlement->receivables = $figures['receivables'];
            $settlement->liabilities = $figures['liabilities'];
            $settlement->distributed_profit_to_date = $figures['distributed_profit_to_date'];
            $settlement->damage_to_date = $figures['damage_to_date'];
            $settlement->shortage_to_date = $figures['shortage_to_date'];
            $settlement->reconstructed_cash = $figures['reconstructed_cash'];
            $settlement->drift = $figures['drift'];

            $settlement->notes = $notes;
            $settlement->created_by = $actorId;
            $settlement->save();

            return $settlement;
        });
    }
}
