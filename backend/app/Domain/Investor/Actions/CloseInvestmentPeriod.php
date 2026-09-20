<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\PeriodHasUnansweredReturns;
use App\Domain\Investor\Exceptions\PeriodIsAlreadyClosed;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriodShare;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodNetProfit;
use App\Domain\Investor\Queries\PoolDeployableCash;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\PeriodDistribution;
use Illuminate\Support\Facades\DB;

/**
 * Ends a period: divides what it made, pays it into wallets, and lets out whoever asked to leave.
 *
 * **This is the only door profit walks through to become withdrawable.** Nothing else writes
 * `profit_release`, so «الربح لا يُسحب قبل الإقفال» needs no guard anywhere else — there is simply
 * no other path.
 *
 * ## What it refuses, and what it deliberately does not
 *
 * `CloseInvestorDeal` refused a container that still held stock or had an order in flight. **Neither
 * applies here, and that is the whole point of the redesign**: a period closes with full shelves,
 * and the goods roll into the next one at cost. An order still in flight has simply not realized
 * anything yet, so there is nothing of it to divide.
 *
 * What it does refuse is an **unanswered returned-goods question** (§6.2.1). A cancelled printed
 * order credits its material back as good stock, and nobody but a person can say whether there is
 * ink on it. Closing over that question divides profit the pool did not earn, on goods it does not
 * have, into wallets the money can be withdrawn from.
 *
 * ## The order of writes, which is fixed
 *
 * 1. **The shares are computed and frozen** — {@see PeriodDistribution} over each participant's
 *    capital, with the company taking a weight like anybody else and the operator's residual on top.
 * 2. **`profit` / `loss` rows per investor**, sourced to the period. This is where the period's
 *    result reaches an individual's ledger for the first time.
 * 3. **Losses settled against capital** — a negative pot becomes a `capital_writedown` capped at
 *    what he has in *this pool*, and any remainder is `loss_absorbed_by_company`. Nothing in the
 *    arrangement makes him owe more than he put in.
 * 4. **Profit released** to the wallet, where it becomes withdrawable.
 * 5. **Queued exits paid**, last — so a man who asked in September to leave is still paid his
 *    September share before his capital goes back.
 *
 * A release before a writedown would hand back money the period had already lost; an exit before
 * the distribution would pay him his capital and then his profit into a pool he had left.
 *
 * **Then the next period opens**, so a pool is never without one. A sale realized in the gap would
 * otherwise have no period to accrue to, and capital offered in it no boundary to wait for.
 *
 * ## The company is paid like a partner
 *
 * Its share — capital weight plus operator's residual — is written to its own investor row and
 * released to its own wallet, exactly as an investor's is. Re-contributing it as capital is then a
 * deliberate act rather than a silent accumulation, which is what «الفصل بين رأس المال والأرباح»
 * asks for.
 */
final class CloseInvestmentPeriod
{
    public function __construct(
        private readonly PeriodNetProfit $netProfit,
        private readonly InvestorBalances $balances,
        private readonly PoolDeployableCash $cash,
        private readonly OpenInvestmentPeriod $openNext,
    ) {}

