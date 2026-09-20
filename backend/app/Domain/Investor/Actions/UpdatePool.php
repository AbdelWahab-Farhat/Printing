<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\DTOs\PoolData;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Support\Facades\DB;

/**
 * Renames a pool and changes which shelves it owns.
 *
 * **`investor_profit_share_percent` is deliberately not editable here.** It is the term the
 * partners were shown, and a pool that could be re-cut mid-life would be re-cutting periods
 * already closed and paid against — the exact thing the settings/snapshot split exists to prevent.
 * Renegotiating a live pool is a decision the business makes, and it will need its own act with
 * its own audit line; it is not an edit slipped into a rename.
 *
 * **Changing the shelves does not move any stock.** Cost layers keep the pool id they were opened
 * with for ever, because they are what that pool's investors paid for. Detaching a shelf decides
 * where the *next* lorry goes and nothing else, which is why it is safe to do while a period is
 * open.
 */
final class UpdatePool
{
    public function __construct(private readonly SyncPoolItems $syncItems) {}

    public function __invoke(InvestorDeal $pool, PoolData $data, ?int $actorId): InvestorDeal
    {
        return DB::transaction(function () use ($pool, $data, $actorId): InvestorDeal {
            $pool->fill([
                'name' => $data->name,
                'notes' => $data->notes,
            ]);
            $pool->save();

            ($this->syncItems)($pool, $data->stockItemIds, $actorId);

            return $pool->load('poolItems.stockItem');
        });
    }
}
