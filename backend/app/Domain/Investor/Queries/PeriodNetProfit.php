<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * What a period made — **the single definition**, read by the close and by the screen that explains
 * it.
 *
 * ```
 *   realized margin        priced draws + delivered orders, as they landed
 * − deductible expenses    is_landed = false, charged to this period
 * − damage cost            spoilage, misprints, goods ruined on a cancelled order
 * − shortage cost
 * ─────────────────────
 * = net profit                                                     may be negative
 * ```
 *
 * **One definition, because a close is an irreversible payout.** The screen that asks somebody to
 * press the button must print the same arithmetic the button then performs; two implementations of
 * this is how a person approves one figure and the ledger writes another.
 *
 * ## The two subtractions, and why they cannot be one
 *
 * **Expenses are charged to a period, not dated into one.** `investment_period_id` is written when
 * the expense is recorded, because a closed period is immutable — an October invoice bearing a
 * September date is charged to October, keeping its true `incurred_on` and a note saying where it
 * was meant for. Filtering by `incurred_on` at read time would put it back in September every time
 * the screen was redrawn.
 *
 * **Damage and shortage are dated**, because they are movements and a movement happened when it
 * happened. There is no equivalent of a late invoice: the stock left the shelf on a day, and that
 * day is in exactly one period.
 *
 * ## What is not subtracted, and must never be
 *
 * Shipping and customs typed on a purchase order arrive here as `is_landed` rows. They are **already
 * inside the cost of the layers that arrived**, so subtracting them again charges the investors for
 * one customs invoice twice. They are kept for the record and excluded from the sum — the guard is
 * {@see InvestorDealExpense::isDeducted()}, and only the server ever sets that flag.
 */
final class PeriodNetProfit
{
    /**
     * @return array{
     *     realized_margin: string,
     *     deductible_expenses: string,
     *     recorded_only_expenses: string,
     *     damage_cost: string,
     *     shortage_cost: string,
     *     net_profit: string
     * }
     */
    public function __invoke(InvestmentPeriod $period): array
    {
        $margin = $this->realizedMargin($period);
        $expenses = $this->expenses($period);
        $losses = $this->stockLosses($period);

        $net = bcsub(
            bcsub($margin, $expenses['deducted'], 2),
            bcadd($losses['damage'], $losses['shortage'], 2),
            2,
        );

        return [
            'realized_margin' => $margin,
            'deductible_expenses' => $expenses['deducted'],
            // Published beside it so the close screen can show «المسجَّل فقط» as its own total and
            // never as part of the sum — the §6.2.4 requirement, in the one place that can honour
            // it without a second query drifting from this one.
            'recorded_only_expenses' => $expenses['recorded_only'],
            'damage_cost' => $losses['damage'],
            'shortage_cost' => $losses['shortage'],
            'net_profit' => Money::round($net),
        ];
    }

    /** Everything the pool realized in this period, from both roads, already netted of corrections. */
    private function realizedMargin(InvestmentPeriod $period): string
    {
        return Money::round((string) (InvestmentRealizedEarning::query()
            ->where('investment_period_id', $period->getKey())
            ->sum('amount') ?: '0'));
    }

    /**
     * @return array{deducted: string, recorded_only: string}
     */
    private function expenses(InvestmentPeriod $period): array
    {
        $rows = InvestorDealExpense::query()
            ->where('investment_period_id', $period->getKey())
            ->get();

        $deducted = '0.00';
        $recordedOnly = '0.00';

        foreach ($rows as $expense) {
            // The one predicate, so this and the eight other read sites cannot disagree about what
            // «deducted» means: not landed, not a reversal, and not already reversed.
            if ($expense->isDeducted()) {
                $deducted = bcadd($deducted, (string) $expense->amount, 2);

                continue;
            }

            if ($expense->is_landed && $expense->reverses_expense_id === null && ! $expense->isReversed()) {
                $recordedOnly = bcadd($recordedOnly, (string) $expense->amount, 2);
            }
        }

        return ['deducted' => $deducted, 'recorded_only' => $recordedOnly];
    }

    /**
     * Damage and shortage off this pool's layers, **within this period's dates**.
     *
     * Scoped by the movement's own timestamp rather than by anything stored on it: a movement
     * happened when it happened, and it falls in exactly one period.
     *
     * The same bucketing {@see DealStockPosition} uses, and deliberately the same shape — a draw
     * that a live reversal undid is walked past whole, and an internal transfer is not a loss at
     * all: its stock is sitting in the destination layer carrying the same pool.
     *
     * @return array{damage: string, shortage: string}
     */
    private function stockLosses(InvestmentPeriod $period): array
    {
        $rows = DB::table('stock_batch_consumptions as c')
            ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
            ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
            ->where('b.investor_deal_id', $period->investor_deal_id)
            ->whereNull('b.deleted_at')
            ->whereNull('c.deleted_at')
            ->whereNull('m.deleted_at')
            ->whereDate('m.created_at', '>=', $period->starts_on->toDateString())
            ->whereDate('m.created_at', '<=', $period->ends_on->toDateString())
            ->whereIn('m.movement_type', ['scrap_loss', 'adjustment'])
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_movements as r')
                ->whereColumn('r.reverses_movement_id', 'm.id')
                ->whereNull('r.deleted_at'))
            ->selectRaw('m.movement_type, m.adjustment_reason, m.from_warehouse_id, SUM(c.total_cost) as cost')
            ->groupBy('m.movement_type', 'm.adjustment_reason', 'm.from_warehouse_id')
            ->get();

        $damage = '0.00';
        $shortage = '0.00';

        foreach ($rows as $row) {
            $bucket = $this->bucketOf(
                (string) $row->movement_type,
                $row->adjustment_reason === null ? null : (string) $row->adjustment_reason,
                $row->from_warehouse_id === null ? null : (int) $row->from_warehouse_id,
            );

            if ($bucket === 'damaged') {
                $damage = bcadd($damage, (string) $row->cost, 2);
            }

            if ($bucket === 'short') {
                $shortage = bcadd($shortage, (string) $row->cost, 2);
            }
        }

        return ['damage' => $damage, 'shortage' => $shortage];
    }

    /**
     * The same mapping {@see DealStockPosition::bucketOf()} makes, for the two buckets that cost a
     * period money.
     *
     * `unit_change` maps to nothing: it is the write-down `SetStockItemUnit` posts for itself, and
     * it cannot occur on a funded shelf because that action refuses one.
     */
    private function bucketOf(string $type, ?string $reason, ?int $fromWarehouse): ?string
    {
        if ($type === 'scrap_loss') {
            return 'damaged';
        }

        if ($type !== 'adjustment' || $fromWarehouse === null) {
            return null;
        }

        return match ($reason) {
            'damage' => 'damaged',
            'shortage', 'count_correction' => 'short',
            default => null,
        };
    }

    /**
     * Whether the period has anything unanswered holding its close up.
     *
     * Not part of the arithmetic, but asked in the same breath by everything that calls this — the
     * close, to refuse; the screen, to explain why the button is disabled.
     */
    public function hasUnansweredReturns(InvestmentPeriod $period): bool
    {
        return DB::table('investment_returned_goods_questions')
            ->where('investor_deal_id', $period->investor_deal_id)
            ->where('verdict', 'open')
            ->whereNull('deleted_at')
            ->exists();
    }
}
