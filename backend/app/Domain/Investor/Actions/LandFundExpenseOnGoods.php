<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Inventory\Actions\ApplyStockChange;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Investor\Enums\FundExpenseChargeKind;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Exceptions\PurchaseOrderBroughtTheFundNothing;
use App\Domain\Investor\Models\FundExpenseCharge;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\PurchaseOrderFundUnits;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Support\LargestRemainder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * مصروفُ الصندوق على البضاعة — يتبع البضاعةَ لا تاريخَه.
 *
 * المواصفة: Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md. قراراتُ المالك 2026-10-12:
 *
 * - المصروفُ المربوطُ بطلب شراءٍ **يتوزّع على كل وحدةٍ أدخلها الطلب للصندوق، بِيعت أو لم تُبع** —
 *   على البنود بقيمة ما وصل منها، ثم على وحدات كل بند.
 * - **حصةُ ما على الرفّ تدخل تكلفتَه**: كلُّ طبقةٍ من البند ترتفع `unit_cost` بمقدار Δ، فيحملها من
 *   يقاسم ربحَ بيعها لاحقاً — قديماً كان أو جديداً — ولا تُكتب على أحدٍ الآن.
 * - **حصةُ ما بِيع تُكتب على فترة البيع** بنسب مستثمريها، صفّاً لكل (حركة، طبقة)
 *   ({@see PostFundExpenseCharge}). والمغلقةُ تقع على المفتوحة.
 *
 * **Δ يُقرَّب لأسفل إلى ثلاث منازل** — دقةُ `unit_cost`. فما على الرفّ لا يزيد عن حصته، وفرقُ
 * الفلوس يقع على المستهلكين؛ ولا مستهلكَ ← صفُّ تقريبٍ على فترة يوم المصروف. فمجموعُ الصفوف يساوي
 * المصروفَ بقرشه دائماً.
 *
 * **كلُّ طبقات البند ترتفع، حتى الفارغة.** وحداتٌ ترجع إليها لاحقاً (إلغاءُ طلبيةٍ سحبت قبل
 * المصروف) ترجع حاملةً الفرق، وحصتُها التي كُتبت على الطلبية تُردّ في اللحظة نفسها
 * ({@see returnChargesOf()}). طبقةٌ فارغةٌ تُركت بلا Δ كانت ستُضيع تلك الحصةَ من الطرفين.
 *
 * **ترتيبُ الأقفال: أرصدةُ المخزن ثم الصندوق** — الترتيبُ الذي يأخذ به السحبُ من الرفّ أقفالَه
 * قبل أن يصل مستمعو الاستثمار. فالمنادي يأخذ {@see lockShelves()} قبل أن يقفل الصفقة.
 */
final class LandFundExpenseOnGoods
{
    public function __construct(
        private readonly FundDeal $fund,
        private readonly PurchaseOrderFundUnits $units,
        private readonly PostFundExpenseCharge $charges,
        private readonly ApplyStockChange $stock,
        private readonly PeriodForEntry $periodFor,
    ) {}

