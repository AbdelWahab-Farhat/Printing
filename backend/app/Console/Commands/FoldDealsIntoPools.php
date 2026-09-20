<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\Investor\Actions\CloseInvestorDeal;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\DealOrdersInFlightQuery;
use App\Domain\Investor\Queries\DealStockPosition;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\Money;
use Illuminate\Console\Command;
use Illuminate\Console\ConfirmableTrait;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Moves the open صفقات into continuous صناديق, once, and loses nothing.
 *
 * **Read the dry-run report before you run this for real.** It is the deliverable of this step;
 * the write is the easy part.
 *
 * ## What is preserved, and it is nearly everything
 *
 * Every `investor_deals` row stays. Its wallet entries stay, its expenses stay, its supplies stay,
 * its shares stay, its audit trail stays, and its screens go on rendering. A folded deal is marked
 * `closed` and keeps `kind = 'deal'` for ever — it is not converted into a pool, because what it
 * recorded was a different arrangement and rewriting it would falsify what was agreed.
 *
 * ## How pools are proposed
 *
 * **By connected components over shared shelves**, not by guesswork. A stock item may belong to
 * one pool only, so two deals that funded the same shelf *must* end up in the same pool; and a
 * deal that funded two shelves binds those two shelves together. Both rules are the same rule,
 * and the transitive closure of it is the answer. One pass, no ambiguity, and the same input
 * always gives the same proposal.
 *
 * A component that ends up holding several distinct materials is **flagged in the report**. That
 * is usually right — «ورق ٧٠غ» and «ورق ٩٠غ» belong together — and occasionally not, and only the
 * owner can say. Separating them means closing the deal that binds them first: this command will
 * not apportion one deal's capital across two pools, because the split would need an
 * apportionment rule it would have to invent and no screen could show its working for.
 *
 * ## What actually moves
 *
 * Per deal, in this order, and the order matters:
 *
 * 1. **the loss against capital** — a deal whose investors came out behind has that shortfall
 *    taken out of the capital they put into *that* deal, capped there, remainder to the company;
 *    the same three rows {@see CloseInvestorDeal} writes;
 * 2. **profit released to the wallet** — it was earned and it is theirs, and it becomes
 *    withdrawable exactly as it would have on a normal close;
 * 3. **capital released, then allocated to the pool** — through the ordinary ledger, so the fold
 *    is two visible rows on the investor's statement rather than a number that changed overnight;
 * 4. **the cost layers re-pointed** from the deal to the pool.
 *
 * Step 4 is the one `UPDATE` in the whole operation, and it is unavoidable: a layer carries the id
 * of whoever owns the goods, and the goods now belong to the pool. Nothing is lost by it — the
 * quantity, the cost and the arrival are untouched, and the movements that drew on the layer keep
 * pointing at the same rows.
 *
 * ## What it refuses
 *
 * **A deal with an order in flight.** Stock leaves at «جاهزة للطباعة», days before delivery, and
 * the profit posts at «تم الاستلام» — to the deal that owned the layer. Fold that deal today and
 * the payment lands on a closed container tomorrow. The command names those orders and stops;
 * wait for the parcels to be delivered. This is the same refusal `CloseInvestorDeal` makes, for
 * the same reason, and it is not overridable.
 *
 * `--dry-run` writes nothing at all, and reports from the same queries the real run uses.
 */
class FoldDealsIntoPools extends Command
{
    use ConfirmableTrait;

    protected $signature = 'investment:fold-in
                            {--dry-run : Report what would change and write nothing}
                            {--force : Skip the confirmation prompt outside local}';

    protected $description = 'Fold the open investor deals into continuous per-material pools';

    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly DealStockPosition $stockPosition,
        private readonly DealOrdersInFlightQuery $ordersInFlight,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $deals = InvestorDeal::query()
            ->where('kind', PoolKind::Deal->value)
            ->where('status', DealStatus::Open->value)
            ->with('items')
            ->orderBy('id')
            ->get();

