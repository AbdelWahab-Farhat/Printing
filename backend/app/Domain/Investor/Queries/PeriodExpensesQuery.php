<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\LandFundExpenseOnGoods;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\FundExpenseCharge;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * مصاريفُ الفترة — ما خرج من الصندوق في أيامها، وما تحمّله المستثمرون منه.
 *
 * ## قائمتان لا قائمة
 *
 * ```
 * expenses     ←  مصاريفُ الصندوق المؤرّخةُ في نافذة الفترة — ما تعدّه CloseInvestmentPeriod::expensesOf()
 * corrections  ←  مصاريفُ من خارج النافذة مسّت محافظَ المستثمرين في هذه الفترة:
 *                 عكسُ مصروفِ فترةٍ أُقفلت، أو مصروفٌ مؤرّخٌ في فترةٍ أُقفلت سُجِّل بعدها
 * ```
 *
 * والثانيةُ هي أرضيةُ {@see PeriodForEntry}: صفٌّ يخصّ فترةً أُقفلت يقع على المفتوحة اليوم.
 * إسقاطُها من الشاشة يترك المستثمرَ يرى في محفظته ردّاً أو تحميلاً لا يجد له سطراً هنا.
 *
 * ## والمعكوسُ بعد الإقفال يبقى معدوداً في فترته
 *
 * **ولم يعد يقع** — مصروفُ فترةٍ أُقفلت لا يُعكس منذ 2026-10-05 ({@see ExpenseChargePeriod})؛
 * والقاعدةُ باقيةٌ لصفوفٍ عُكست قبل ذلك.
 *
 * ما أُقفلت عليه الفترةُ وُزّع مالُه بأرقامٍ مُعلنة، فعكسُه بعد ذلك لا يعود إليها — يقع ردُّه
 * على الفترة المفتوحة يومَه ويظهر في «corrections» هناك. فالسطرُ في فترته يبقى معدوداً ويقول
 * إنه عُكس لاحقاً، ومجموعُها يساوي `expenses_amount` المجمّد عليها.
 *
 * وكذلك مصروفٌ بتاريخٍ فيها كُتب بعد إقفالها: يُعرض في فترة تاريخه غيرَ معدود
 * (`recorded_after_close`)، ويظهر تحميلُه في «corrections» الفترةِ التي وقع عليها.
 *
 * ## وما على المستثمرين من دفتر المحافظ لا من حساب
 *
 * صفوفُ `loss` المختومةُ بهذه الفترة — التي قُبض بها فعلاً. حسابُها من النسبة ثانيةً كان يُظهر
 * رقماً يخالف ما نقص من المحافظ يوم تتغيّر نسبة.
 */
final class PeriodExpensesQuery
{
    public function __construct(
        private readonly FundDeal $fund,
        private readonly ExpenseChargePeriod $chargePeriod,
        private readonly GoodsExpenseCharges $goods,
        private readonly LandFundExpenseOnGoods $onGoods,
    ) {}

