<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\DTOs\PoolPurchaseData;
use App\Domain\Investor\DTOs\PoolPurchaseLineData;
use App\Domain\Investor\Exceptions\PoolCannotAffordThePurchase;
use App\Domain\Investor\Exceptions\PurchaseOrderCannotBeFunded;
use App\Domain\Investor\Exceptions\StockItemHasNoPool;
use App\Domain\Investor\Models\InvestmentPoolItem;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Queries\PoolDeployableCash;
use App\Domain\PurchaseOrder\Queries\FundingSnapshotQuery;
use Illuminate\Support\Facades\DB;

/**
 * «هذه البنود تُشترى من مال الصندوق» — declared before the lorry arrives.
 *
 * ## What replaced what
 *
 * This is the half of `FundPurchaseOrder` that survives. That action did four things at once: it
 * created a deal, took the partners' money, froze their percentages, and claimed the order's lines.
 * A pool already exists and already holds its money, so all that is left is the last of the four —
 * and a decision that has shrunk from «which container?» to **«pool money or the company's?»**
 *
 * **Nobody picks a pool.** The material decides, through `investment_pool_items`, where a stock
 * item belongs to exactly one pool by database guarantee. So «الموظف لا يختار الصفقة أبداً» holds
 * more strongly than it did: there is no longer a container to choose even for the person who used
 * to choose it.
 *
 * ## The order the guards run in
 *
 * Every check happens before the first write, because a purchase order half-marked is worse than
 * one not marked at all — the lines that did get through would arrive carrying a pool while their
 * neighbours became company stock, and nobody would know it had been meant as one act.
 *
 * 1. **The order may still be funded** — nothing received yet. After receipt the cost layer has
 *    been stamped and can never be stamped again.
 * 2. **Every line is a line of this order, and is still unclaimed.** A line already carrying a
 *    container would be silently ignored at receipt, because the supply lookup answers with the
 *    first row it finds.
 * 3. **Every material belongs to a pool.**
 * 4. **Every pool can afford its share** — see below.
 *
 * ## Affordability is per pool, not per line
 *
 * Two lines of one lorry may belong to the same pool, and checking each against the pool's cash
 * separately would let a pool holding 15,000 buy two lines of 10,000. The costs are summed **by
 * pool** first, and each pool is asked once whether it covers its whole share.
 *
 * The cost is the line's landed cost from {@see FundingSnapshotQuery} — the same figure
 * `ReceivePurchaseOrder` will open the layer at, so the cash this reserves is the cash that will
 * actually be spent. A line nobody has priced costs zero here and is refused, which is the gate
 * `ReceivePurchaseOrder` already keeps, said one step earlier where it can still be fixed by typing
 * the price.
 */