    /**
     * أأدخل الطلبُ للصندوق بضاعةً مستلمة؟ — قبل أن يُكتب شيء.
     *
     * @throws PurchaseOrderBroughtTheFundNothing
     */
    public function guard(int $purchaseOrderId): void
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null || $this->units->linesOf($purchaseOrderId, $fundId) === []) {
            throw PurchaseOrderBroughtTheFundNothing::make($purchaseOrderId);
        }
    }

    /** يقفل أرصدةَ كل مخزنٍ فيه شيءٌ من بضاعة الطلب — بترتيبٍ ثابت، قبل قفل الصندوق. */
    public function lockShelves(int $purchaseOrderId): void
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return;
        }

        $pairs = [];

        foreach ($this->units->batchesOf($purchaseOrderId, $fundId) as $batch) {
            $pairs[$batch['warehouse_id'].':'.$batch['stock_item_id']] = [$batch['warehouse_id'], $batch['stock_item_id']];
        }

        ksort($pairs);

        foreach ($pairs as [$warehouseId, $stockItemId]) {
            $this->stock->lockBalance($warehouseId, $stockItemId);
        }
    }

    /** يوزّع مصروفاً مربوطاً بطلب شراء. يُنادى والرفوفُ والصندوقُ مقفولة. */
    public function __invoke(InvestorDealExpense $expense, ?int $actorId): void
    {
        $fund = ($this->fund)();
        $lines = $this->units->linesOf((int) $expense->purchase_order_id, (int) $fund->getKey());

        $watermark = $this->units->watermark();
        $expense->landed_through_consumption_id = $watermark;
        $expense->save();

        $shares = LargestRemainder::split(
            LargestRemainder::toCents((string) $expense->amount),
            array_map(fn (array $line): string => $line['weight_cents'], $lines),
        );

        foreach ($lines as $itemId => $line) {
            $this->landLine($fund, $expense, $line, $shares[$itemId] ?? '0', $watermark, $actorId);
        }
    }

    /**
     * يُبطل مصروفاً مربوطاً بطلب شراء — بالمسار نفسه، بإشارةٍ معاكسة (§٤.٦).
     *
     * 1. حصصُ المستهلكين القائمة تُردّ.
     * 2. كلُّ طبقةٍ من البند تنقص Δ — ما على الرفّ اليوم يعود إلى تكلفته.
     * 3. وما بِيع **بعد** الهبوط حمل Δ في تكلفته فقلّ ربحُه: يُردّ إليه — ربحاً في فترة بيعه.
     */
    public function unland(InvestorDealExpense $original, string $reason, ?int $actorId): void
    {
        $fund = ($this->fund)();

        foreach ($this->liveCharges($original) as $charge) {
            $this->charges->reverse($fund, $charge, $reason, $actorId);
        }

        $deltas = $this->deltasOf($original);

        if ($deltas === []) {
            return;
        }

        $batches = $this->units->batchesOf((int) $original->purchase_order_id, (int) $fund->getKey());
        $locked = $this->lockBatches(array_keys($batches));

        foreach ($batches as $batchId => $batch) {
            $delta = $deltas[$batch['stock_movement_id']] ?? null;

            if ($delta === null) {
                continue;
            }

            $row = $locked[$batchId];
            $row->unit_cost = bcsub((string) $row->unit_cost, $delta, 3);
            $row->save();

            $this->write($original, FundExpenseChargeKind::Shelf, [
                'stock_batch_id' => $batchId,
                'quantity' => (string) $row->quantity_remaining,
                'unit_amount' => $delta,
                'amount' => bcmul(Money::round(bcmul((string) $row->quantity_remaining, $delta, 6)), '-1', 2),
                'charged_on' => now()->toDateString(),
            ]);
        }

        $since = $this->units->consumersOf(
            array_keys($batches),
            afterConsumptionId: (int) $original->landed_through_consumption_id,
        );

        foreach ($since as $consumer) {
            $delta = $deltas[$batches[$consumer['stock_batch_id']]['stock_movement_id']] ?? null;

            if ($delta === null) {
                continue;
            }

            $amount = Money::round(bcmul($consumer['quantity'], $delta, 6));

            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            $credit = $this->write($original, FundExpenseChargeKind::Consumer, [
                'stock_batch_id' => $consumer['stock_batch_id'],
                'stock_movement_id' => $consumer['stock_movement_id'],
                'order_id' => $consumer['order_id'],
                'quantity' => $consumer['quantity'],
                'unit_amount' => $delta,
                'amount' => bcmul($amount, '-1', 2),
                'charged_on' => $consumer['charged_on'],
            ]);

            $this->charges->post($fund, $credit, $actorId);
        }
    }

    /**
     * سحبٌ عُكس فرجعت وحداتُه إلى طبقاتها — تُردّ كلُّ حصةٍ قائمةٍ كُتبت عليه (§٤.٥).
     *
     * الطبقةُ تحمل Δ من الآن، فالحصةُ لو بقيت حُسب نصيبُ تلك الوحدات مرّتين. وما اشترته المطبعةُ
     * من رفٍّ مسعَّر لا يرجع إلى طبقته — ذهب للشركة — فحصتُه تبقى: البيعُ قائم.
     */
    public function returnChargesOf(int $movementId, bool $purchasedLayersToCompany): void
    {
        $charges = FundExpenseCharge::query()
            ->with('batch:id,printing_sale_price')
            ->where('stock_movement_id', $movementId)
            ->where('kind', FundExpenseChargeKind::Consumer->value)
            ->whereNull('reverses_charge_id')
            ->whereDoesntHave('reversedBy')
            ->orderBy('id')
            ->get()
            ->reject(fn (FundExpenseCharge $charge): bool => $purchasedLayersToCompany
                && $charge->batch?->printing_sale_price !== null);

        if ($charges->isEmpty()) {
            return;
        }

        $fund = InvestorDeal::query()->whereKey($this->fund->idOrNull())->lockForUpdate()->firstOrFail();

        foreach ($charges as $charge) {
            $this->charges->reverse($fund, $charge, 'رجعت البضاعة إلى الرفّ وهي تحمل حصتها', null);
        }
    }

    /**
     * أوّلُ فترةٍ مغلقة يمسّها عكسُ هذا المصروف — فيُرفض العكس (امتدادُ قرار 2026-10-05).
     *
     * حصةُ مستهلكٍ قائمة في فترةٍ أُقفلت، أو بيعٌ بعد الهبوط وقع في فترةٍ أُقفلت: أرقامُها أُعلنت.
     * وفرقُ التقريب لا يمنع — قروشٌ تُردّ على المفتوحة.
     */
    public function closedPeriodTouchedBy(InvestorDealExpense $expense): ?InvestmentPeriod
    {
        $periodIds = $this->liveCharges($expense)
            ->filter(fn (FundExpenseCharge $charge): bool => $charge->kind === FundExpenseChargeKind::Consumer)
            ->pluck('investment_period_id')
            ->filter()
            ->unique()
            ->all();

        $closed = InvestmentPeriod::query()
            ->whereIn('id', $periodIds)
            ->where('status', PeriodStatus::Closed->value)
            ->orderBy('starts_on')
            ->first();

        if ($closed !== null) {
            return $closed;
        }

        $fundId = $this->fund->idOrNull();

        if ($fundId === null || $expense->landed_through_consumption_id === null) {
            return null;
        }

        $batches = $this->units->batchesOf((int) $expense->purchase_order_id, $fundId);
        $since = $this->units->consumersOf(
            array_keys($batches),
            afterConsumptionId: (int) $expense->landed_through_consumption_id,
        );

        foreach ($since as $consumer) {
            $covering = InvestmentPeriod::covering(Carbon::parse($consumer['charged_on']));

            if ($covering?->status === PeriodStatus::Closed) {
                return $covering;
            }
        }

        return null;
    }

    /**
     * @param  array{item_id: int, stock_item_id: int, received: string, weight_cents: string, batches: array<int, array<string, mixed>>}  $line
     */
    private function landLine(
        InvestorDeal $fund,
        InvestorDealExpense $expense,
        array $line,
        string $shareCents,
        int $watermark,
        ?int $actorId,
    ): void {
        if (bccomp($shareCents, '0', 0) === 0) {
            return;
        }

        // bcdiv يقطع ولا يقرّب: Δ لا يزيد عن نصيب الوحدة أبداً.
        $delta = bcdiv(LargestRemainder::fromCents($shareCents), $line['received'], 3);
        $locked = $this->lockBatches(array_keys($line['batches']));
        $shelfCents = '0';

        foreach ($locked as $batchId => $row) {
            // «من كم لكم» — تكلفتُها قبل هذا المصروف، تُقرأ قبل أن تُرفع.
            $before = (string) $row->unit_cost;

            if (bccomp($delta, '0', 3) > 0) {
                $row->unit_cost = bcadd($before, $delta, 3);
                $row->save();
            }

            $amount = Money::round(bcmul((string) $row->quantity_remaining, $delta, 6));
            $shelfCents = bcadd($shelfCents, LargestRemainder::toCents($amount), 0);

            $this->write($expense, FundExpenseChargeKind::Shelf, [
                'stock_batch_id' => $batchId,
                'quantity' => (string) $row->quantity_remaining,
                'unit_amount' => $delta,
                'unit_cost_before' => $before,
                'amount' => $amount,
                'charged_on' => $expense->incurred_on->toDateString(),
            ]);
        }

        $restCents = bcsub($shareCents, $shelfCents, 0);

        if (bccomp($restCents, '0', 0) === 0) {
            return;
        }

        $consumers = $this->units->consumersOf(array_keys($line['batches']), throughConsumptionId: $watermark);

        if ($consumers === []) {
            $rounding = $this->write($expense, FundExpenseChargeKind::Rounding, [
                'amount' => LargestRemainder::fromCents($restCents),
                'charged_on' => $expense->incurred_on->toDateString(),
            ]);
            $this->charges->post($fund, $rounding, $actorId);

            return;
        }

        $split = LargestRemainder::split(
            $restCents,
            array_map(fn (array $consumer): string => bcmul($consumer['quantity'], '1000', 0), $consumers),
        );

        foreach ($consumers as $index => $consumer) {
            $charge = $this->write($expense, FundExpenseChargeKind::Consumer, [
                'stock_batch_id' => $consumer['stock_batch_id'],
                'stock_movement_id' => $consumer['stock_movement_id'],
                'order_id' => $consumer['order_id'],
                'quantity' => $consumer['quantity'],
                'unit_amount' => $delta,
                'amount' => LargestRemainder::fromCents($split[$index]),
                'charged_on' => $consumer['charged_on'],
            ]);

            $this->charges->post($fund, $charge, $actorId);
        }
    }

    /**
     * Δ لكل حركة وصول — من صفوف الرفّ الأصلية. نسخُ الطبقة تحمل حركتَها، فتأخذ Δ نفسَه.
     *
     * @return array<int, string>
     */
    private function deltasOf(InvestorDealExpense $expense): array
    {
        $rows = FundExpenseCharge::query()
            ->join('stock_batches as b', 'b.id', '=', 'fund_expense_charges.stock_batch_id')
            ->where('fund_expense_charges.investor_deal_expense_id', $expense->getKey())
            ->where('fund_expense_charges.kind', FundExpenseChargeKind::Shelf->value)
            ->where('fund_expense_charges.amount', '>=', 0)
            ->whereNull('fund_expense_charges.reverses_charge_id')
            ->where('fund_expense_charges.unit_amount', '>', 0)
            ->get(['b.stock_movement_id', 'fund_expense_charges.unit_amount']);

        $deltas = [];

        foreach ($rows as $row) {
            $deltas[(int) $row->stock_movement_id] = (string) $row->unit_amount;
        }

        return $deltas;
    }

    /** @return Collection<int, FundExpenseCharge> */
    private function liveCharges(InvestorDealExpense $expense): Collection
    {
        return FundExpenseCharge::query()
            ->where('investor_deal_expense_id', $expense->getKey())
            ->whereIn('kind', [FundExpenseChargeKind::Consumer->value, FundExpenseChargeKind::Rounding->value])
            ->whereNull('reverses_charge_id')
            ->whereDoesntHave('reversedBy')
            ->orderBy('id')
            ->get();
    }

    /**
     * @param  list<int>  $ids
     * @return array<int, StockBatch>
     */
    private function lockBatches(array $ids): array
    {
        if ($ids === []) {
            return [];
        }

        return StockBatch::query()
            ->whereIn('id', $ids)
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy('id')
            ->all();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function write(InvestorDealExpense $expense, FundExpenseChargeKind $kind, array $attributes): FundExpenseCharge
    {
        $charge = new FundExpenseCharge;
        $charge->investor_deal_expense_id = $expense->getKey();
        $charge->kind = $kind;
        $charge->stock_batch_id = $attributes['stock_batch_id'] ?? null;
        $charge->stock_movement_id = $attributes['stock_movement_id'] ?? null;
        $charge->order_id = $attributes['order_id'] ?? null;
        $charge->quantity = $attributes['quantity'] ?? '0';
        $charge->unit_amount = $attributes['unit_amount'] ?? null;
        $charge->unit_cost_before = $attributes['unit_cost_before'] ?? null;
        $charge->amount = $attributes['amount'];
        $charge->charged_on = $attributes['charged_on'];
        // مختومٌ قبل الكتابة: صفٌّ يُكتب ولا يُعدَّل، فسجلُّه حدثٌ واحد.
        $charge->investment_period_id = $kind->isCharged()
            ? $this->periodFor->forCharge($charge->order_id, $charge->charged_on->toDateString())
            : null;
        $charge->save();

        return $charge;
    }
}
