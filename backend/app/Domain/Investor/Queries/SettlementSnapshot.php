<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Where a pool's money is — worked out **twice, from sources that never consult each other**.
 *
 * ## Why twice
 *
 * The identity in §6.5 of the design reads:
 *
 * ```
 * Σ capital in pool + Σ undivided profit  =  deployable cash + stock at cost
 * ```
 *
 * Asked of {@see PoolDeployableCash} alone that is a **tautology** — it *defines* deployable cash as
 * book value less stock, so the two sides are the same subtraction written backwards and can never
 * disagree. A settlement built on it would print a reassuring zero for ever, including on the day
 * somebody wrote a lorry off the shelf by hand.
 *
 * So the right-hand side is rebuilt here from the **movements**, and only then compared:
 *
 * ```
 * book side    = Σ capital_deal + Σ profit_deal            the wallet ledger
 *              + net profit of the open period             the periods and the earnings table
 *
 * walked side  = capital in − capital out                  Allocation / Release rows
 *              + earnings to date                          investment_realized_earnings, every period
 *              − profit released to wallets                ProfitRelease rows
 *              − expenses charged                          investor_deal_expenses, deducted only
 *              − cost of every layer ever bought           the cost layers
 *              + cost of every layer sold                  the draw ledger
 *              + stock still on the shelf at cost          the cost layers again
 *
 * drift        = book side − walked side
 * ```
 *
 * ## What makes it come out zero
 *
 * Substituting `received = remaining + sold + damaged + short` into the walk collapses it to
 *
 * ```
 * walked side = capital + earnings − profit released − expenses − damage − shortage
 * ```
 *
 * and every closed period released exactly `earnings − expenses − damage − shortage` of its own, so
 * all the closed terms cancel and what is left is the **open** period's net profit — which is the
 * second line of the book side. They agree to the fils, and they agree for a reason rather than by
 * coincidence.
 *
 * ## What makes it come out non-zero
 *
 * Anything that moved goods or money without telling the investment ledger. The plain case: a
 * `damage` adjustment posted straight through Inventory in a period that has since closed. The
 * goods left the shelf, `stock_at_cost` fell, no loss was ever charged to anybody — and the pool's
 * apparent cash rose by their cost. **Nothing else in this system would ever mention it.**
 *
 * That is a finding. It is reported and never absorbed, because a figure that quietly corrects
 * itself is a figure nobody can audit.
 *
 * ## `undeployed_current_profit`
 *
 * The open period's net profit is real money the company is holding, and
 * {@see PoolDeployableCash} does **not** count it as spendable: that query reads `profit_deal` from
 * the wallet ledger, where a pool's profit appears only at the close and leaves again in the same
 * transaction, so the figure it sees is always zero. Whether this month's margin should buy next
 * month's lorry is the owner's call. What this query refuses to do is leave it unnamed.
 */
