<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\Actions\ApplyStockChange;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\UnitEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\DealCannotFoldIntoFund;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\DealOrdersInFlightQuery;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * صفقةٌ قديمة تدخل الصندوق — «نخلي اول فترة صاحبها عبدالرحمن مباشرة وهكذا مع بضاعته هذي».
 *
 * المواصفة: §٠.٩ و§س١٣ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}، والتوصياتُ
 * الخمس كلُّها. بأرقام الصفقة يومَ التحويل، لا برقمٍ مكتوبٍ قبله.
 *
 * ```
 * يبقى في الصفقة   F  = نصيبُه × نسبةُ الشركاء × تكلفةُ ما في الطريق      (§١٣د)
 * يدخل الصندوق     E  = رأسُ ماله فيها − F
 * بضاعةٌ           G  = نصيبُه × تكلفةُ الرفّ كلِّه — وحصّةُ الشركة منه يشتريها (§١٣أ)
 * نقدٌ             X  = E − G — من صندوق الشركة إلى خزينة الصندوق باسمه          (§١٣ب)
 * وحداتُه          E ÷ سعرِ الوحدة قبل التحويل، محبوسةً من يومه                    (§١٣هـ)
 * ربحُه فيها       يُفرَج عنه في محفظته، ونقدُه يدخل الخزينة معه                  (§١٣ج)
 * ```
 *
 * ## ولماذا يدخل ربحُه الخزينةَ وهو في محفظته
 *
 * **كلُّ سحبِ أرباحٍ يخرج من خزينة الصندوق** ({@see RecordWalletEntry}). وربحُ الصفقة القديمة
 * نقدُه في صندوق الشركة — فلو أُفرِج عنه بلا نقده لسحبه صاحبُه من مال الصندوق. والقيمةُ لا تتغيّر
 * بذلك: نقدٌ يدخل بقدر ربحٍ يُطرح.
 *
 * ## والبضاعةُ تنتقل في طبقاتٍ جديدة لا بإعادة وسم
 *
 * {@see ApplyStockChange::handOverBatches()}: طبقةُ الصفقة تُسحب إلى الصفر، وطبقةٌ مثلُها
 * للصندوق بتكلفتها وتاريخها وسعر سادتها. إعادةُ وسم الطبقة كانت ستنسب ماضيها كلَّه إلى الصندوق.
 *
 * ## وما يبقى بعده
 *
 * الصفقةُ مفتوحةٌ ومعلَّمةٌ `folded_into_fund_at` ما دامت لها طلبياتٌ في الطريق؛ تُتمّها الجدولةُ
 * ({@see RollInvestmentPeriods}) حين تصل. **ولا تسوّيها فترة**: صفُّ الإفراج هنا لا يعني «ربحُ
 * الفترة دُفع»، فالفترةُ تتخطّى الصفقةَ المعلَّمة كلَّها. والتحويلُ يُعاد بلا ضرر: بضاعةٌ عادت إلى
 * رفّها بعده تنتقل بنداءٍ ثانٍ بالقاعدة نفسها.
 */
final class FoldDealIntoFund
{
    public function __construct(
        private readonly FundDeal $fund,
        private readonly UnitPrice $price,
        private readonly InvestorBalances $balances,
        private readonly DealOrdersInFlightQuery $inFlight,
        private readonly ApplyStockChange $stock,
        private readonly RecordCashEntry $cash,
        private readonly PeriodForEntry $periodFor,
    ) {}

    /**
     * @return array{
     *     deal: string,
     *     unit_price: string,
     *     shelf_quantity: string,
     *     shelf_cost: string,
     *     company_share_of_shelf: string,
     *     in_flight_cost: string,
     *     investors: list<array{investor_id: int, name: string, capital: string, stays: string,
     *         enters: string, goods: string, cash: string, units: string, profit: string}>
     * }
     */
    public function __invoke(InvestorDeal $deal, int $actorId): array
    {
        $this->guardTheDeal($deal);

        return DB::transaction(function () use ($deal, $actorId): array {
            $locked = InvestorDeal::query()->whereKey($deal->getKey())->lockForUpdate()->firstOrFail();
            $this->guardTheDeal($locked);

            $period = InvestmentPeriod::query()
                ->where('status', PeriodStatus::Open)
                ->lockForUpdate()
                ->first();

            $this->guardThePeriod($period);

            // **قبل كل كتابة**، كما في {@see DepositToFund}: البضاعةُ والنقدُ يرفعان القيمةَ لحظةَ
            // دخولهما، والوحداتُ تُشترى بسعر ما قبلهما.
            $plan = $this->plan($locked);

            $locked->folded_into_fund_at ??= now();
            $locked->save();

            $fund = ($this->fund)();

            $this->handOverTheShelf($locked, (int) $fund->getKey(), $actorId);

            foreach ($plan['investors'] as $line) {
                $this->enter($locked, $fund, $period, $line, $plan['unit_price'], $actorId);
            }

            return $plan;
        });
    }

