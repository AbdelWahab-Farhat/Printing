<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\PurchaseFromFund;
use App\Domain\Investor\Actions\RecordFundExpense;
use App\Domain\Investor\Actions\WithdrawFromFund;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodOrdersQuery;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Queries\UnitPrice;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * الصندوق الاستثماري
 *
 * الصندوقُ واحدٌ مستمرّ، والذي يتكرّر فيه **فترةٌ محاسبية** لا صفقة. هذه النقطةُ تجيب سؤالين
 * يُقرآن معاً: كم يساوي الصندوق الآن، وأيُّ فترةٍ تستقبل القيد.
 *
 * **والقيمةُ تُعرض ببنودها لا بمجموعها وحده.** من يقرأ «٢٦٬٠٠٠» يحتاج أن يعرف كم منها نقدٌ وكم
 * بضاعةٌ على رفّ وكم بضاعةٌ في المطبعة — وإلا كان الرقمُ ادّعاءً لا حساباً.
 */
class InvestmentFundController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly FundValuation $valuation,
        private readonly OpenInvestmentPeriod $openPeriod,
        private readonly CloseInvestmentPeriod $closePeriod,
        private readonly UnitPrice $unitPrice,
        private readonly FundUnits $units,
        private readonly PeriodShares $shares,
        private readonly InvestorBalances $balances,
        private readonly DepositToFund $deposit,
        private readonly WithdrawFromFund $withdraw,
        private readonly RecordFundExpense $expense,
        private readonly PurchaseFromFund $purchase,
        private readonly PeriodOrdersQuery $periodOrders,
    ) {}

    /**
     * Read the fund's standing
     */
    public function show(): JsonResponse
    {
        $period = InvestmentPeriod::open();

        return $this->success([
            'valuation' => ($this->valuation)(),
            'period' => $period === null ? null : $this->periodPayload($period),

            // **سعرُ الوحدة على اللوحة، لا في شاشةٍ خفيّة.** هو الرقمُ الذي يشتري به الداخلُ
            // الجديد، فمن يقبض مالاً من مستثمرٍ اليوم يحتاج أن يراه قبل أن يكتب.
            'unit_price' => ($this->unitPrice)(),
            'units_outstanding' => $this->units->outstanding(),
            'investors' => $this->holders($period),

            // **ما يمكن أن يشترك به كلُّ واحد اليوم.** الشاشةُ تحتاجه قبل أن يُكتب رقم: السقفُ
            // رصيدُ محفظته، ومن يكتب فوقه يُردّ بعد أن كتب. وهو رصيدٌ لا تعرفه إلا الخوادم —
            // زميلٌ سجّل سحباً قبل ثانية.
            'subscribable' => $this->subscribable(),
        ]);
    }

    /**
     * Subscribe wallet capital into the fund
     *
     * **ولا `method` هنا.** المالُ في المحفظة منذ أن سُلِّم على الطاولة بطريقة دفعٍ سُمّيت
     * هناك؛ وهذا نقلٌ داخليّ لا يعبر فيه دينارٌ يداً. وسقفُه رصيدُ محفظته — قرارُ المالك:
     * «مش أي رقم يقبل، لين يكون في محفظة المستثمر».
     */
    public function storeDeposit(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'investor_id' => ['required', 'integer', 'exists:investors,id'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $result = ($this->deposit)(
            investorId: (int) $validated['investor_id'],
            amount: (string) $validated['amount'],
            actorId: $request->user()?->id,
            notes: $validated['notes'] ?? null,
        );

        $units = $result['units'];

        return $this->success(
            [
                'units' => (string) $units->units,
                'unit_price' => (string) $units->unit_price,
                'locked_until' => $units->locked_until?->toDateString(),
            ],
            "دخل المال: {$units->units} وحدة بسعر {$units->unit_price} د.ل، محبوسةٌ إلى {$units->locked_until?->toDateString()}",
        );
    }

    /**
     * Redeem capital out of the fund, back into the wallet
     *
     * **ولا `method` هنا كذلك**: المالُ يرجع إلى محفظته لا إلى يده. وما يخرج نقداً حركةٌ ثالثة
     * تُسجَّل من شاشة محفظته، فهناك يقرّر أيأخذه أم يعيد الاشتراك به.
     */
    public function storeWithdrawal(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'investor_id' => ['required', 'integer', 'exists:investors,id'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $result = ($this->withdraw)(
            investorId: (int) $validated['investor_id'],
            amount: (string) $validated['amount'],
            actorId: $request->user()?->id,
            notes: $validated['notes'] ?? null,
        );

        return $this->success(
            ['units_cancelled' => (string) $result['units']->units],
            'رجع رأسُ المال إلى محفظته وأُلغيت وحداتُه — فلا نسبةَ بلا مال',
        );
    }

    /**
     * Record an expense against the fund
     */
    public function storeExpense(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'kind' => ['required', 'string', 'in:'.implode(',', array_column(DealExpenseKind::cases(), 'value'))],
            'name' => ['required', 'string', 'max:150'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'incurred_on' => ['required', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $expense = ($this->expense)(
            new DealExpenseData(
                kind: DealExpenseKind::from($validated['kind']),
                name: $validated['name'],
                amount: (string) $validated['amount'],
                incurredOn: $validated['incurred_on'],
                notes: $validated['notes'] ?? null,
            ),
            $request->user()?->id,
        );

        return $this->success(
            ['id' => $expense->id, 'amount' => (string) $expense->amount],
            'سُجِّل المصروف وخرج من الخزينة',
        );
    }

    /**
     * Buy a purchase order with the fund's cash
     *
     * **وسعرُ السادة يُسأل هنا أو لا يُسأل أبداً.** هو شرطُ شراءٍ يُجمَّد على السطر لحظةَ
     * المطالبة به، فلا موضعَ ثانياً يُكتب فيه بعد أن تصير البضاعةُ طبقةَ تكلفة.
     */
    public function purchase(Request $request, int $purchase_order): JsonResponse
    {
        $validated = $request->validate([
            'stock_item_ids' => ['nullable', 'array'],
            'stock_item_ids.*' => ['integer', 'exists:stock_items,id'],

            // **سعرُ السادة لكل رفّ، والمفتاحُ رقمُ المادة.** رفٌّ بلا سعرٍ هنا يمشي على الطريق
            // الآخر — يركب البيعَ إلى التسليم — وهو ما كان يفعله كلُّ رفٍّ قبل اليوم، فالغيابُ
            // هو التصرّف القديم بعينه لا نقصاً في الطلب.
            //
            // و`min:0.001` لا `min:0`: صفرٌ يمرّ من التحقّق ثم يصطدم بـCHECK في قاعدة البيانات
            // فيخرج 500 بدل رسالةٍ يقرأها إنسان. نفسُ حدّ {@see FundPurchaseOrderRequest}.
            'printing_sale_prices' => ['nullable', 'array'],
            'printing_sale_prices.*' => ['nullable', 'numeric', 'min:0.001', 'max:999999999'],
        ]);

        $prices = [];

        foreach ($validated['printing_sale_prices'] ?? [] as $stockItemId => $price) {
            if ($price !== null && $price !== '') {
                $prices[(int) $stockItemId] = (string) $price;
            }
        }

        $deal = ($this->purchase)(
            $purchase_order,
            $validated['stock_item_ids'] ?? null,
            $request->user()?->id,
            $prices,
        );

        return $this->success(
            ['deal_id' => $deal->id, 'shelves' => $deal->items->count()],
            'اشترى الصندوقُ الأمرَ — خرج النقدُ وصارت رفوفُه من مواده',
        );
    }

    /**
     * List the periods
     */
    public function periods(): JsonResponse
    {
        $periods = InvestmentPeriod::query()->orderByDesc('starts_on')->limit(60)->get();

        return $this->success(
            $periods->map(fn (InvestmentPeriod $period): array => $this->periodPayload($period))->all(),
        );
    }

    /**
     * The orders of one period, and what each investor took from each
     *
     * «الطلبيات التي أعطت ربح المستثمرين فيها، وربح كل مستثمر» — صفٌّ لكل طلبية، وتحته من أخذ
     * منها وكم.
     *
     * **والأرقامُ من دفتر المحافظ لا من حسابٍ ثانٍ.** هذا سؤالُ «ماذا قبض الناسُ في هذه الفترة»،
     * وجوابُه الصفوفُ التي قُبض بها؛ وإعادةُ اشتقاقه من الـFIFO بعد سنةٍ كانت تُظهر رقماً غير
     * الذي دخل الجيوب — انظر {@see PeriodOrdersQuery}.
     *
     * والفترةُ تسافر مع قائمتها فترسم الشاشةُ ترويستَها وجسمَها بنداءٍ واحد.
     */
    public function periodOrders(InvestmentPeriod $period): JsonResponse
    {
        return $this->success([
            'period' => $this->periodPayload($period),
            ...($this->periodOrders)((int) $period->getKey()),
        ]);
    }

    /**
     * رصيدُ محفظة كل مستثمرٍ نشِط — سقفُ اشتراكه اليوم.
     *
     * لكلِّهم لا لحَمَلة الوحدات وحدهم: الداخلُ الجديد هو بالضبط من لا وحداتِ له، وهو من يحتاج
     * أن يُعرف سقفُه قبل أن يُكتب له رقم.
     *
     * @return list<array<string, mixed>>
     */
    private function subscribable(): array
    {
        $investors = Investor::query()->orderBy('name')->get(['id', 'name']);

        if ($investors->isEmpty()) {
            return [];
        }

        $balances = $this->balances->forInvestors($investors->pluck('id')->map(fn ($id): int => (int) $id)->all());

        return $investors->map(fn (Investor $investor): array => [
            'investor_id' => (int) $investor->id,
            'name' => (string) $investor->name,
            'wallet_capital' => $balances[(int) $investor->id]['wallet_capital'] ?? '0.00',
            'wallet_profit' => $balances[(int) $investor->id]['wallet_profit'] ?? '0.00',
        ])->all();
    }

    /**
     * كلُّ من يملك وحداتٍ الآن: نسبتُه في الفترة الجارية، ورأسُ ماله، وربحُه.
     *
     * **ثلاثةُ أرقامٍ لا رقمٌ واحد.** «نسبتُه» تقول ماذا سيأخذ من ربح هذا الشهر، و«رأسُ ماله»
     * ماذا وضع، و«ربحُه» ماذا أخذ ولم يسحبه. جمعُها في عمودٍ واحد يُخفي أيَّها يتحرّك.
     *
     * @return list<array<string, mixed>>
     */
    private function holders(?InvestmentPeriod $period): array
    {
        $units = $this->units->byInvestor();

        if ($units === []) {
            return [];
        }

        $ids = array_keys($units);
        $shares = $period === null ? [] : $this->shares->forPeriod((int) $period->getKey());
        $balances = $this->balances->forInvestors($ids);
        $names = Investor::query()->whereIn('id', $ids)->pluck('name', 'id');

        $rows = [];

        foreach ($ids as $id) {
            $rows[] = [
                'investor_id' => $id,
                'name' => (string) ($names[$id] ?? ''),
                'units' => $units[$id],
                'share_percent' => $shares[$id] ?? '0.000000',
                'capital' => $balances[$id]['capital'] ?? '0.00',
                'profit' => $balances[$id]['profit'] ?? '0.00',
            ];
        }

        usort($rows, fn (array $a, array $b): int => bccomp($b['units'], $a['units'], 6));

        return $rows;
    }

    /**
     * Open an accounting period
     */
    public function openPeriod(Request $request): JsonResponse
    {
        $period = ($this->openPeriod)($request->user()?->id);

        return $this->success(
            $this->periodPayload($period),
            "فُتحت الفترة «{$period->code}» على رصيد ما قبلها — ولم يُصفَّر شيء",
        );
    }

    /**
     * Close the running period
     */
    public function closePeriod(Request $request): JsonResponse
    {
        $validated = $request->validate([
            // **تجاوزٌ مُسبَّب لا تجاوزٌ صامت.** الطلبيةُ العالقة أو الإنهاءُ المبكّر بابٌ يُفتح
            // باسم من فتحه وسببه، ويُكتب على صفّ الفترة إلى الأبد.
            'override_reason' => ['nullable', 'string', 'min:10', 'max:500'],
        ], [
            'override_reason.min' => 'سبب التجاوز يُكتب كاملاً، لا كلمةً واحدة',
        ]);

        $period = ($this->closePeriod)(
            $request->user()?->id,
            $validated['override_reason'] ?? null,
        );

        return $this->success(
            $this->periodPayload($period),
            "أُقفلت الفترة «{$period->code}» — أُفرج عن الأرباح، ورأسُ المال والبضاعة في مكانهما",
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function periodPayload(InvestmentPeriod $period): array
    {
        return [
            'id' => $period->id,
            'code' => $period->code,
            'status' => $period->status->value,
            'status_label' => $period->status->label(),

            'starts_on' => $period->starts_on->toDateString(),
            'ends_on' => $period->ends_on->toDateString(),
            'subscription_closes_on' => $period->subscription_closes_on->toDateString(),

            // **يفترق عن «مستحقّة الإقفال» عن قصد.** التاريخُ يجعلها مستحقّة، والطلبياتُ التي
            // خرجت بضاعتُها ولم تُسلَّم تقرّر إن كانت تستطيع — فاللوحةُ تقول «مستحقّة منذ ٣ أيام»
            // بدل أن يصمت غيابُ الجدولة.
            'is_due_to_close' => $period->isDueToClose(now()),

            // ما كُتب على صفّها إن أُقفلت بتجاوز — يبقى على الشاشة ولا يُطوى.
            'override_reason' => $period->override_reason,

            'period_months' => $period->period_months,
            'investor_profit_share_percent' => (string) $period->investor_profit_share_percent,
            'capital_lock_months' => $period->capital_lock_months,
            'ends_settlement_cycle' => (bool) $period->ends_settlement_cycle,

            // بابُ الاكتتاب — ما يقرّر أيظهر زرُّ «إيداع» أم يظهر سببُ غيابه.
            'accepts_capital' => $period->acceptsCapitalOn(now()),

            'opening_stock_cost' => (string) $period->opening_stock_cost,
            'opening_cash' => (string) $period->opening_cash,

            'closed_at' => $period->closed_at?->toDateTimeString(),
            'net_profit' => $period->net_profit === null ? null : (string) $period->net_profit,
            'investors_pool' => $period->investors_pool === null ? null : (string) $period->investors_pool,
            'company_share' => $period->company_share === null ? null : (string) $period->company_share,
            'sales_revenue' => $period->sales_revenue === null ? null : (string) $period->sales_revenue,
            'closing_stock_cost' => $period->closing_stock_cost === null ? null : (string) $period->closing_stock_cost,
            'closing_cash' => $period->closing_cash === null ? null : (string) $period->closing_cash,
        ];
    }
}