    /**
     * @throws PeriodIsAlreadyClosed|PeriodHasUnansweredReturns
     */
    public function __invoke(InvestmentPeriod $period, ?int $actorId = null): InvestmentPeriod
    {
        return DB::transaction(function () use ($period, $actorId): InvestmentPeriod {
            $locked = InvestmentPeriod::query()->whereKey($period->getKey())->lockForUpdate()->firstOrFail();
            $pool = InvestorDeal::query()->whereKey($locked->investor_deal_id)->lockForUpdate()->firstOrFail();

            if ($locked->status !== PeriodStatus::Open) {
                throw PeriodIsAlreadyClosed::make($locked->starts_on->toDateString());
            }

            if ($this->netProfit->hasUnansweredReturns($locked)) {
                throw PeriodHasUnansweredReturns::make((string) ($pool->name ?? $pool->code));
            }

            $opening = ($this->cash)((int) $pool->getKey());
            $figures = ($this->netProfit)($locked);

            $division = PeriodDistribution::divide(
                $figures['net_profit'],
                $this->capitalByInvestor((int) $pool->getKey()),
                $this->companyInvestorId(),
                (string) $pool->investor_profit_share_percent,
            );

            $this->freezeShares($locked, $division, $this->companyInvestorId());
            $this->postResults($locked, $pool, $division);
            $this->settleEveryone($locked, $pool);
            $this->payQueuedExits($pool, $locked);

            $closing = ($this->cash)((int) $pool->getKey());

            $locked->fill([]);
            $locked->status = PeriodStatus::Closed;
            $locked->closed_at = now();
            $locked->closed_by = $actorId;
            $locked->opening_cash = $opening['deployable_cash'];
            $locked->closing_cash = $closing['deployable_cash'];
            $locked->opening_stock_cost = $opening['stock_at_cost'];
            $locked->closing_stock_cost = $closing['stock_at_cost'];
            $locked->realized_margin = $figures['realized_margin'];
            $locked->deductible_expenses = $figures['deductible_expenses'];
            $locked->damage_cost = $figures['damage_cost'];
            $locked->shortage_cost = $figures['shortage_cost'];
            $locked->net_profit = $figures['net_profit'];
            $locked->investor_share_percent_applied = (string) $pool->investor_profit_share_percent;
            $locked->investor_capital_weight_applied = $division['investor_weight_percent'];
            $locked->total_pool_capital = $division['total_capital'];
            $locked->total_investor_capital = $division['total_investor_capital'];
            $locked->save();

            // **The next period opens in the same breath**, and a pool is never without one.
            //
            // Not tidiness: everything that lands on a pool has to land *somewhere*. A sale
            // realized between a close and the next open would have no period to accrue to, and a
            // man offering capital would be asked to wait for a boundary nobody had set. Both are
            // reachable in minutes on a working day, and both would be reported as the feature
            // being broken rather than as a period being late.
            //
            // This also admits the capital queued for this boundary — see OpenInvestmentPeriod.
            ($this->openNext)($pool);

            return $locked->refresh();
        });
    }

    /**
     * Every participant's capital in this pool, company included.
     *
     * Read from the ledger rather than from a roster: capital is what the movements say it is, and
     * a stored percentage is the thing this whole design removed.
     *
     * @return array<int, string>
     */
    private function capitalByInvestor(int $poolId): array
    {
        $capital = [];

        foreach ($this->balances->forDeal($poolId)['per_investor'] as $investorId => $pots) {
            // A man who has taken everything out is not a participant this period, and giving him
            // a zero-capital row would put a 0.0000% share on the record for no reason.
            if (bccomp($pots['capital'], '0', 2) > 0) {
                $capital[(int) $investorId] = $pots['capital'];
            }
        }

        return $capital;
    }

    /** The company's investor row, when there is one. */
    private function companyInvestorId(): ?int
    {
        $id = Investor::query()->where('is_company', true)->value('id');

        return $id === null ? null : (int) $id;
    }

    /**
     * @param  array<string, mixed>  $division
     */
    private function freezeShares(InvestmentPeriod $period, array $division, ?int $companyId): void
    {
        foreach ($division['per_investor'] as $investorId => $share) {
            $row = new InvestmentPeriodShare;
            $row->investment_period_id = $period->getKey();
            $row->investor_id = $investorId;
            $row->capital = $share['capital'];
            $row->share_percent = $share['share_percent'];
            $row->net_share = $share['net_share'];
            $row->is_company = false;
            $row->save();
        }

        if ($companyId === null || bccomp($division['company_total'], '0', 2) === 0) {
            return;
        }

        // The company's line, carrying its whole take: its capital's weight **and** the operator's
        // residual. `share_percent` is 100 of its own side, which is what it is — the figure that
        // means something for it is `net_share`.
        $row = new InvestmentPeriodShare;
        $row->investment_period_id = $period->getKey();
        $row->investor_id = $companyId;
        $row->capital = $division['total_capital'] === '0.00'
            ? '0.00'
            : bcsub($division['total_capital'], $division['total_investor_capital'], 2);
        $row->share_percent = '100.0000';
        $row->net_share = $division['company_total'];
        $row->is_company = true;
        $row->save();
    }

