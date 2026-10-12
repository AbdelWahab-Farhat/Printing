<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * «مصاريف الصندوق» — كلُّ مصاريفه في قائمةٍ واحدة، وبجانب كلٍّ فترتُه، وفلترٌ بالفترة.
 *
 * طلبُ المالك 2026-10-12: «المصاريف خليني اقدر اخش عليها من هنا مباشرة، وتعرض لي كل مصاريف
 * وبجانبها الفترة الخاصة بها واقدر افلتر حسب الفترة». كانت لا تُرى إلا فترةً فترة.
 *
 * ## فترةُ المصروف: التي يقع يومُه فيها
 *
 * قاعدةُ «مصاريف الفترة» في شاشة الفترة نفسُها ({@see PeriodExpensesQuery}): الفلترُ نافذةُ
 * الفترة على `incurred_on`، و«يُعدّ؟» يُسأل عنها بالقاعدة نفسِها — فمجموعُ القائمة مفلترةً
 * بفترةٍ هو مجموعُ تلك الشاشة بعينه. والمسجَّلُ بعد إقفال فترته يبقى فيها غيرَ معدود، كما هناك.
 *
 * ومصروفٌ بتاريخٍ قبل أوّل فترة بلا فترة، ويُعدّ في «الكل» ما لم يُعكس.
 *
 * **ولا نصيبَ لكلِّ مستثمرٍ هنا.** ذلك ما حُمِّل في فترةٍ بعينها، وشاشةُ الفترة تقوله؛ والقائمةُ
 * تفتحها بلمسة.
 */
final class FundExpensesQuery
{
    public const PER_PAGE = 20;

    public function __construct(
        private readonly FundDeal $fund,
        private readonly PeriodExpensesQuery $periodExpenses,
        private readonly GoodsExpenseCharges $goods,
    ) {}