final class SettlementSnapshot
{
    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly DealStockPosition $stockPosition,
        private readonly PeriodNetProfit $netProfit,
        private readonly SettingsService $settings,
    ) {}

    /**
     * @return array{
     *     total_capital: string,
     *     investor_capital: string,
     *     company_capital: string,
     *     deployable_cash: string,
     *     stock_at_cost: string,
     *     undeployed_current_profit: string,
     *     receivables: string,
     *     liabilities: string,
     *     distributed_profit_to_date: string,
     *     company_absorbed_loss: string,
     *     damage_to_date: string,
     *     shortage_to_date: string,
     *     book_value: string,
     *     reconstructed_cash: string,
     *     reconstructed_value: string,
     *     drift: string,
     *     period_from_id: ?int,
     *     period_to_id: ?int,
     *     last_settled_on: ?string,
     *     next_settlement_due_on: ?string,
     *     settlement_is_overdue: bool,
     *     settlement_period_months: int
     * }
     */
    public function __invoke(int $poolId): array
    {
        $ledger = $this->balances->forDeal($poolId);
        $stock = ($this->stockPosition)($poolId);

        $openProfit = $this->openPeriodNetProfit($poolId);
        $capital = $this->capitalSides($poolId, $ledger['per_investor']);

        // ── the book side ────────────────────────────────────────────────────────────────
        $bookValue = Money::round(bcadd(
            bcadd($ledger['capital'], $ledger['profit'], 2),
            $openProfit,
            2,
        ));

        // ── the walked side ──────────────────────────────────────────────────────────────
        $moved = $this->ledgerMovements($poolId);
        $earnings = $this->earningsToDate($poolId);
        $expenses = $this->expensesCharged($poolId);

        // Everything the pool ever paid for. Derived rather than summed off the layers directly:
        // an internal transfer mints a fresh layer at the destination, so `SUM(quantity_received)`
        // counts every transferred unit twice. `DealStockPosition` already refuses that trap, and
        // this is the same reasoning applied to cost.
        $costReceived = bcadd(
            bcadd($stock['cost_remaining'], $stock['cost_sold'], 2),
            bcadd($stock['cost_damaged'], $stock['cost_short'], 2),
            2,
        );

        $walkedCash = bcsub(
            bcadd(
                bcadd(
                    bcsub($moved['capital_in'], $moved['capital_out'], 2),
                    // **Money the company really put in.** When a period's loss runs past what an
                    // investor has in the pool, the remainder is written off to the company rather
                    // than left owing — and the pool goes on holding goods it could not otherwise
                    // have paid for. It moves no cash across a counter, so nothing in the movement
                    // ledger shows it; left out of the walk it would surface as drift on every
                    // pool that ever had a bad month, which is the fastest way to teach somebody
                    // that drift means nothing.
                    $moved['company_absorbed_loss'],
                    2,
                ),
                bcsub($earnings, $moved['profit_released'], 2),
                2,
            ),
            bcadd($expenses, bcsub($costReceived, $stock['cost_sold'], 2), 2),
            2,
        );

        // **The cash alone**, which is the figure a person can act on: «الصندوق المفروض عنده
        // ٨٠٬٠٠٠». The comparison below adds the goods back, because the book side counts both.
        $reconstructed = Money::round($walkedCash);
        $reconstructedValue = bcadd($reconstructed, $stock['cost_remaining'], 2);

        return [
            'total_capital' => $ledger['capital'],
            'investor_capital' => $capital['investor'],
            'company_capital' => $capital['company'],

            'deployable_cash' => Money::round(
                bcsub(bcadd($ledger['capital'], $ledger['profit'], 2), $stock['cost_remaining'], 2)
            ),
            'stock_at_cost' => $stock['cost_remaining'],
            'undeployed_current_profit' => $openProfit,

            'receivables' => $this->receivables($poolId),
            'liabilities' => $this->undrawnProfitOwed($poolId),

            'distributed_profit_to_date' => $moved['profit_released'],
            'company_absorbed_loss' => $moved['company_absorbed_loss'],
            'damage_to_date' => $stock['cost_damaged'],
            'shortage_to_date' => $stock['cost_short'],

            'book_value' => $bookValue,
            'reconstructed_cash' => $reconstructed,
            'reconstructed_value' => Money::round($reconstructedValue),
            'drift' => Money::round(bcsub($bookValue, $reconstructedValue, 2)),

            'period_from_id' => $this->firstUnsettledPeriodId($poolId),
            'period_to_id' => $this->lastClosedPeriodId($poolId),
        ] + $this->dueDates($poolId);
    }

    /**
     * The open period's net profit — nobody's yet, and not in `deployable_cash`.
     *
     * Zero when the pool has no open period, which is only reachable mid-close: every other path
     * opens the next one in the same transaction that closes the last.
     */
    private function openPeriodNetProfit(int $poolId): string
    {
        $open = InvestmentPeriod::query()
            ->where('investor_deal_id', $poolId)
            ->where('status', PeriodStatus::Open->value)
            ->first();

        return $open === null ? '0.00' : ($this->netProfit)($open)['net_profit'];
    }

    /**
     * Capital split between the partners and the company's own stake.
     *
     * The company is an ordinary participant here (§10) — one `investors` row flagged `is_company`,
     * taking a capital weight like anybody else. Splitting it out is presentation, not arithmetic.
     *
     * @param  array<int, array{capital: string, profit: string}>  $perInvestor
     * @return array{investor: string, company: string}
     */
    private function capitalSides(int $poolId, array $perInvestor): array
    {
        $companyId = Investor::query()->where('is_company', true)->value('id');

        $investor = '0.00';
        $company = '0.00';

        foreach ($perInvestor as $investorId => $pots) {
            if ($companyId !== null && (int) $investorId === (int) $companyId) {
                $company = bcadd($company, $pots['capital'], 2);

                continue;
            }

            $investor = bcadd($investor, $pots['capital'], 2);
        }

        return ['investor' => Money::round($investor), 'company' => Money::round($company)];
    }

    /**
     * The three cash-moving sums in the wallet ledger, by type.
     *
     * A reversal is netted by reading `deltas()` rather than the raw type — the same treatment
     * {@see InvestorBalances} gives it, and for the same reason: a reversed allocation must not
     * count as capital that went in.
     *
     * @return array{capital_in: string, capital_out: string, profit_released: string, company_absorbed_loss: string}
     */
    private function ledgerMovements(int $poolId): array
    {
        $in = '0';
        $out = '0';
        $released = '0';
        $absorbed = '0';

        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investor_deal_id', $poolId)
            ->get();

        foreach ($entries as $entry) {
            $effective = $entry->type === WalletEntryType::Reversal
                ? $entry->reversedEntry?->type
                : $entry->type;

            if ($effective === null) {
                continue;
            }

            // A reversal carries the opposite sign of the row it undoes.
            $sign = $entry->type === WalletEntryType::Reversal ? '-1' : '1';
            $amount = bcmul((string) $entry->amount, $sign, 2);

            match ($effective) {
                WalletEntryType::Allocation => $in = bcadd($in, $amount, 2),
                WalletEntryType::Release => $out = bcadd($out, $amount, 2),
                WalletEntryType::ProfitRelease => $released = bcadd($released, $amount, 2),
                WalletEntryType::LossAbsorbedByCompany => $absorbed = bcadd($absorbed, $amount, 2),
                default => null,
            };
        }

        return [
            'capital_in' => Money::round($in),
            'capital_out' => Money::round($out),
            'profit_released' => Money::round($released),
            'company_absorbed_loss' => Money::round($absorbed),
        ];
    }

    /** Everything this pool has ever realized, across every period, corrections included. */
    private function earningsToDate(int $poolId): string
    {
        return Money::round((string) (DB::table('investment_realized_earnings as e')
            ->join('investment_periods as p', 'p.id', '=', 'e.investment_period_id')
            ->where('p.investor_deal_id', $poolId)
            ->whereNull('e.deleted_at')
            ->whereNull('p.deleted_at')
            ->sum('e.amount') ?: '0'));
    }

    /**
     * Expenses that were actually subtracted — never the `is_landed` ones.
     *
     * Shipping and customs typed on a purchase order are **already inside the cost of the layers
     * that arrived**, so the walk would charge them a second time. They are recorded and excluded,
     * exactly as {@see PeriodNetProfit} excludes them.
     */
    private function expensesCharged(int $poolId): string
    {
        return Money::round((string) (DB::table('investor_deal_expenses')
            ->where('investor_deal_id', $poolId)
            ->where('is_landed', false)
            ->whereNull('deleted_at')
            ->sum('amount') ?: '0'));
    }

    /**
     * Money the pool has booked as earned and the customer has not paid.
     *
     * **The size of an assumption `deployable_cash` makes silently.** Profit is recognised at
     * delivery, so an order delivered on credit is counted as cash in hand by every screen. That is
     * inherited from the deal model and is not wrong — but it is an assumption, and a settlement is
     * where an assumption gets a number.
     *
     * Scoped to earnings whose source is an order still carrying a balance. An earning sourced to a
     * stock movement — سعر السادة, paid by the press at the shelf — is not a customer debt and is
     * not here.
     */
    private function receivables(int $poolId): string
    {
        return Money::round((string) (DB::table('investment_realized_earnings as e')
            ->join('investment_periods as p', 'p.id', '=', 'e.investment_period_id')
            ->join('orders as o', 'o.id', '=', 'e.source_id')
            ->where('p.investor_deal_id', $poolId)
            ->where('e.source_type', AuditSubject::Order->value)
            ->whereNull('e.deleted_at')
            ->whereNull('p.deleted_at')
            ->whereNull('o.deleted_at')
            ->whereRaw('o.grand_total - (o.paid_amount + o.written_off_amount + o.carrier_settled_amount) > 0')
            ->sum('e.amount') ?: '0'));
    }

    /**
     * Undrawn profit this pool has put into wallets — money the company holds and does not own.
     *
     * **A liability, never working capital**, and the owner's ruling rather than an inference. It
     * is read from this pool's `ProfitRelease` rows less what those people have since withdrawn,
     * which is the closest an honest per-pool figure can get: a wallet is shared across every pool
     * a man is in, so a withdrawal cannot be attributed to one of them.
     *
     * The attribution is therefore proportional and is stated as such — the company-wide identity
     * in §6.5 is the one that adds up exactly, and it is the sum over pools of this figure.
     */
    private function undrawnProfitOwed(int $poolId): string
    {
        $released = $this->ledgerMovements($poolId)['profit_released'];

        $releasedEverywhere = Money::round((string) (DB::table('investor_wallet_entries')
            ->where('type', WalletEntryType::ProfitRelease->value)
            ->whereNull('deleted_at')
            ->sum('amount') ?: '0'));

        if (bccomp($releasedEverywhere, '0', 2) === 0) {
            return '0.00';
        }

        $withdrawn = Money::round((string) (DB::table('investor_wallet_entries')
            ->where('type', WalletEntryType::ProfitWithdrawal->value)
            ->whereNull('deleted_at')
            ->sum('amount') ?: '0'));

        $outstanding = bcsub($releasedEverywhere, $withdrawn, 2);

        if (bccomp($outstanding, '0', 2) <= 0) {
            return '0.00';
        }

        // This pool's share of what is still owed, by the weight of what it released.
        return Money::round(bcdiv(bcmul($outstanding, $released, 8), $releasedEverywhere, 2));
    }

    /**
     * When the next review falls due — the last settlement plus the interval.
     *
     * **Derived, never stored**, which is what makes «مدة التسوية» a setting that can be changed
     * without rewriting history: shorten the cycle and the next date moves; a settlement already
     * signed keeps the date it was signed on.
     *
     * A pool nobody has ever settled is **not** overdue. It has no last settlement to count from,
     * and inventing one — from the pool's opening, say — would put a red mark on every new pool
     * from the day it was created, which is how people learn to ignore a red mark.
     *
     * @return array{last_settled_on: ?string, next_settlement_due_on: ?string, settlement_is_overdue: bool, settlement_period_months: int}
     */
    private function dueDates(int $poolId): array
    {
        $months = $this->settings->settlementPeriodMonths();

        $last = DB::table('investment_settlements')
            ->where('investor_deal_id', $poolId)
            ->whereNull('deleted_at')
            ->max('settled_on');

        if ($last === null) {
            return [
                'last_settled_on' => null,
                'next_settlement_due_on' => null,
                'settlement_is_overdue' => false,
                'settlement_period_months' => $months,
            ];
        }

        // `addMonthsNoOverflow` so a settlement signed on the 31st falls due on the 28th of a
        // short month rather than slipping into the next one — the same helper the period
        // calendar uses, for the same reason.
        $due = Carbon::parse((string) $last)->addMonthsNoOverflow($months);

        return [
            'last_settled_on' => Carbon::parse((string) $last)->toDateString(),
            'next_settlement_due_on' => $due->toDateString(),
            'settlement_is_overdue' => $due->isPast(),
            'settlement_period_months' => $months,
        ];
    }

    /** The oldest closed period no settlement has covered yet. */
    private function firstUnsettledPeriodId(int $poolId): ?int
    {
        $lastSettledTo = DB::table('investment_settlements')
            ->where('investor_deal_id', $poolId)
            ->whereNull('deleted_at')
            ->max('period_to_id');

        $id = InvestmentPeriod::query()
            ->where('investor_deal_id', $poolId)
            ->where('status', PeriodStatus::Closed->value)
            ->when($lastSettledTo !== null, fn ($q) => $q->where('id', '>', $lastSettledTo))
            ->orderBy('id')
            ->value('id');

        return $id === null ? null : (int) $id;
    }

    /** The newest closed period — the far end of what this settlement can assert about. */
    private function lastClosedPeriodId(int $poolId): ?int
    {
        $id = InvestmentPeriod::query()
            ->where('investor_deal_id', $poolId)
            ->where('status', PeriodStatus::Closed->value)
            ->orderByDesc('id')
            ->value('id');

        return $id === null ? null : (int) $id;
    }
}