final class BuyPurchaseOrderLinesFromPools
{
    public function __construct(
        private readonly FundingSnapshotQuery $snapshot,
        private readonly PoolDeployableCash $cash,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @return list<InvestorDealSupply>
     *
     * @throws PurchaseOrderCannotBeFunded|StockItemHasNoPool|PoolCannotAffordThePurchase
     */
    public function __invoke(int $purchaseOrderId, PoolPurchaseData $data, ?int $actorId): array
    {
        return DB::transaction(function () use ($purchaseOrderId, $data, $actorId): array {
            $order = ($this->snapshot)($purchaseOrderId, lock: true);

            $this->guardOrder($order);
            $lines = $this->linesToBuy($order, $purchaseOrderId, $data);
            $pools = $this->poolsFor($lines);

            $this->guardAffordability($order, $lines, $pools);

            $written = [];

            foreach ($lines as $line) {
                $supply = new InvestorDealSupply;

                $supply->investor_deal_id = $pools[$line->stockItemId]->getKey();
                $supply->source_type = AuditSubject::PurchaseOrder->value;
                $supply->source_id = $purchaseOrderId;
                $supply->stock_item_id = $line->stockItemId;
                // سعر السادة for this lorry. Null rides the sale instead — see the DTO.
                $supply->printing_sale_price = $line->printingSalePrice;
                $supply->claimed_by = $actorId;
                $supply->save();

                $written[] = $supply;
            }

            return $written;
        });
    }

    /**
     * @param  array{id: int, status: string, is_fundable: bool, stock_item_ids: list<int>, total_cost: string}|null  $order
     *
     * @throws PurchaseOrderCannotBeFunded
     */
    private function guardOrder(?array $order): void
    {
        if ($order === null) {
            throw PurchaseOrderCannotBeFunded::notFound();
        }

        if ($order['stock_item_ids'] === []) {
            throw PurchaseOrderCannotBeFunded::hasNoLines();
        }

        if (! $order['is_fundable']) {
            throw PurchaseOrderCannotBeFunded::alreadyArriving();
        }
    }

    /**
     * The lines this call is buying, and the proof each is free.
     *
     * @param  array{stock_item_ids: list<int>, ...}  $order
     * @return list<PoolPurchaseLineData>
     *
     * @throws PurchaseOrderCannotBeFunded
     */
    private function linesToBuy(array $order, int $purchaseOrderId, PoolPurchaseData $data): array
    {
        if ($data->lines === []) {
            throw PurchaseOrderCannotBeFunded::noLinesChosen();
        }

        $claimed = InvestorDealSupply::query()
            ->where('source_type', AuditSubject::PurchaseOrder->value)
            ->where('source_id', $purchaseOrderId)
            ->pluck('investor_deal_id', 'stock_item_id')
            ->all();

        $seen = [];

        foreach ($data->lines as $line) {
            if (! in_array($line->stockItemId, $order['stock_item_ids'], true)) {
                throw PurchaseOrderCannotBeFunded::lineIsNotOnTheOrder();
            }

            if (array_key_exists($line->stockItemId, $claimed)) {
                $container = InvestorDeal::query()->whereKey($claimed[$line->stockItemId])->first();

                throw PurchaseOrderCannotBeFunded::lineAlreadyFunded(
                    (string) ($container?->name ?? $container?->code ?? '')
                );
            }

            if (in_array($line->stockItemId, $seen, true)) {
                throw PurchaseOrderCannotBeFunded::listedTwice();
            }

            $seen[] = $line->stockItemId;
        }

        return $data->lines;
    }

    /**
     * The pool behind each material — the lookup that replaced a person's choice.
     *
     * @param  list<PoolPurchaseLineData>  $lines
     * @return array<int, InvestorDeal> keyed by stock item id
     *
     * @throws StockItemHasNoPool
     */
    private function poolsFor(array $lines): array
    {
        $pools = [];

        foreach ($lines as $line) {
            $item = InvestmentPoolItem::query()
                ->with('pool')
                ->where('stock_item_id', $line->stockItemId)
                ->first();

            if ($item?->pool === null) {
                throw StockItemHasNoPool::make(
                    $this->inventory->findStockItem($line->stockItemId)->displayName()
                );
            }

            $pools[$line->stockItemId] = $item->pool;
        }

        return $pools;
    }

    /**
     * Each pool asked once, about its whole share of this lorry.
     *
     * @param  array{line_costs: array<int, string>, ...}  $order
     * @param  list<PoolPurchaseLineData>  $lines
     * @param  array<int, InvestorDeal>  $pools
     *
     * @throws PurchaseOrderCannotBeFunded|PoolCannotAffordThePurchase
     */
    private function guardAffordability(array $order, array $lines, array $pools): void
    {
        $wanted = [];

        foreach ($lines as $line) {
            $cost = $order['line_costs'][$line->stockItemId] ?? '0.00';

            // The same rule `ReceivePurchaseOrder` keeps at the gate — pool goods do not arrive
            // without a unit cost — said where it can still be fixed by typing the price.
            if (bccomp($cost, '0', 2) <= 0) {
                throw PurchaseOrderCannotBeFunded::linesHaveNoCost();
            }

            $poolId = (int) $pools[$line->stockItemId]->getKey();
            $wanted[$poolId] = bcadd($wanted[$poolId] ?? '0.00', $cost, 2);
        }

        foreach ($wanted as $poolId => $cost) {
            $available = ($this->cash)($poolId)['deployable_cash'];

            if (bccomp($cost, $available, 2) > 0) {
                $pool = collect($pools)->first(fn (InvestorDeal $p) => (int) $p->getKey() === $poolId);

                throw PoolCannotAffordThePurchase::make(
                    (string) ($pool?->name ?? $pool?->code ?? ''),
                    $cost,
                    $available,
                );
            }
        }
    }
}
