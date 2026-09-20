<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Catalog\CatalogService;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Exceptions\StockItemBelongsToAnotherPool;
use App\Domain\Investor\Exceptions\StockItemIsNotInvestable;
use App\Domain\Investor\Models\InvestmentPoolItem;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Support\Facades\DB;

/**
 * Replaces the set of shelves a pool owns.
 *
 * Two gates, and they are asked in this order because the cheaper refusal should come first:
 *
 * 1. **May this shelf be invested in at all?** Asked through Catalog's own door, never by
 *    reaching for a product model — and the question is «every active product on this shelf is
 *    investable», not «any of them is». A shelf shared with a product outside the investable
 *    headings would have the investor's money financing goods sold at another product's margin,
 *    and FIFO cannot tell the two apart.
 * 2. **Is it already owned by a different pool?** The database refuses this with a unique index;
 *    asking here first turns a constraint violation into a sentence that names the pool already
 *    holding the shelf.
 *
 * **Every check runs before the first write.** A pool that refused its fourth shelf must not be
 * left owning the first three — the same discipline `FundPurchaseOrder` applies to its funders.
 *
 * **Detaching is a soft delete, and re-attaching elsewhere is then legal.** The unique index is
 * partial on `deleted_at`, so a shelf that genuinely moves house leaves a row behind saying it was
 * once here. What that does *not* do is move the stock: the cost layers already on the shelf keep
 * the pool id they were opened with, for ever, because they are what that pool's investors paid
 * for. Detaching decides where the *next* lorry goes, and nothing else.
 */
final class SyncPoolItems
{
    public function __construct(
        private readonly CatalogService $catalog,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @param  list<int>  $stockItemIds
     *
     * @throws StockItemIsNotInvestable
     * @throws StockItemBelongsToAnotherPool
     */
    public function __invoke(InvestorDeal $pool, array $stockItemIds, ?int $actorId = null): InvestorDeal
    {
        $wanted = array_values(array_unique(array_map('intval', $stockItemIds)));

        $this->guard($pool, $wanted);

        return DB::transaction(function () use ($pool, $wanted, $actorId): InvestorDeal {
            foreach ($pool->poolItems()->get() as $existing) {
                if (! in_array((int) $existing->stock_item_id, $wanted, true)) {
                    $existing->delete();
                }
            }

            foreach ($wanted as $stockItemId) {
                $row = $pool->poolItems()->where('stock_item_id', $stockItemId)->first();

                if ($row !== null) {
                    continue;
                }

                // Not `firstOrCreate(['stock_item_id' => …])`: both columns are deliberately not
                // fillable — which shelf a pool owns is this action's to decide and never a
                // payload's — so a mass assignment would be refused outright under strict mode.
                $row = $pool->poolItems()->make();
                $row->stock_item_id = $stockItemId;
                $row->created_by = $actorId;
                $row->save();
            }

            return $pool->load('poolItems.stockItem');
        });
    }

    /**
     * Every refusal, before any write.
     *
     * @param  list<int>  $stockItemIds
     *
     * @throws StockItemIsNotInvestable
     * @throws StockItemBelongsToAnotherPool
     */
    private function guard(InvestorDeal $pool, array $stockItemIds): void
    {
        foreach ($stockItemIds as $stockItemId) {
            $verdict = $this->catalog->stockItemInvestability($stockItemId);

            if (! $verdict['investable']) {
                throw StockItemIsNotInvestable::make(
                    $verdict['offending_product']
                        ?? $this->inventory->findStockItem($stockItemId)->displayName()
                );
            }

            $owner = InvestmentPoolItem::query()
                ->with('pool')
                ->where('stock_item_id', $stockItemId)
                ->where('investor_deal_id', '<>', $pool->getKey())
                ->first();

            if ($owner !== null) {
                throw StockItemBelongsToAnotherPool::make(
                    $this->inventory->findStockItem($stockItemId)->displayName(),
                    (string) ($owner->pool?->name ?? $owner->pool?->code ?? ''),
                );
            }
        }
    }
}
