<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\DTOs\PoolData;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Facades\DB;

/**
 * Opens a صندوق: a continuous pool for one material.
 *
 * **It is born open, and it is born empty.** There is no draft state to leave, because there are
 * no terms to review before the money arrives — a deal froze its partners and percentages at the
 * moment of opening and a pool never freezes them at all, recomputing ownership from capital at
 * every close. And there is no capital here: money arrives later, gated by the grace window, and
 * the first period is what gives it somewhere to land.
 *
 * `status` is `Open` for the whole of a pool's life. The state machine that moves a deal through
 * draft → open → closed simply does not apply: what closes is the **period**, and a pool with no
 * stock left is a pool between lorries, not a finished one.
 *
 * **The profit share is copied from the company default now and never read from there again**, the
 * same rule `CreateInvestorDeal` follows and for the same reason: the men putting money in were
 * shown a number, and editing the default next year must not re-cut a pool they are already in.
 *
 * **Its first accounting period opens with it.** A pool with no period cannot accept capital — the
 * grace window would have no boundary to measure against — so «born empty» must not also mean
 * «born unable to receive anything».
 */
final class CreatePool
{
    public function __construct(
        private readonly SettingsService $settings,
        private readonly SyncPoolItems $syncItems,
        private readonly OpenInvestmentPeriod $openPeriod,
    ) {}

    public function __invoke(PoolData $data, ?int $actorId): InvestorDeal
    {
        return DB::transaction(function () use ($data, $actorId): InvestorDeal {
            $pool = new InvestorDeal([
                'name' => $data->name,
                'opened_on' => now()->toDateString(),
                'notes' => $data->notes,
            ]);

            $pool->kind = PoolKind::Pool;
            $pool->status = DealStatus::Open;
            $pool->opened_at = now();
            $pool->investor_profit_share_percent = $data->investorProfitSharePercent
                ?? $this->settings->investorProfitSharePercent();
            $pool->created_by = $actorId;
            $pool->save();

            ($this->syncItems)($pool, $data->stockItemIds, $actorId);

            // **Its first period, opened in the same breath.** A pool with no period cannot take
            // capital at all — the grace window has no boundary to measure today against, so there
            // is no honest answer to give an investor before he commits. Born empty is the
            // intention; born unable to receive anything is not.
            ($this->openPeriod)($pool);

            return $pool->load('poolItems.stockItem');
        });
    }
}