    /**
     * @return array{
     *     expenses: list<array<string, mixed>>,
     *     corrections: list<array<string, mixed>>,
     *     totals: array{expenses_total: string, investors_total: string, frozen_total: ?string}
     * }
     */
    public function __invoke(InvestmentPeriod $period): array
    {
        $fundId = $this->fund->idOrNull();
        $frozen = $period->status === PeriodStatus::Closed && $period->expenses_amount !== null
            ? (string) $period->expenses_amount
            : null;

        if ($fundId === null) {
            return [
                'expenses' => [],
                'corrections' => [],
                'totals' => ['expenses_total' => '0.00', 'investors_total' => '0.00', 'frozen_total' => $frozen],
            ];
        }

        // المستثمر ← المبلغ، لكل مصروفٍ مسّ محافظَهم في هذه الفترة. موجبٌ ما حُمِّلوه، وسالبٌ ما رُدّ.
        $charges = $this->chargesIn((int) $period->getKey(), $fundId);

        $inWindow = $this->originals($fundId)
            ->whereNull('purchase_order_id')
            ->whereBetween('incurred_on', [$period->starts_on->toDateString(), $period->ends_on->toDateString()])
            ->get();

        // **مصروفٌ على البضاعة بحصصه في هذه الفترة لا بيومه** (FUND-EXPENSE-ON-GOODS §٤.٨) — ما
        // كُتب على مبيعاتها وما رُدّ إليها. وما رفع تكلفةَ الرفّ ليس مصروفَ فترة.
        $goodsAmounts = $this->goods->amountsIn($period, $fundId);
        $linked = $goodsAmounts === []
            ? collect()
            : $this->originals($fundId)->whereIn('id', array_keys($goodsAmounts))->get();

        $outside = array_diff(
            array_keys($charges),
            $inWindow->pluck('id')->map(fn ($id): int => (int) $id)->all(),
            $linked->pluck('id')->map(fn ($id): int => (int) $id)->all(),
        );

        $corrections = $outside === []
            ? collect()
            : $this->originals($fundId)->whereNull('purchase_order_id')->whereIn('id', $outside)->get();

        $all = $inWindow->concat($linked)->concat($corrections);
        $reversals = $this->reversalsOf($all);
        $reversalPeriods = $this->periodsOfRefunds($reversals);
        $names = Investor::query()
            ->whereIn('id', collect($charges)->flatMap(fn (array $rows): array => array_keys($rows))->unique()->all())
            ->pluck('name', 'id');

        $expenseRows = $inWindow
            ->concat($linked)
            ->sortByDesc(fn (InvestorDealExpense $expense): string => $expense->incurred_on?->toDateString().sprintf('%012d', $expense->id))
            ->map(fn (InvestorDealExpense $expense): array => $this->row(
                $expense,
                $period,
                $reversals[(int) $expense->id] ?? null,
                $reversalPeriods,
                $charges[(int) $expense->id] ?? [],
                $names,
                $goodsAmounts[(int) $expense->id] ?? null,
            ))
            ->all();

        $correctionRows = $corrections
            ->map(fn (InvestorDealExpense $expense): array => $this->row(
                $expense,
                $period,
                $reversals[(int) $expense->id] ?? null,
                $reversalPeriods,
                $charges[(int) $expense->id] ?? [],
                $names,
            ))
            ->all();

        $expensesTotal = '0';

        foreach ($expenseRows as $row) {
            if ($row['counted']) {
                $expensesTotal = bcadd($expensesTotal, $row['amount'], 2);
            }
        }

        $investorsTotal = '0';

        foreach ($charges as $rows) {
            foreach ($rows as $amount) {
                $investorsTotal = bcadd($investorsTotal, $amount, 8);
            }
        }

        return [
            'expenses' => array_values($expenseRows),
            'corrections' => array_values($correctionRows),
            'totals' => [
                'expenses_total' => Money::round($expensesTotal),
                'investors_total' => Money::round($investorsTotal),
                'frozen_total' => $frozen,
            ],
        ];
    }