    /**
     * The period's result into each ledger — one `profit` or `loss` row per participant.
     *
     * Sourced to the **period**, not to an order: under pools a person is paid once a month for
     * everything the pool did, and the orders behind that figure are read from
     * `investment_realized_earnings` when somebody asks «من أين جاء هذا؟».
     *
     * @param  array<string, mixed>  $division
     */
    private function postResults(InvestmentPeriod $period, InvestorDeal $pool, array $division): void
    {
        $amounts = [];

        foreach ($division['per_investor'] as $investorId => $share) {
            $amounts[(int) $investorId] = $share['net_share'];
        }

        $companyId = $this->companyInvestorId();

        if ($companyId !== null) {
            $amounts[$companyId] = bcadd($amounts[$companyId] ?? '0.00', $division['company_total'], 2);
        }

        foreach ($amounts as $investorId => $amount) {
            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            $isLoss = bccomp($amount, '0', 2) < 0;

            $entry = new InvestorWalletEntry([
                'amount' => $isLoss ? substr($amount, 1) : $amount,
                'occurred_at' => now(),
            ]);

            $entry->investor_id = $investorId;
            $entry->investor_deal_id = $pool->getKey();
            $entry->type = $isLoss ? WalletEntryType::Loss : WalletEntryType::Profit;
            $entry->source_type = AuditSubject::InvestmentPeriod->value;
            $entry->source_id = $period->getKey();
            $entry->save();
        }
    }

    /**
     * Settles every pot in the pool: losses out of capital, then profit to the wallet.
     *
     * Reads the **balance** rather than this period's share, deliberately. A residue from an earlier
     * period — a rounding remainder, a correction posted after a close — would otherwise sit in
     * `profit_deal` for ever, never released and never explained.
     */
    private function settleEveryone(InvestmentPeriod $period, InvestorDeal $pool): void
    {
        foreach ($this->balances->forDeal((int) $pool->getKey())['per_investor'] as $investorId => $pots) {
            $this->settle($pool, (int) $investorId, $pots['capital'], $pots['profit']);
        }
    }

    /** One participant: the loss out of his capital here, then what is left to his wallet. */
    private function settle(InvestorDeal $pool, int $investorId, string $capital, string $profit): void
    {
        // Every amount in this ledger is positive, so a negative pot has no release to hand back
        // with: the shortfall comes out of the capital he put into THIS pool, and out of nothing
        // else. A loss in the ink pool never reaches his paper capital.
        if (bccomp($profit, '0', 2) < 0) {
            $shortfall = substr($profit, 1);
            $fromCapital = bccomp($shortfall, $capital, 2) > 0 ? $capital : $shortfall;

            if (bccomp($fromCapital, '0', 2) > 0) {
                $this->write($pool, $investorId, WalletEntryType::CapitalWritedown, $fromCapital);
                $profit = bcadd($profit, $fromCapital, 2);
            }

            // Nothing in the arrangement makes him owe more than he put in, so the remainder is the
            // company's — written as its own line so it appears on his statement rather than
            // vanishing into a difference nobody can name.
            if (bccomp($profit, '0', 2) < 0) {
                $this->write($pool, $investorId, WalletEntryType::LossAbsorbedByCompany, substr($profit, 1));
                $profit = '0.00';
            }
        }

        if (bccomp($profit, '0', 2) > 0) {
            $this->write($pool, $investorId, WalletEntryType::ProfitRelease, $profit);
        }
    }