    /**
     * ما كان التحويلُ سيفعله الآن — بالحراس نفسها والأرقام نفسها، ولا يكتب شيئاً.
     *
     * @return array<string, mixed>
     */
    public function preview(InvestorDeal $deal): array
    {
        $this->guardTheDeal($deal);
        $this->guardThePeriod(InvestmentPeriod::open());

        return $this->plan($deal);
    }

    private function guardTheDeal(InvestorDeal $deal): void
    {
        if ($this->fund->is($deal)) {
            throw DealCannotFoldIntoFund::isTheFund();
        }

        if ($deal->status !== DealStatus::Open) {
            throw DealCannotFoldIntoFund::notOpen((string) $deal->code, $deal->status->label());
        }
    }

    /** وحداتٌ تُصدَر في فترةٍ تقبل رأسَ مالٍ اليوم — ونافذةُ الأولى كلُّ أيامها. */
    private function guardThePeriod(?InvestmentPeriod $period): void
    {
        if ($period === null || ! $period->acceptsCapitalOn(now())) {
            throw DealCannotFoldIntoFund::noPeriodTakesCapital();
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function plan(InvestorDeal $deal): array
    {
        $dealId = (int) $deal->getKey();
        $funded = bcdiv((string) $deal->investor_funded_percent, '100', 8);

        $shelf = DB::table('stock_batches')
            ->where('investor_deal_id', $dealId)
            ->whereNull('deleted_at')
            ->where('quantity_remaining', '>', 0)
            ->selectRaw('COALESCE(SUM(quantity_remaining), 0) as qty, COALESCE(SUM(quantity_remaining * unit_cost), 0) as cost')
            ->first();

        $shelfCost = Money::round((string) $shelf->cost);
        $inFlightCost = Money::round($this->inFlight->costOf($dealId));

        $shares = $deal->shares()->with('investor')->orderBy('investor_id')->get();
        $pots = $this->balances->forDeal($dealId)['per_investor'];

        $weights = $shares->map(fn ($share): string => (string) $share->share_percent)->all();

        if ($shares->isEmpty()) {
            throw DealCannotFoldIntoFund::nobodyToFold((string) $deal->code);
        }

        // الباقي الأكبر لا التقريبُ لكلّ واحد: مجموعُ الحصص يساوي الكلَّ بلا قرشٍ ضائع.
        $goods = Money::allocate($shelfCost, $weights);
        $staying = Money::allocate(Money::round(bcmul($funded, $inFlightCost, 8)), $weights);

        $price = ($this->price)();
        $lines = [];

        foreach ($shares->values() as $index => $share) {
            $investorId = (int) $share->investor_id;
            $capital = $pots[$investorId]['capital'] ?? '0.00';
            $profit = $pots[$investorId]['profit'] ?? '0.00';

            $enters = Money::round(bcsub($capital, $staying[$index], 8));
            $cash = Money::round(bcsub($enters, $goods[$index], 8));

            if (bccomp($cash, '0', 2) < 0) {
                throw DealCannotFoldIntoFund::cashCannotBuyTheCompanyShare(
                    (string) $deal->code,
                    (string) $share->investor?->name,
                    substr($cash, 1),
                );
            }

            $lines[] = [
                'investor_id' => $investorId,
                'name' => (string) $share->investor?->name,
                'capital' => $capital,
                'stays' => $staying[$index],
                'enters' => $enters,
                'goods' => $goods[$index],
                'cash' => $cash,
                'units' => bccomp($enters, '0', 2) > 0 ? bcdiv($enters, $price, 6) : '0.000000',
                'profit' => $profit,
            ];
        }

        return [
            'deal' => (string) $deal->code,
            'unit_price' => $price,
            'shelf_quantity' => number_format((float) $shelf->qty, 3, '.', ''),
            'shelf_cost' => $shelfCost,
            'company_share_of_shelf' => Money::round(bcmul(bcsub('1', $funded, 8), $shelfCost, 8)),
            'in_flight_cost' => $inFlightCost,
            'investors' => $lines,
        ];
    }

    /**
     * الرفُّ كلُّه إلى الصندوق — حركتان لكلّ صنفٍ في كلّ مخزن: خروجٌ من الصفقة ودخولٌ للصندوق.
     */
    private function handOverTheShelf(InvestorDeal $deal, int $fundId, int $actorId): void
    {
        $groups = StockBatch::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('quantity_remaining', '>', 0)
            ->orderBy('warehouse_id')
            ->orderBy('stock_item_id')
            ->get()
            ->groupBy(fn (StockBatch $batch): string => $batch->warehouse_id.':'.$batch->stock_item_id);

        foreach ($groups as $batches) {
            $first = $batches->first();
            $quantity = number_format((float) $batches->sum(fn ($b) => (float) $b->quantity_remaining), 3, '.', '');
            $note = "نقل ملكية: بضاعة الصفقة {$deal->code} إلى الصندوق";

            $out = $this->movement((int) $first->stock_item_id, (int) $first->warehouse_id, null, $quantity, $note, $actorId);

            $this->stock->handOverBatches(
                (int) $first->warehouse_id,
                (int) $first->stock_item_id,
                $batches->pluck('id')->map(fn ($id): int => (int) $id)->all(),
                $fundId,
                (int) $out->getKey(),
            );

            $this->movement((int) $first->stock_item_id, null, (int) $first->warehouse_id, $quantity, $note, $actorId);
        }
    }

    private function movement(int $stockItemId, ?int $from, ?int $to, string $quantity, string $note, int $actorId): StockMovement
    {
        $movement = new StockMovement([
            'quantity' => $quantity,
            'notes' => $note,
        ]);

        $movement->stock_item_id = $stockItemId;
        $movement->movement_type = MovementType::OwnershipTransfer;
        $movement->from_warehouse_id = $from;
        $movement->to_warehouse_id = $to;
        $movement->employee_id = $actorId;
        $movement->save();

        return $movement;
    }

    /**
     * شريكٌ واحد: رأسُ ماله من الصفقة إلى الصندوق، ووحداتُه، ونقدُه، وربحُه.
     *
     * @param  array<string, mixed>  $line
     */
    private function enter(
        InvestorDeal $deal,
        InvestorDeal $fund,
        InvestmentPeriod $period,
        array $line,
        string $unitPrice,
        int $actorId,
    ): void {
        $investorId = (int) $line['investor_id'];
        $note = "تحويل الصفقة {$deal->code} إلى الصندوق";

        if (bccomp($line['enters'], '0', 2) > 0) {
            // خروجٌ من الصفقة إلى المحفظة ثم دخولٌ منها إلى الصندوق — زوجٌ يتقابل في المحفظة، فيبقى
            // كشفُه يقول من أين جاء المالُ وإلى أين ذهب.
            $this->write($investorId, $deal, WalletEntryType::Release, $line['enters'], null, $note);

            $allocation = $this->write(
                $investorId,
                $fund,
                WalletEntryType::Allocation,
                $line['enters'],
                $this->periodFor->byDate(now()),
                $note,
            );

            $units = new InvestmentUnit;
            $units->investor_id = $investorId;
            $units->investment_period_id = $period->getKey();
            $units->type = UnitEntryType::Issue;
            $units->units = $line['units'];
            $units->unit_price = $unitPrice;
            $units->amount = $line['enters'];
            // §١٣هـ: من يوم التحويل، بمدّة الفترة المجمَّدة — كأيّ دفعةٍ تدخل الصندوق.
            $units->locked_until = now()->addMonths((int) $period->capital_lock_months)->toDateString();
            $units->source_type = AuditSubject::InvestorWalletEntry->value;
            $units->source_id = $allocation->getKey();
            $units->occurred_at = now();
            $units->recorded_by = $actorId;
            $units->save();

            if (bccomp($line['cash'], '0', 2) > 0) {
                ($this->cash)(
                    type: CashEntryType::LegacyTransfer,
                    amount: $line['cash'],
                    sourceType: AuditSubject::InvestorWalletEntry->value,
                    sourceId: (int) $allocation->getKey(),
                    actorId: $actorId,
                    notes: "نقد {$line['name']} المحقَّق من الصفقة {$deal->code} بعد حصة الشركة من البضاعة",
                );
            }
        }

        if (bccomp($line['profit'], '0', 2) > 0) {
            $release = $this->write($investorId, $deal, WalletEntryType::ProfitRelease, $line['profit'], null, $note);

            ($this->cash)(
                type: CashEntryType::LegacyTransfer,
                amount: $line['profit'],
                sourceType: AuditSubject::InvestorWalletEntry->value,
                sourceId: (int) $release->getKey(),
                actorId: $actorId,
                notes: "ربح {$line['name']} من الصفقة {$deal->code}",
            );
        }
    }

    /**
     * صفٌّ في المحفظة. **وصفُّ الصفقة المعلَّمة بلا ختم فترة**: لا فترةَ تسوّيها.
     */
    private function write(
        int $investorId,
        InvestorDeal $deal,
        WalletEntryType $type,
        string $amount,
        ?int $periodId,
        string $note,
    ): InvestorWalletEntry {
        $entry = new InvestorWalletEntry([
            'amount' => Money::round($amount),
            'occurred_at' => now(),
            'notes' => $note,
        ]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $deal->getKey();
        $entry->investment_period_id = $periodId;
        $entry->type = $type;
        $entry->save();

        return $entry;
    }
}