        if ($deals->isEmpty()) {
            $this->info('لا توجد صفقات مفتوحة — لا شيء لترحيله.');

            return self::SUCCESS;
        }

        $blocked = $this->blockedByOrdersInFlight($deals);

        if ($blocked !== []) {
            $this->error('صفقات لها طلبيات لم تُسلَّم بعد — انتظر تسليمها قبل الترحيل:');

            foreach ($blocked as $code => $orders) {
                $this->line("  {$code} — ".implode('، ', $orders));
            }

            return self::FAILURE;
        }

        $components = $this->propose($deals);

        $this->report($components, $deals);

        if ($this->option('dry-run')) {
            $this->newLine();
            $this->info('تجربة فقط — لم يُكتب شيء.');

            return self::SUCCESS;
        }

        if (! $this->confirmToProceed('سيتم ترحيل الصفقات المفتوحة إلى صناديق')) {
            return self::FAILURE;
        }

        $this->fold($components, $deals);

        $this->newLine();
        $this->info('تم الترحيل.');

        return self::SUCCESS;
    }

    /**
     * Which deals cannot move yet, and the orders that are holding them.
     *
     * @param  Collection<int, InvestorDeal>  $deals
     * @return array<string, list<string>>
     */
    private function blockedByOrdersInFlight($deals): array
    {
        $blocked = [];

        foreach ($deals as $deal) {
            $orders = ($this->ordersInFlight)((int) $deal->getKey());

            if ($orders !== []) {
                $blocked[(string) $deal->code] = $orders;
            }
        }

        return $blocked;
    }

    /**
     * The proposed pools: connected components over the shelves the deals share.
     *
     * Union-find over stock item ids, with each deal unioning all of its own shelves. Deals that
     * share a shelf land in one component by construction, which is the whole requirement — a
     * stock item may belong to one pool only.
     *
     * @param  Collection<int, InvestorDeal>  $deals
     * @return array<int, array{stock_items: list<int>, deal_ids: list<int>}> keyed by component root
     */
    private function propose($deals): array
    {
        $parent = [];

        $find = function (int $x) use (&$parent, &$find): int {
            $parent[$x] ??= $x;

            return $parent[$x] === $x ? $x : $parent[$x] = $find($parent[$x]);
        };

        $union = function (int $a, int $b) use (&$parent, $find): void {
            $ra = $find($a);
            $rb = $find($b);

            if ($ra !== $rb) {
                // Toward the smaller id, so the component's root — and therefore the report's
                // order — is stable between runs.
                $parent[max($ra, $rb)] = min($ra, $rb);
            }
        };

        $dealShelves = [];

        foreach ($deals as $deal) {
            $shelves = $this->shelvesOf($deal);
            $dealShelves[(int) $deal->getKey()] = $shelves;

            foreach ($shelves as $shelf) {
                $find($shelf);
                $union($shelves[0], $shelf);
            }
        }

        $components = [];

        foreach ($dealShelves as $dealId => $shelves) {
            if ($shelves === []) {
                continue;
            }

            $root = $find($shelves[0]);

            $components[$root] ??= ['stock_items' => [], 'deal_ids' => []];
            $components[$root]['deal_ids'][] = $dealId;
            $components[$root]['stock_items'] = array_values(array_unique(
                array_merge($components[$root]['stock_items'], $shelves)
            ));
        }

        ksort($components);

        foreach ($components as $root => $component) {
            sort($components[$root]['stock_items']);
        }

        return $components;
    }

    /**
     * The shelves one deal stands on.
     *
     * Read from `investor_deal_items` — what the deal was written against — rather than from its
     * cost layers, because a deal whose goods are all sold still belongs to its material and must
     * land in that material's pool.
     *
     * @return list<int>
     */
    private function shelvesOf(InvestorDeal $deal): array
    {
        return $deal->items
            ->map(fn ($item): int => (int) $item->stock_item_id)
            ->unique()
            ->sort()
            ->values()
            ->all();
    }

    /**
     * @param  array<int, array{stock_items: list<int>, deal_ids: list<int>}>  $components
     * @param  Collection<int, InvestorDeal>  $deals
     */
    private function report(array $components, $deals): void
    {
        $byId = $deals->keyBy(fn (InvestorDeal $deal) => (int) $deal->getKey());

        $this->info('الصناديق المقترحة — '.count($components).':');
        $this->newLine();

        foreach ($components as $root => $component) {
            $this->line('■ صندوق مقترح #'.$root);
            $this->line('  المواد: '.implode('، ', $this->labelledShelfNames($component['stock_items'])));

            if (count($component['stock_items']) > 1) {
                $this->warn('  ⚠ يضم أكثر من مادة — راجِع إن كانت تنتمي لصندوق واحد فعلاً.');
            }

            $capital = [];
            $stockCost = '0.00';

            foreach ($component['deal_ids'] as $dealId) {
                $deal = $byId[$dealId];
                $balances = $this->balances->forDeal($dealId);
                $position = ($this->stockPosition)($dealId);
                $stockCost = bcadd($stockCost, $position['cost_remaining'], 2);

                $this->line("    ← {$deal->code}: رأس مال ".$balances['capital']
                    .' · ربح غير مُسوّى '.$balances['profit']
                    .' · بضاعة بالتكلفة '.$position['cost_remaining']);

                foreach ($balances['per_investor'] as $investorId => $pots) {
                    $capital[$investorId] = bcadd($capital[$investorId] ?? '0.00', $pots['capital'], 2);
                }
            }

            $this->line('  رأس المال الافتتاحي للصندوق:');

            foreach ($capital as $investorId => $amount) {
                $this->line("    • مستثمر #{$investorId}: {$amount}");
            }

            $this->line('  البضاعة الافتتاحية بالتكلفة: '.$stockCost);
            $this->newLine();
        }
    }

    /**
     * The shelves' own names, in the order the ids were given.
     *
     * @param  list<int>  $stockItemIds
     * @return list<string>
     */
    private function shelfNames(array $stockItemIds): array
    {
        $names = DB::table('stock_items')->whereIn('id', $stockItemIds)->pluck('name', 'id');

        return array_values(array_map(
            fn (int $id): string => (string) ($names[$id] ?? "#{$id}"),
            $stockItemIds,
        ));
    }

    /**
     * The same names with their ids, for the report — where «ورق» twice would be unreadable.
     *
     * @param  list<int>  $stockItemIds
     * @return list<string>
     */
    private function labelledShelfNames(array $stockItemIds): array
    {
        return array_map(
            fn (string $name, int $id): string => "{$name} (#{$id})",
            $this->shelfNames($stockItemIds),
            $stockItemIds,
        );
    }

    /**
     * @param  array<int, array{stock_items: list<int>, deal_ids: list<int>}>  $components
     * @param  Collection<int, InvestorDeal>  $deals
     */
    private function fold(array $components, $deals): void
    {
        $byId = $deals->keyBy(fn (InvestorDeal $deal) => (int) $deal->getKey());

        DB::transaction(function () use ($components, $byId): void {
            $capitalBefore = $this->capitalByInvestor();

            foreach ($components as $root => $component) {
                $pool = $this->openPool($root, $component, $byId);

                foreach ($component['deal_ids'] as $dealId) {
                    $this->foldOne($byId[$dealId], $pool);
                }
            }

            $capitalAfter = $this->capitalByInvestor();

            // **The whole safety of this command.** Capital is released from a deal and allocated
            // to a pool in the same breath, so every investor's total must be exactly what it was.
            // A difference of a piastre means an equation is wrong, and the right response is to
            // leave the database as it was and go and find out why.
            if ($capitalBefore !== $capitalAfter) {
                $this->error('اختلّ رأس المال بعد الترحيل — تم التراجع عن كل شيء.');

                foreach ($capitalBefore as $investorId => $before) {
                    $after = $capitalAfter[$investorId] ?? '0.00';

                    if ($before !== $after) {
                        $this->error("  مستثمر #{$investorId}: قبل {$before} · بعد {$after}");
                    }
                }

                throw new \RuntimeException('fold-in capital assertion failed');
            }
        });
    }

    /**
     * Every investor's capital, wherever it sits — wallet plus every container.
     *
     * The sum this command must not move. Capital *inside* a container changes by design; the
     * total a man has with the company does not.
     *
     * @return array<int, string>
     */
    private function capitalByInvestor(): array
    {
        $totals = [];

        foreach (InvestorWalletEntry::query()->with('reversedEntry')->get() as $entry) {
            $deltas = $entry->deltas();
            $id = (int) $entry->investor_id;

            $totals[$id] = bcadd(
                $totals[$id] ?? '0.00',
                bcadd($deltas['capital_wallet'], $deltas['capital_deal'], 2),
                2,
            );
        }

        ksort($totals);

        return $totals;
    }

    /**
     * @param  array{stock_items: list<int>, deal_ids: list<int>}  $component
     * @param  Collection<int, InvestorDeal>  $byId
     */
    private function openPool(int $root, array $component, $byId): InvestorDeal
    {
        $names = $this->shelfNames($component['stock_items']);
        $first = $byId[$component['deal_ids'][0]];

        $pool = new InvestorDeal([
            'name' => $this->uniquePoolName((string) ($names[0] ?? ''), $root),
            'opened_on' => now()->toDateString(),
            'notes' => 'مُرحَّل من: '.implode('، ', array_map(
                fn (int $id): string => (string) $byId[$id]->code,
                $component['deal_ids'],
            )),
        ]);

        $pool->kind = PoolKind::Pool;
        $pool->status = DealStatus::Open;
        $pool->opened_at = now();

        // **Every frozen term the deal was on comes across, not just the profit share.**
        //
        // The reason is the orders already in flight. Attribution reads the *layer's*
        // `investor_deal_id` at delivery ({@see \App\Domain\Inventory\Queries\ConsumptionBreakdownQuery}),
        // so the moment the fold re-points those layers, an order struck under D1 is paid by the
        // pool instead — through {@see InvestorDeal::investorsCutOf()}, which multiplies by
        // `investor_funded_percent`. A pool taking that column's default of 100 would pay the
        // investors for goods they did not buy: D1's real figure is 93.1808, and the company owns
        // the remaining 6.82% of every dinar those orders earn.
        //
        // So the pool inherits the terms wholesale and the transition is invisible to an order
        // half-way through its life. From Slice 3 the middle factor becomes period-computed from
        // capital and these columns fall out of the arithmetic — but until then they are what the
        // sums are made of.
        $pool->investor_profit_share_percent = $first->investor_profit_share_percent;
        $pool->investor_funded_percent = $first->investor_funded_percent;
        $pool->company_stake = $first->company_stake;
        $pool->printing_sale_price = $first->printing_sale_price;
        $pool->save();

        foreach ($component['stock_items'] as $stockItemId) {
            $row = $pool->poolItems()->make();
            $row->stock_item_id = $stockItemId;
            $row->save();
        }

        return $pool;
    }

    /**
     * A name no other pool has.
     *
     * **Two shelves may genuinely share a name** — `stock_items.name` is not unique, and «كيس شحن»
     * standing behind two products is ordinary. The pool name *is* unique, because it is what
     * staff say out loud, so the first proposal can collide and the command must not die halfway
     * through a fold with three pools written and two not.
     *
     * Disambiguated by the component root rather than by a counter: the root is derived from the
     * data, so the same database always produces the same names and a second dry-run reads the
     * same as the first. The owner renames them afterwards from the screen; this only has to be
     * unique and recognisable.
     */
    private function uniquePoolName(string $preferred, int $root): string
    {
        $base = trim($preferred) === '' ? "صندوق {$root}" : mb_substr(trim($preferred), 0, 110);

        $taken = fn (string $name): bool => InvestorDeal::query()
            ->where('kind', PoolKind::Pool->value)
            ->where('name', $name)
            ->exists();

        if (! $taken($base)) {
            return $base;
        }

        $withRoot = mb_substr($base, 0, 110)." #{$root}";

        return $taken($withRoot) ? mb_substr($base, 0, 100).' #'.$root.'-'.uniqid() : $withRoot;
    }

    private function foldOne(InvestorDeal $deal, InvestorDeal $pool): void
    {
        foreach ($this->balances->forDeal((int) $deal->getKey())['per_investor'] as $investorId => $pots) {
            $capital = $pots['capital'];
            $profit = $pots['profit'];

            // The loss out of the capital he put into THIS deal, exactly as a close would settle
            // it. Every amount in the ledger is positive, so a negative profit has no release to
            // hand back with.
            if (bccomp($profit, '0', 2) < 0) {
                $shortfall = substr($profit, 1);
                $fromCapital = bccomp($shortfall, $capital, 2) > 0 ? $capital : $shortfall;

                if (bccomp($fromCapital, '0', 2) > 0) {
                    $this->write($deal, (int) $investorId, WalletEntryType::CapitalWritedown, $fromCapital);
                    $capital = bcsub($capital, $fromCapital, 2);
                    $profit = bcadd($profit, $fromCapital, 2);
                }

                if (bccomp($profit, '0', 2) < 0) {
                    $this->write($deal, (int) $investorId, WalletEntryType::LossAbsorbedByCompany, substr($profit, 1));
                    $profit = '0.00';
                }
            }

            // Earned under the old arrangement and settled under it: it goes to his wallet and is
            // withdrawable, rather than being carried into a pool period he had no part in.
            if (bccomp($profit, '0', 2) > 0) {
                $this->write($deal, (int) $investorId, WalletEntryType::ProfitRelease, $profit);
            }

            if (bccomp($capital, '0', 2) > 0) {
                $this->write($deal, (int) $investorId, WalletEntryType::Release, $capital);
                $this->write($pool, (int) $investorId, WalletEntryType::Allocation, $capital);
            }
        }

        $this->carryShares($deal, $pool);

        // The goods change hands. The one UPDATE in this command — see the class docblock.
        DB::table('stock_batches')
            ->where('investor_deal_id', $deal->getKey())
            ->whereNull('deleted_at')
            ->update(['investor_deal_id' => $pool->getKey()]);

        $deal->status = DealStatus::Closed;
        $deal->closed_at = now();
        $deal->notes = trim((string) $deal->notes."\nمُرحَّلة إلى صندوق ".$pool->code);
        $deal->save();
    }

    /**
     * Puts each of the deal's investors on the pool's roster, once.
     *
     * `share_percent` is copied so the row satisfies the table's `> 0` check, and is **not** what
     * any split reads: a pool's ownership is recomputed from capital at every close. The roster's
     * job here is «who is in this pool», and `joined_at` is when he really joined.
     */
    private function carryShares(InvestorDeal $deal, InvestorDeal $pool): void
    {
        foreach ($deal->shares()->get() as $share) {
            $existing = $pool->shares()->where('investor_id', $share->investor_id)->first();

            if ($existing !== null) {
                continue;
            }

            $row = $pool->shares()->make([
                'committed_amount' => $share->committed_amount,
                // Null, deliberately. A pool's ownership is recomputed from capital at every
                // close; a percentage here would be a second answer to a question that already
                // has one, and zero or an even split would both be figures somebody could
                // believe. See the migration that made this column nullable.
                'share_percent' => null,
                'notes' => 'مُرحَّل من '.$deal->code,
            ]);

            $row->investor_id = $share->investor_id;
            $row->joined_at = $share->joined_at;
            $row->save();
        }
    }

    private function write(InvestorDeal $container, int $investorId, WalletEntryType $type, string $amount): void
    {
        $entry = new InvestorWalletEntry([
            'amount' => Money::round($amount),
            'occurred_at' => now(),
        ]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $container->getKey();
        $entry->type = $type;
        $entry->save();
    }
}