    /**
     * Capital out, for whoever asked during the period — **after** the distribution.
     *
     * So a man who said in September that he wanted to leave is still paid his September share
     * before his money goes back.
     *
     * ## He is paid out of the cash, never out of the goods
     *
     * A pool's money is in two shapes at any moment: cash it has not spent, and stock it bought
     * with it. Only the first can be handed back — `deployable_cash` is book value **less stock at
     * cost**, so an exit can never force a lorry to be sold. What cannot be covered stays pending
     * and comes round at the next close.
     *
     * ## And only out of *his own* share of that cash
     *
     * The ceiling is his capital weight × the pool's cash, not the pool's whole cash. Without the
     * weight, whoever asked first could empty the till: two partners each owning half of a pool
     * holding 40,000 in cash, and the first to queue takes all 40,000 while the second waits on a
     * lorry selling. Same pool, same month, same right to leave — and the only thing that decided
     * it was the order they walked in.
     *
     * **The weights are taken once, before anybody is paid.** Recomputing them as the loop runs
     * would make each man's ceiling depend on who came before him in the queue, which is the
     * arbitrariness this is here to remove.
     *
     * A man with two standing requests is tracked across both, or he would draw his whole share
     * twice.
     */
    private function payQueuedExits(InvestorDeal $pool, InvestmentPeriod $period): void
    {
        $pending = InvestmentCapitalRequest::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('status', CapitalRequestStatus::Pending->value)
            ->where('direction', CapitalRequestDirection::Out->value)
            ->orderBy('requested_at')
            ->orderBy('id')
            ->lockForUpdate()
            ->get();

        if ($pending->isEmpty()) {
            return;
        }

        // One snapshot, so the split does not depend on the order of the queue.
        $snapshot = $this->balances->forDeal((int) $pool->getKey());
        $totalCapital = $snapshot['capital'];
        $cash = ($this->cash)((int) $pool->getKey())['deployable_cash'];

        $paid = [];

        foreach ($pending as $request) {
            $investorId = (int) $request->investor_id;
            $wanted = (string) $request->amount;

            $inPool = $snapshot['per_investor'][$investorId]['capital'] ?? '0.00';
            $already = $paid[$investorId] ?? '0.00';

            $ceiling = bcsub($this->shareOfCash($inPool, $totalCapital, $cash), $already, 2);

            if (bccomp($wanted, $ceiling, 2) > 0) {
                continue;
            }

            $paid[$investorId] = bcadd($already, $wanted, 2);

            $entry = $this->write($pool, $investorId, WalletEntryType::Release, $wanted);

            $request->status = CapitalRequestStatus::Applied;
            $request->effective_period_id = $period->getKey();
            $request->applied_entry_id = $entry->getKey();
            $request->save();
        }
    }

    /**
     * The most this investor may take out today: his slice of the cash, capped by what he owns.
     *
     * The cap matters when the pool is holding more cash than stock — a man owning a tenth of a
     * pool that is almost all cash would otherwise be offered a tenth of it regardless of whether
     * he ever put that much in.
     */
    private function shareOfCash(string $hisCapital, string $totalCapital, string $cash): string
    {
        if (bccomp($totalCapital, '0', 2) <= 0 || bccomp($cash, '0', 2) <= 0) {
            return '0.00';
        }

        $slice = Money::round(bcdiv(bcmul($cash, $hisCapital, 8), $totalCapital, 8));

        return bccomp($slice, $hisCapital, 2) > 0 ? $hisCapital : $slice;
    }

    private function write(InvestorDeal $pool, int $investorId, WalletEntryType $type, string $amount): InvestorWalletEntry
    {
        $entry = new InvestorWalletEntry([
            'amount' => Money::round($amount),
            'occurred_at' => now(),
        ]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $pool->getKey();
        $entry->type = $type;
        $entry->save();

        return $entry;
    }
}