    /**
     * ما تحمّله المستثمرون من المصاريف في هذه الفترة — سطرُ «منها على المستثمرين» في أرقامها.
     *
     * مجموعُ `investors_total` نفسُه بنداءٍ واحد لا بمشي الصفوف: سجلُّ الفترات يرسمه لكل فترةٍ
     * مغلقة. صفوفُ التحميل `loss`، وعكوسُها تُطرح — ولا نوعَ ثالثاً يكتبه مصروف.
     */
    public function investorsShareOf(InvestmentPeriod $period): string
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return '0.00';
        }

        $total = DB::table('investor_wallet_entries as w')
            ->leftJoin('investor_wallet_entries as o', 'o.id', '=', 'w.reverses_entry_id')
            ->join('investor_deal_expenses as x', 'x.id', '=', DB::raw('coalesce(o.source_id, w.source_id)'))
            ->where('x.investor_deal_id', $fundId)
            ->where('w.investment_period_id', $period->getKey())
            ->whereNull('w.deleted_at')
            ->whereRaw('coalesce(o.source_type, w.source_type) = ?', [AuditSubject::InvestorDealExpense->value])
            ->whereRaw('coalesce(o.type, w.type) = ?', [WalletEntryType::Loss->value])
            ->sum(DB::raw("case when w.type = 'reversal' then -w.amount else w.amount end"));

        // وحصصُ المصاريف على البضاعة — مصدرُها الصفّ، ومصروفُها من خلفه. الخسارةُ تُحمَّل والربحُ
        // ردٌّ لما حملته تكلفةُ بضاعةٍ بِيعت ثم عُكس مصروفُها، فيُطرح.
        $onGoods = DB::table('investor_wallet_entries as w')
            ->leftJoin('investor_wallet_entries as o', 'o.id', '=', 'w.reverses_entry_id')
            ->join('fund_expense_charges as f', 'f.id', '=', DB::raw('coalesce(o.source_id, w.source_id)'))
            ->join('investor_deal_expenses as x', 'x.id', '=', 'f.investor_deal_expense_id')
            ->where('x.investor_deal_id', $fundId)
            ->where('w.investment_period_id', $period->getKey())
            ->whereNull('w.deleted_at')
            ->whereRaw('coalesce(o.source_type, w.source_type) = ?', [AuditSubject::FundExpenseCharge->value])
            ->sum(DB::raw("case coalesce(o.type, w.type) when 'loss' then 1 else -1 end
                * case when w.type = 'reversal' then -w.amount else w.amount end"));

        return Money::round(bcadd((string) ($total ?? '0'), (string) ($onGoods ?? '0'), 8));
    }

    /**
     * أصولُ مصاريف الصندوق — لا عكوسُها، ولا ما دخل تكلفةَ البضاعة. الأحدثُ أولاً.
     *
     * @return Builder<InvestorDealExpense>
     */
    private function originals(int $fundId): Builder
    {
        return InvestorDealExpense::query()
            ->with(['treasuryAccount:id,name', 'recordedBy:id,name'])
            ->where('investor_deal_id', $fundId)
            ->where('is_landed', false)
            ->whereNull('reverses_expense_id')
            ->orderByDesc('incurred_on')
            ->orderByDesc('id');
    }

    /**
     * ما تحمّله كلُّ مستثمرٍ من كل مصروفٍ في هذه الفترة — من صفوفها المختومة بها.
     *
     * العكسُ لا يحمل مصدراً بنفسه في كل حال، فمصدرُه مصدرُ ما عكسه — كما في {@see PeriodOrdersQuery}.
     *
     * **ومصاريفُ الصندوق وحدها.** صفوفُ صفقةٍ قديمة مفتوحة تُختم بالفترة كذلك
     * ({@see CloseInvestmentPeriod::claimUnstamped()})، ومستثمروها غيرُ مستثمري الصندوق.
     *
     * @return array<int, array<int, string>> المصروف ← المستثمر ← المبلغ (موجبٌ = حُمِّل)
     */
    private function chargesIn(int $periodId, int $fundId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investment_period_id', $periodId)
            ->get();

        // حصصُ المصاريف على البضاعة مصدرُها الصفُّ لا المصروف — فتُردّ إلى مصروفها.
        $chargeIds = $entries
            ->map(fn (InvestorWalletEntry $entry) => $entry->type === WalletEntryType::Reversal ? $entry->reversedEntry : $entry)
            ->filter(fn (?InvestorWalletEntry $origin): bool => $origin?->source_type === AuditSubject::FundExpenseCharge->value)
            ->map(fn (InvestorWalletEntry $origin): int => (int) $origin->source_id)
            ->unique()
            ->all();
        $expenseOfCharge = $chargeIds === []
            ? []
            : FundExpenseCharge::query()->whereIn('id', $chargeIds)->pluck('investor_deal_expense_id', 'id')->all();

        $charges = [];

        foreach ($entries as $entry) {
            $origin = $entry->type === WalletEntryType::Reversal ? $entry->reversedEntry : $entry;

            $expenseId = match ($origin?->source_type) {
                AuditSubject::InvestorDealExpense->value => (int) $origin->source_id,
                AuditSubject::FundExpenseCharge->value => (int) ($expenseOfCharge[(int) $origin->source_id] ?? 0),
                default => 0,
            };

            if ($expenseId === 0) {
                continue;
            }

            $investorId = (int) $entry->investor_id;

            // `profit_deal` يهبط بالتحميل، فالتحميلُ عكسُ إشارته.
            $charges[$expenseId][$investorId] = bcsub(
                $charges[$expenseId][$investorId] ?? '0',
                $entry->deltas()['profit_deal'],
                8,
            );
        }

        if ($charges === []) {
            return [];
        }

        $theFunds = InvestorDealExpense::query()
            ->where('investor_deal_id', $fundId)
            ->whereIn('id', array_keys($charges))
            ->pluck('id')
            ->map(fn ($id): int => (int) $id)
            ->all();

        return array_intersect_key($charges, array_flip($theFunds));
    }

    /**
     * عكسُ كل مصروف، إن عُكس — واحدٌ أو لا شيء، بحكم الفهرس الفريد على `reverses_expense_id`.
     *
     * @param  Collection<int, InvestorDealExpense>  $expenses
     * @return array<int, InvestorDealExpense>
     */
    private function reversalsOf(Collection $expenses): array
    {
        if ($expenses->isEmpty()) {
            return [];
        }

        return InvestorDealExpense::query()
            ->whereIn('reverses_expense_id', $expenses->pluck('id')->all())
            ->get()
            ->keyBy(fn (InvestorDealExpense $reversal): int => (int) $reversal->reverses_expense_id)
            ->all();
    }

    /**
     * في أيّ فترةٍ وقع ردُّ كلِّ عكس — من صفوف الردّ نفسِها، وإلا فالفترةُ التي تسع يومَه.
     *
     * @param  array<int, InvestorDealExpense>  $reversals
     * @return array<int, string|null> المصروف الأصلي ← رمز الفترة
     */
    private function periodsOfRefunds(array $reversals): array
    {
        if ($reversals === []) {
            return [];
        }

        $stamped = InvestorWalletEntry::query()
            ->where('type', WalletEntryType::Reversal->value)
            ->whereNotNull('investment_period_id')
            ->whereHas('reversedEntry', fn ($q) => $q
                ->where('source_type', AuditSubject::InvestorDealExpense->value)
                ->whereIn('source_id', array_keys($reversals)))
            ->with('reversedEntry:id,source_id')
            ->get(['id', 'reverses_entry_id', 'investment_period_id']);

        $periodIds = [];

        foreach ($stamped as $entry) {
            $periodIds[(int) $entry->reversedEntry->source_id] = (int) $entry->investment_period_id;
        }

        $codes = InvestmentPeriod::query()->whereIn('id', array_values($periodIds))->pluck('code', 'id');

        $result = [];

        foreach ($reversals as $expenseId => $reversal) {
            $result[$expenseId] = isset($periodIds[$expenseId])
                ? (string) ($codes[$periodIds[$expenseId]] ?? '')
                : InvestmentPeriod::covering($reversal->incurred_on)?->code;
        }

        return $result;
    }

    /**
     * @param  array<int, string|null>  $reversalPeriods
     * @param  array<int, string>  $charges
     * @param  Collection<int|string, mixed>  $names
     * @return array<string, mixed>
     */
    private function row(
        InvestorDealExpense $expense,
        InvestmentPeriod $period,
        ?InvestorDealExpense $reversal,
        array $reversalPeriods,
        array $charges,
        Collection $names,
        ?string $amountInPeriod = null,
    ): array {
        $onGoods = $expense->purchase_order_id !== null;
        $investors = [];
        $investorsTotal = '0';

        foreach ($charges as $investorId => $amount) {
            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            $investorsTotal = bcadd($investorsTotal, $amount, 8);
            $investors[] = [
                'investor_id' => $investorId,
                'name' => (string) ($names[$investorId] ?? ''),
                'amount' => Money::round($amount),
            ];
        }

        usort($investors, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2));

        return [
            'id' => (int) $expense->id,
            'kind' => $expense->kind->value,
            'kind_label' => $expense->kind->label(),
            'name' => (string) $expense->name,
            // مصروفٌ على البضاعة: ما وقع منه في هذه الفترة؛ وكاملُه في `expense_amount`.
            'amount' => $onGoods ? ($amountInPeriod ?? '0.00') : (string) $expense->amount,
            'expense_amount' => (string) $expense->amount,
            'purchase_order' => $onGoods ? ['id' => (int) $expense->purchase_order_id] : null,
            'incurred_on' => $expense->incurred_on?->toDateString(),
            'notes' => $expense->notes,
            'treasury_account' => $expense->treasuryAccount === null
                ? null
                : ['id' => (int) $expense->treasuryAccount->id, 'name' => (string) $expense->treasuryAccount->name],
            'recorded_by' => $expense->recordedBy === null
                ? null
                : ['id' => (int) $expense->recordedBy->id, 'name' => (string) $expense->recordedBy->name],
            'counted' => $onGoods ? $amountInPeriod !== null : $this->counts($expense, $period, $reversal),
            'recorded_after_close' => $this->recordedAfterClose($expense, $period),
            'reversal' => $reversal === null ? null : [
                'id' => (int) $reversal->id,
                'incurred_on' => $reversal->incurred_on?->toDateString(),
                'reason' => $reversal->notes,
                'period_code' => $reversalPeriods[(int) $expense->id] ?? null,
            ],
            'is_reversed' => $reversal !== null,

            // **الخادمُ يقول أيُعكس** — الحارسُ نفسُه الذي يرفض العكس، لا نسخةٌ منه في التطبيق.
            // ولا تكاليفُ وصول أمر شراء: تتبع استلامَها، وتُعكس بالتراجع عنه.
            'can_reverse' => $reversal === null
                && ($onGoods
                    ? $this->onGoods->closedPeriodTouchedBy($expense) === null
                    : ! $this->chargePeriod->isClosed($expense))
                && $expense->source_type !== AuditSubject::PurchaseOrderAdditionalCost->value,

            // **ما تحمّله المستثمرون منه في هذه الفترة** — موجبٌ ما حُمِّلوه، وسالبٌ ما رُدّ إليهم.
            'investors_amount' => Money::round($investorsTotal),
            'investors' => $investors,
        ];
    }

    /**
     * أيُعدّ في مصاريف هذه الفترة؟ — القاعدةُ التي يعدّ بها الإقفال، مقروءةً على حالها اليوم.
     *
     * يُعدّ ما لم يُعكس، وما عُكس **بعد** أن أُقفلت فترتُه: الإقفالُ عدّه يومها، وردُّه وقع على
     * غيرها. ومصروفٌ من خارج النافذة لا يُعدّ هنا أبداً — مكانُه مصاريفُ فترة تاريخه.
     *
     * **عامّةٌ لأن قائمةَ مصاريف الصندوق تقرؤها** ({@see FundExpensesQuery}): مجموعُها مفلترةً
     * بفترةٍ هو مجموعُ هذه الشاشة، والقاعدةُ في موضعٍ واحد لا يختلفان عليه.
     */
    public function counts(InvestorDealExpense $expense, InvestmentPeriod $period, ?InvestorDealExpense $reversal): bool
    {
        $date = $expense->incurred_on?->toDateString();

        if ($date === null || $date < $period->starts_on->toDateString() || $date > $period->ends_on->toDateString()) {
            return false;
        }

        // سُجِّل بعد أن أُقفلت: الإقفالُ لم يره، وتحميلُه وقع على المفتوحة يومَ سُجِّل.
        if ($this->recordedAfterClose($expense, $period)) {
            return false;
        }

        if ($reversal === null) {
            return true;
        }

        return $period->status === PeriodStatus::Closed
            && $period->closed_at !== null
            && $reversal->created_at !== null
            && $reversal->created_at->gte($period->closed_at);
    }

    /** مصروفٌ بتاريخٍ في فترةٍ أُقفلت، كُتب بعد إقفالها — {@see PeriodForEntry} أنزله على المفتوحة. */
    public function recordedAfterClose(InvestorDealExpense $expense, InvestmentPeriod $period): bool
    {
        return $period->status === PeriodStatus::Closed
            && $period->closed_at !== null
            && $expense->created_at !== null
            && $expense->created_at->gte($period->closed_at);
    }
}
