<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Enums\FundExpenseChargeKind;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * ما وقع من مصروفٍ على البضاعة في كل فترة — القاعدةُ الواحدة التي تعدّ بها الشاشاتُ والإقفال.
 *
 * Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٨. **مصروفُ الفترة من مصروفٍ على البضاعة هو صفوفُ
 * المبيعات والتقريب المختومةُ بها** — ما حُمِّل وما رُدّ، كلٌّ في فترته. وما رفع تكلفةَ الرفّ ليس
 * مصروفَ فترةٍ أبداً: يظهر في «تكلفة البضاعة المباعة» يومَ تُباع.
 *
 * يقرؤه {@see CloseInvestmentPeriod::expensesOf()} و
 * {@see PeriodExpensesQuery} و{@see FundExpensesQuery} — فلا يختلف رقمان على مصروفٍ واحد.
 */
final class GoodsExpenseCharges
{
    /** صفوفٌ تُعدّ في الفترات. */
    private const CHARGED = [FundExpenseChargeKind::Consumer->value, FundExpenseChargeKind::Rounding->value];

    /**
     * صافي ما وقع في الفترة من كل مصروفٍ على البضاعة.
     *
     * @return array<int, string> المصروف ← المبلغ
     */
    public function amountsIn(InvestmentPeriod $period, ?int $fundId = null): array
    {
        $rows = DB::table('fund_expense_charges as f')
            ->join('investor_deal_expenses as x', 'x.id', '=', 'f.investor_deal_expense_id')
            ->whereNull('f.deleted_at')
            ->whereNull('x.deleted_at')
            ->whereIn('f.kind', self::CHARGED)
            ->when($fundId !== null, fn ($q) => $q->where('x.investor_deal_id', $fundId))
            ->where(fn ($q) => $q
                ->where('f.investment_period_id', $period->getKey())
                // صفٌّ لم تسعه فترةٌ يومَ كُتب — تطالب به الفترةُ التي تسع يومَه، كصفوف المحافظ.
                ->orWhere(fn ($unstamped) => $unstamped
                    ->whereNull('f.investment_period_id')
                    ->whereBetween('f.charged_on', [$period->starts_on->toDateString(), $period->ends_on->toDateString()])))
            ->groupBy('f.investor_deal_expense_id')
            ->get(['f.investor_deal_expense_id', DB::raw('SUM(f.amount) as amount')]);

        $amounts = [];

        foreach ($rows as $row) {
            $amounts[(int) $row->investor_deal_expense_id] = Money::round((string) $row->amount);
        }

        return $amounts;
    }

    /** مجموعُ ما وقع في الفترة من كل المصاريف على البضاعة. */
    public function totalIn(InvestmentPeriod $period, ?int $fundId = null): string
    {
        return Money::sum(...array_values($this->amountsIn($period, $fundId)) ?: ['0']);
    }

    /**
     * كيف انقسم كلُّ مصروف يومَ سُجِّل: على البضاعة، وعلى المبيعات — من صفوفه الأصلية لا عكوسها.
     *
     * @param  list<int>  $expenseIds
     * @return array<int, array{on_goods: string, on_sales: string}>
     */
    public function splitOf(array $expenseIds): array
    {
        if ($expenseIds === []) {
            return [];
        }

        $rows = DB::table('fund_expense_charges')
            ->whereIn('investor_deal_expense_id', $expenseIds)
            ->whereNull('deleted_at')
            ->whereNull('reverses_charge_id')
            ->where('amount', '>=', 0)
            ->groupBy('investor_deal_expense_id', 'kind')
            ->get(['investor_deal_expense_id', 'kind', DB::raw('SUM(amount) as amount')]);

        $split = [];

        foreach ($rows as $row) {
            $id = (int) $row->investor_deal_expense_id;
            $split[$id] ??= ['on_goods' => '0.00', 'on_sales' => '0.00'];
            $key = $row->kind === FundExpenseChargeKind::Shelf->value ? 'on_goods' : 'on_sales';
            $split[$id][$key] = Money::round(bcadd($split[$id][$key], (string) $row->amount, 2));
        }

        return $split;
    }

    /**
     * «من كم لكم» — تكلفةُ وحدة كلِّ مادةٍ قبل المصروف وبعده، وكم كان منها على الرفّ يومَها.
     *
     * من صفوف الرفّ الأصلية: `unit_cost_before` كُتب لحظةَ الهبوط، والفرقُ `unit_amount`. ومادةٌ لم
     * يبقَ منها شيءٌ على الرفّ تظهر أيضاً — تكلفتُها رُفعت لما يرجع إليها، وحصتُها على المبيعات.
     *
     * @param  list<int>  $expenseIds
     * @return array<int, list<array{stock_item_id: int, name: string, unit: ?string, unit_label: ?string, quantity: string, cost_before: ?string, cost_after: ?string}>>
     */
    public function goodsOf(array $expenseIds): array
    {
        if ($expenseIds === []) {
            return [];
        }

        $rows = DB::table('fund_expense_charges as f')
            ->join('stock_batches as b', 'b.id', '=', 'f.stock_batch_id')
            ->join('stock_items as si', 'si.id', '=', 'b.stock_item_id')
            ->whereIn('f.investor_deal_expense_id', $expenseIds)
            ->where('f.kind', FundExpenseChargeKind::Shelf->value)
            ->whereNull('f.deleted_at')
            ->whereNull('f.reverses_charge_id')
            ->where('f.amount', '>=', 0)
            ->groupBy('f.investor_deal_expense_id', 'si.id', 'si.name', 'si.unit')
            ->orderBy('si.name')
            ->get([
                'f.investor_deal_expense_id',
                'si.id as stock_item_id',
                'si.name',
                'si.unit',
                DB::raw('SUM(f.quantity) as quantity'),
                DB::raw('MIN(f.unit_cost_before) as cost_before'),
                DB::raw('MIN(f.unit_amount) as delta'),
            ]);

        $goods = [];

        foreach ($rows as $row) {
            $unit = $row->unit === null ? null : PricingUnit::tryFrom((string) $row->unit);
            $before = $row->cost_before === null ? null : (string) $row->cost_before;

            $goods[(int) $row->investor_deal_expense_id][] = [
                'stock_item_id' => (int) $row->stock_item_id,
                'name' => (string) $row->name,
                'unit' => $unit?->value,
                'unit_label' => $unit?->label(),
                'quantity' => (string) $row->quantity,
                'cost_before' => $before,
                'cost_after' => $before === null ? null : bcadd($before, (string) $row->delta, 3),
            ];
        }

        return $goods;
    }
}