    /**
     * @return array{
     *     rows: list<array<string, mixed>>,
     *     expenses_total: string,
     *     current_page: int,
     *     per_page: int,
     *     last_page: int,
     *     total: int
     * }
     */
    public function page(?InvestmentPeriod $period, int $page = 1, int $perPage = self::PER_PAGE): array
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return [
                'rows' => [],
                'expenses_total' => '0.00',
                'current_page' => 1,
                'per_page' => $perPage,
                'last_page' => 1,
                'total' => 0,
            ];
        }

        $periods = InvestmentPeriod::query()->orderBy('starts_on')->get();

        // مصروفٌ على البضاعة يظهر في فترةٍ بحصصه فيها — القاعدةُ نفسُها في شاشة الفترة.
        $inPeriod = $period === null ? [] : $this->goods->amountsIn($period, $fundId);

        // **المجموعُ لكل الصفحات لا لهذه** — بأعمدةٍ خفيفة، فالسؤالُ «أيُعدّ؟» يحتاج عكسَ كلٍّ ولحظةَ كتابته.
        $all = $this->originals($fundId, $period, array_keys($inPeriod))
            ->get(['id', 'amount', 'incurred_on', 'created_at', 'purchase_order_id']);
        $allReversals = $this->reversalsOf($all->pluck('id')->all());

        $total = '0';

        foreach ($all as $expense) {
            $reversal = $allReversals[(int) $expense->id] ?? null;

            if ($expense->purchase_order_id !== null) {
                $total = bcadd($total, $this->amountOf($expense, $period, $reversal, $inPeriod), 2);

                continue;
            }

            if ($this->counted($expense, $this->covering($periods, $expense), $reversal)) {
                $total = bcadd($total, (string) $expense->amount, 2);
            }
        }

        $paginator = $this->originals($fundId, $period, array_keys($inPeriod))
            ->with(['treasuryAccount:id,name', 'recordedBy:id,name'])
            ->paginate($perPage, ['*'], 'page', $page);

        $splits = $this->goods->splitOf(array_map(
            fn (InvestorDealExpense $expense): int => (int) $expense->id,
            array_filter($paginator->items(), fn (InvestorDealExpense $expense): bool => $expense->purchase_order_id !== null),
        ));

        $rows = [];

        foreach ($paginator->items() as $expense) {
            $reversal = $allReversals[(int) $expense->id] ?? null;
            $row = $this->row($expense, $this->covering($periods, $expense), $reversal);

            if ($expense->purchase_order_id !== null) {
                $row['amount'] = $this->amountOf($expense, $period, $reversal, $inPeriod);
                $row['counted'] = $period === null ? $reversal === null : true;
                $row['recorded_after_close'] = false;
                $row['split'] = $splits[(int) $expense->id] ?? ['on_goods' => '0.00', 'on_sales' => '0.00'];
            }

            $rows[] = $row;
        }

        return [
            'rows' => $rows,
            'expenses_total' => Money::round($total),
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'last_page' => $paginator->lastPage(),
            'total' => $paginator->total(),
        ];
    }

    /**
     * أصولُ مصاريف الصندوق — لا عكوسُها، ولا ما دخل تكلفةَ البضاعة. الأحدثُ أولاً.
     *
     * الشرطُ نفسُه في {@see PeriodExpensesQuery}، ونافذةُ الفترة حين يُفلتر بها — والمصاريفُ على
     * البضاعة التي لها حصصٌ في تلك الفترة، أيّاً كان يومُها.
     *
     * @param  list<int>  $onGoodsInPeriod
     * @return Builder<InvestorDealExpense>
     */
    private function originals(int $fundId, ?InvestmentPeriod $period, array $onGoodsInPeriod = []): Builder
    {
        return InvestorDealExpense::query()
            ->where('investor_deal_id', $fundId)
            ->where('is_landed', false)
            ->whereNull('reverses_expense_id')
            ->when($period, fn (Builder $q, InvestmentPeriod $p) => $q->where(fn (Builder $w) => $w
                ->where(fn (Builder $byDay) => $byDay
                    ->whereNull('purchase_order_id')
                    ->whereBetween('incurred_on', [$p->starts_on->toDateString(), $p->ends_on->toDateString()]))
                ->orWhereIn('id', $onGoodsInPeriod)))
            ->orderByDesc('incurred_on')
            ->orderByDesc('id');
    }

    /**
     * عكسُ كل مصروف، إن عُكس — واحدٌ أو لا شيء، بحكم الفهرس الفريد على `reverses_expense_id`.
     *
     * @param  list<int|string>  $ids
     * @return array<int, InvestorDealExpense>
     */
    private function reversalsOf(array $ids): array
    {
        if ($ids === []) {
            return [];
        }

        return InvestorDealExpense::query()
            ->whereIn('reverses_expense_id', $ids)
            ->get(['id', 'reverses_expense_id', 'incurred_on', 'notes', 'created_at'])
            ->keyBy(fn (InvestorDealExpense $reversal): int => (int) $reversal->reverses_expense_id)
            ->all();
    }

    /**
     * الفترةُ التي يقع يومُ المصروف فيها — من الفترات المحمولة مرّةً، لا استعلامٌ لكل سطر.
     *
     * @param  Collection<int, InvestmentPeriod>  $periods
     */
    private function covering(Collection $periods, InvestorDealExpense $expense): ?InvestmentPeriod
    {
        $day = $expense->incurred_on?->toDateString();

        if ($day === null) {
            return null;
        }

        return $periods->first(fn (InvestmentPeriod $period): bool => $period->starts_on->toDateString() <= $day
            && $period->ends_on->toDateString() >= $day);
    }

    /**
     * ما يُعدّ من مصروفٍ على البضاعة: في فترةٍ حصصُه فيها، وبلا فترةٍ كاملُه ما لم يُعكس.
     *
     * @param  array<int, string>  $inPeriod
     */
    private function amountOf(InvestorDealExpense $expense, ?InvestmentPeriod $period, ?InvestorDealExpense $reversal, array $inPeriod): string
    {
        if ($period !== null) {
            return $inPeriod[(int) $expense->id] ?? '0.00';
        }

        return $reversal === null ? (string) $expense->amount : '0.00';
    }

    /** أيُعدّ؟ — بقاعدة شاشة فترته، وبلا فترةٍ: ما لم يُعكس. */
    private function counted(InvestorDealExpense $expense, ?InvestmentPeriod $period, ?InvestorDealExpense $reversal): bool
    {
        return $period === null
            ? $reversal === null
            : $this->periodExpenses->counts($expense, $period, $reversal);
    }

    /**
     * @return array<string, mixed>
     */
    private function row(InvestorDealExpense $expense, ?InvestmentPeriod $period, ?InvestorDealExpense $reversal): array
    {
        return [
            'id' => (int) $expense->id,
            'kind' => $expense->kind->value,
            'kind_label' => $expense->kind->label(),
            'name' => (string) $expense->name,
            'amount' => (string) $expense->amount,
            'expense_amount' => (string) $expense->amount,
            'purchase_order' => $expense->purchase_order_id === null ? null : ['id' => (int) $expense->purchase_order_id],
            'split' => null,
            'incurred_on' => $expense->incurred_on?->toDateString(),
            'notes' => $expense->notes,
            'treasury_account' => $expense->treasuryAccount === null
                ? null
                : ['id' => (int) $expense->treasuryAccount->id, 'name' => (string) $expense->treasuryAccount->name],
            'recorded_by' => $expense->recordedBy === null
                ? null
                : ['id' => (int) $expense->recordedBy->id, 'name' => (string) $expense->recordedBy->name],
            'period' => $period === null ? null : [
                'id' => (int) $period->id,
                'code' => (string) $period->code,
                'status' => $period->status->value,
                'status_label' => $period->status->label(),
            ],
            'counted' => $this->counted($expense, $period, $reversal),
            'recorded_after_close' => $period !== null && $this->periodExpenses->recordedAfterClose($expense, $period),
            'is_reversed' => $reversal !== null,
            'reversal' => $reversal === null ? null : [
                'id' => (int) $reversal->id,
                'incurred_on' => $reversal->incurred_on?->toDateString(),
                'reason' => $reversal->notes,
            ],
        ];
    }
}
