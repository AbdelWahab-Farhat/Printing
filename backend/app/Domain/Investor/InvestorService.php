<?php

declare(strict_types=1);

namespace App\Domain\Investor;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\BuyPurchaseOrderLinesFromPools;
use App\Domain\Investor\Actions\CancelCapitalRequest;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\CloseInvestorDeal;
use App\Domain\Investor\Actions\CreateInvestor;
use App\Domain\Investor\Actions\CreatePool;
use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\PostDealEarningsForOrder;
use App\Domain\Investor\Actions\PostDealStockPurchases;
use App\Domain\Investor\Actions\RaiseReturnedGoodsQuestions;
use App\Domain\Investor\Actions\RecordDealExpense;
use App\Domain\Investor\Actions\RecordReturnedGoodsVerdict;
use App\Domain\Investor\Actions\RecordSettlement;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\RequestPoolCapital;
use App\Domain\Investor\Actions\SetInvestorActivation;
use App\Domain\Investor\Actions\UnwindDealEarningsForOrder;
use App\Domain\Investor\Actions\UpdateInvestor;
use App\Domain\Investor\Actions\UpdatePool;
use App\Domain\Investor\DTOs\CapitalRequestData;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\FundPurchaseOrderData;
use App\Domain\Investor\DTOs\InvestorData;
use App\Domain\Investor\DTOs\PoolData;
use App\Domain\Investor\DTOs\PoolPurchaseData;
use App\Domain\Investor\DTOs\SupplyFunding;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\InvestmentSettlement;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\DealListQuery;
use App\Domain\Investor\Queries\DealOrdersQuery;
use App\Domain\Investor\Queries\DealStockPosition;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\InvestorListQuery;
use App\Domain\Investor\Queries\OrderInvestorSharesQuery;
use App\Domain\Investor\Queries\PeriodNetProfit;
use App\Domain\Investor\Queries\PoolDeployableCash;
use App\Domain\Investor\Queries\PoolListQuery;
use App\Domain\Investor\Queries\PurchaseOrderFundingQuery;
use App\Domain\Investor\Queries\SettlementSnapshot;
use App\Domain\Investor\Support\GraceWindow;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Events\OrderProfitUnwound;
use App\Domain\Order\Events\OrderStockDrawn;
use App\Domain\Settings\SettingsService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The door to everything about investors — and the only one other contexts knock on.
 *
 * **The dependency runs one way.** Investment reads Orders, Inventory and Catalog through their
 * services; none of them imports anything from here. The two places the rest of the system calls
 * in are both a single line: `ReceivePurchaseOrder` asks which deal financed a line, and
 * `ChangeOrderStatus` says that an order has been delivered. Neither knows what happens next.
 */
final class InvestorService
{
    public function __construct(
        private readonly CreateInvestor $createInvestor,
        private readonly UpdateInvestor $updateInvestor,
        private readonly SetInvestorActivation $setActivation,
        private readonly FundPurchaseOrder $fundPurchaseOrder,
        private readonly CloseInvestorDeal $closeDeal,
        private readonly CreatePool $createPool,
        private readonly UpdatePool $updatePool,
        private readonly OpenInvestmentPeriod $openPeriod,
        private readonly BuyPurchaseOrderLinesFromPools $buyFromPools,
        private readonly CloseInvestmentPeriod $closePeriod,
        private readonly RaiseReturnedGoodsQuestions $raiseReturnedGoods,
        private readonly RecordReturnedGoodsVerdict $recordVerdict,
        private readonly PeriodNetProfit $periodNetProfit,
        private readonly PoolDeployableCash $deployableCash,
        private readonly SettlementSnapshot $settlementSnapshot,
        private readonly RecordSettlement $recordSettlement,
        private readonly RequestPoolCapital $requestCapital,
        private readonly CancelCapitalRequest $cancelCapitalRequest,
        private readonly RecordWalletEntry $recordEntry,
        private readonly RecordDealExpense $recordExpense,
        private readonly PostDealEarningsForOrder $postEarnings,
        private readonly PostDealStockPurchases $postStockPurchases,
        private readonly UnwindDealEarningsForOrder $unwindEarnings,
        private readonly InvestorBalances $balances,
        private readonly InvestorListQuery $investorList,
        private readonly DealListQuery $dealList,
        private readonly PoolListQuery $poolList,
        private readonly DealStockPosition $stockPosition,
        private readonly DealOrdersQuery $dealOrderList,
        private readonly OrderInvestorSharesQuery $orderShares,
        private readonly PurchaseOrderFundingQuery $purchaseOrderFunding,
        private readonly SettingsService $settings,
    ) {}

    // ── people ───────────────────────────────────────────────────────────────

    public function createInvestor(InvestorData $data, ?int $actorId): Investor
    {
        return ($this->createInvestor)($data, $actorId);
    }

    public function updateInvestor(Investor $investor, InvestorData $data): Investor
    {
        return ($this->updateInvestor)($investor, $data);
    }

    public function setInvestorActivation(Investor $investor, bool $isActive): Investor
    {
        return ($this->setActivation)($investor, $isActive);
    }

    /** The investor behind a signed-in user, or null — the whole of the portal's scoping. */
    public function investorFor(?User $user): ?Investor
    {
        if ($user === null) {
            return null;
        }

        return Investor::query()
            ->where('user_id', $user->getKey())
            ->where('is_active', true)
            ->first();
    }

    /**
     * Every account that belongs to an investor rather than to an employee.
     *
     * The set complement of {@see investorFor}, and it exists for one caller: a staff-wide
     * announcement has to reach employees and **not** the people whose money is in the stock.
     * Asked here rather than by querying `investors` from another context, because this Service
     * is the door — and because «is this account an investor?» has exactly one correct answer
     * and should have exactly one implementation of it.
     *
     * Active investors only, matching `investorFor` and `UserResource.is_investor`: a retired
     * investor whose login was never removed is an ordinary account again.
     *
     * @return list<int>
     */
    public function linkedUserIds(): array
    {
        return Investor::query()
            ->whereNotNull('user_id')
            ->where('is_active', true)
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    // ── deals ────────────────────────────────────────────────────────────────

    /**
     * A purchase order becomes a funded, open deal — its lines, its claim and its money at once.
     *
     * The only way a deal is born. There is no deal assembled by hand: the fraction of the goods
     * its partners own is derived from the order's cost, and a deal without an order had nothing
     * to derive it from — the owner's word, 2026-09-05: «صفقة يدوية يجب أن لا توجد».
     */
    public function fundPurchaseOrder(int $purchaseOrderId, FundPurchaseOrderData $data, ?int $actorId): InvestorDeal
    {
        return ($this->fundPurchaseOrder)($purchaseOrderId, $data, $actorId);
    }

    public function closeDeal(InvestorDeal $deal): InvestorDeal
    {
        return ($this->closeDeal)($deal);
    }

    // ── pools ────────────────────────────────────────────────────────────────

    /**
     * Opens a صندوق — a continuous pool for one material.
     *
     * It is born open and empty: money arrives later through its own act, and ownership is
     * recomputed from that money at every period close. Unlike a deal, it is never «struck».
     */
    public function createPool(PoolData $data, ?int $actorId): InvestorDeal
    {
        return ($this->createPool)($data, $actorId);
    }

    /** Renames a pool and changes which shelves it owns — never its profit share. */
    public function updatePool(InvestorDeal $pool, PoolData $data, ?int $actorId): InvestorDeal
    {
        return ($this->updatePool)($pool, $data, $actorId);
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, InvestorDeal>
     */
    public function paginatePools(array $filters, int $perPage = 15)
    {
        return ($this->poolList)($filters, $perPage);
    }

    // ── periods and queued capital ───────────────────────────────────────────

    /**
     * Starts a pool's next accounting period, and lets in the capital that was waiting for it.
     *
     * The dates come from the company calendar, not from the caller: the day after the last period
     * ended, for `profit_period_months`. Read once, here, and never again for this period.
     *
     * @return array{period: InvestmentPeriod, applied: list<InvestmentCapitalRequest>, short: array<int, array{investor_id: int, wanted: string, available: string}>}
     */
    public function openPeriod(InvestorDeal $pool): array
    {
        return ($this->openPeriod)($pool);
    }

    /** The pool's current period, or null between a close and the next open. */
    public function currentPeriodFor(int $poolId): ?InvestmentPeriod
    {
        return InvestmentPeriod::query()
            ->where('investor_deal_id', $poolId)
            ->where('status', 'open')
            ->first();
    }

    /**
     * Capital offered to a pool, or asked back from it.
     *
     * Taken now when it is capital coming in and today is still inside the grace window; queued for
     * the next boundary otherwise. An exit is always queued — see {@see RequestPoolCapital}.
     */
    public function requestPoolCapital(InvestorDeal $pool, CapitalRequestData $data, ?int $actorId): InvestmentCapitalRequest
    {
        return ($this->requestCapital)($pool, $data, $actorId);
    }

    public function cancelCapitalRequest(InvestmentCapitalRequest $request): InvestmentCapitalRequest
    {
        return ($this->cancelCapitalRequest)($request);
    }

    /**
     * What a pool's screen must say **before** somebody commits money: when the window shuts, and
     * what would happen if he pressed the button now.
     *
     * Computed through {@see GraceWindow}, the same function {@see RequestPoolCapital} then acts on,
     * so the promise and the behaviour cannot disagree.
     *
     * @return array{period: ?InvestmentPeriod, grace_window_ends_on: ?string, capital_takes_effect_on: ?string, is_inside_grace_window: bool}
     */
    public function capitalTimingFor(int $poolId): array
    {
        $period = $this->currentPeriodFor($poolId);

        if ($period === null) {
            return [
                'period' => null,
                'grace_window_ends_on' => null,
                'capital_takes_effect_on' => null,
                'is_inside_grace_window' => false,
            ];
        }

        $graceDays = $this->settings->entryGraceDays();
        $now = now();

        return [
            'period' => $period,
            'grace_window_ends_on' => GraceWindow::closesOn($period, $graceDays)->toDateString(),
            'capital_takes_effect_on' => GraceWindow::takesEffectOn($period, $graceDays, $now)->toDateString(),
            'is_inside_grace_window' => GraceWindow::admits($period, $graceDays, $now),
        ];
    }

    /**
     * Closes a period: divides what it made, pays it into wallets, lets out whoever asked to leave,
     * and opens the next one.
     *
     * The only door profit walks through to become withdrawable. Refused while any returned-goods
     * question is unanswered.
     */
    public function closePeriod(InvestmentPeriod $period, ?int $actorId): InvestmentPeriod
    {
        return ($this->closePeriod)($period, $actorId);
    }

    /**
     * What a period made, and whether anything is holding its close up — the same arithmetic the
     * close itself performs, so a screen can print its working before the button is pressed.
     *
     * @return array<string, mixed>
     */
    public function periodFigures(InvestmentPeriod $period): array
    {
        return ($this->periodNetProfit)($period) + [
            'has_unanswered_returns' => $this->periodNetProfit->hasUnansweredReturns($period),
        ];
    }

    /**
     * A cancelled order gave its material back — ask whether it is still usable.
     *
     * Called from the `OrderStockReturned` listener. Does nothing for the ordinary cancellation,
     * which is most of them.
     *
     * @return list<InvestmentReturnedGoodsQuestion>
     */
    public function askAboutReturnedGoods(int $orderId): array
    {
        return ($this->raiseReturnedGoods)($orderId);
    }

    /** «صالحة» writes nothing; «تالفة» takes the goods off the shelf as damage. */
    public function answerReturnedGoods(
        InvestmentReturnedGoodsQuestion $question,
        ReturnedGoodsVerdict $verdict,
        int $warehouseId,
        int $actorId,
        ?string $notes = null,
    ): InvestmentReturnedGoodsQuestion {
        return ($this->recordVerdict)($question, $verdict, $warehouseId, $actorId, $notes);
    }

    // ── buying with pool money ───────────────────────────────────────────────

    /**
     * Marks lines of a purchase order as bought with pool money.
     *
     * The pool follows from the material; the only decision carried in is the yes/no. Refused if a
     * line is already claimed, if a material belongs to no pool, or if a pool cannot cover its
     * share of the lorry.
     *
     * @return list<InvestorDealSupply>
     */
    public function buyPurchaseOrderLinesFromPools(int $purchaseOrderId, PoolPurchaseData $data, ?int $actorId): array
    {
        return ($this->buyFromPools)($purchaseOrderId, $data, $actorId);
    }

    /**
     * What a pool can actually spend — book value less the goods it is already holding.
     *
     * Derived on every read. Undrawn profit is excluded by construction: it left `profit_deal` for
     * the investor's wallet when the period closed.
     *
     * @return array{book_value: string, stock_at_cost: string, deployable_cash: string, capital: string, unsettled_profit: string}
     */
    public function deployableCashFor(int $poolId): array
    {
        return ($this->deployableCash)($poolId);
    }

    /**
     * How many months capital must stay in a pool before its owner may ask for it back.
     *
     * Exposed through this door rather than by handing screens the settings service, so «متى يحق
     * له السحب؟» is answered in the same place the refusal is written.
     */
    public function minimumTermMonths(): int
    {
        return $this->settings->minimumTermMonths();
    }

    // ── settlement ───────────────────────────────────────────────────────────

    /**
     * Where a pool's money is — **worked out twice**, from the wallet ledger and from the
     * movements, so the two can be compared rather than assumed equal.
     *
     * Derived on demand, and the same figures {@see RecordSettlement()} then freezes. A screen that
     * asks somebody to sign a position must print the position that gets signed.
     *
     * @return array<string, mixed>
     */
    public function settlementSnapshotFor(int $poolId): array
    {
        return ($this->settlementSnapshot)($poolId);
    }

    /**
     * Freeze and sign that position.
     *
     * **Moves nothing.** No wallet row, no stock movement, no period touched — and a non-zero drift
     * is written down and left standing rather than adjusted away.
     */
    public function recordSettlement(
        InvestorDeal $pool,
        ?string $settledOn,
        ?int $approvedBy,
        ?string $notes,
        ?int $actorId,
    ): InvestmentSettlement {
        return ($this->recordSettlement)($pool, $settledOn, $approvedBy, $notes, $actorId);
    }

    // ── money ────────────────────────────────────────────────────────────────

    public function recordWalletEntry(WalletEntryData $data, ?int $actorId): InvestorWalletEntry
    {
        return ($this->recordEntry)($data, $actorId);
    }

    public function recordDealExpense(InvestorDeal $deal, DealExpenseData $data, ?int $actorId): InvestorDealExpense
    {
        return ($this->recordExpense)($deal, $data, $actorId);
    }

    /**
     * @return array{wallet: array{capital: string, profit: string}, deals: array<int, array{capital: string, profit: string}>}
     */
    public function balancesFor(int $investorId): array
    {
        return $this->balances->forInvestor($investorId);
    }

    /**
     * The totals of a page of investors, in one query — what the register screen draws.
     *
     * @param  list<int>  $investorIds
     * @return array<int, array{capital: string, profit: string, wallet_capital: string, wallet_profit: string}>
     */
    public function balancesForMany(array $investorIds): array
    {
        return $this->balances->forInvestors($investorIds);
    }

    /**
     * @return array{capital: string, profit: string, per_investor: array<int, array{capital: string, profit: string}>}
     */
    public function dealBalances(int $dealId): array
    {
        return $this->balances->forDeal($dealId);
    }

    // ── the two lines the rest of the system calls ───────────────────────────

    /**
     * A set of deals as a screen holding their ids needs them: the code, and who is in each.
     *
     * For the screens that hold a deal id and cannot name it — a cost layer, a movement. They
     * live in Inventory, which must not import anything from here, so the Application layer asks
     * and hands the answer down.
     *
     * **One query for the page, two with the partners.** A layer list showing fifty batches must
     * not become fifty lookups.
     *
     * @param  list<int>  $dealIds
     * @return array<int, array{code: string, investors: list<array{investor_id: int, name: string, committed_amount: string, share_percent: string}>}>
     */
    public function dealSummaries(array $dealIds): array
    {
        if ($dealIds === []) {
            return [];
        }

        $deals = InvestorDeal::query()
            ->whereIn('id', $dealIds)
            ->with('shares.investor')
            ->get();

        $out = [];

        foreach ($deals as $deal) {
            $out[(int) $deal->getKey()] = [
                'code' => (string) $deal->code,
                'investors' => $deal->shares->map(fn ($share): array => [
                    'investor_id' => (int) $share->investor_id,
                    'name' => (string) ($share->investor?->name ?? ''),
                    'committed_amount' => (string) $share->committed_amount,
                    'share_percent' => (string) $share->share_percent,
                ])->values()->all(),
            ];
        }

        return $out;
    }

    /**
     * The investors' share of profit a new deal is born with — the company default.
     *
     * Read by the funding screen so the number is **shown** rather than left to be discovered
     * after the deal is struck. Copied onto each deal at birth and never read again for that
     * deal, so editing it tomorrow moves nothing already agreed.
     */
    public function defaultProfitSharePercent(): string
    {
        return (string) $this->settings->investorProfitSharePercent();
    }

    /**
     * The deals financing one purchase order, with their partners and percentages.
     *
     * Read by the purchase-order screen. Empty for the ordinary order the company paid for
     * itself, which is most of them.
     *
     * @return list<array<string, mixed>>
     */
    public function fundingForPurchaseOrder(int $purchaseOrderId): array
    {
        return ($this->purchaseOrderFunding)($purchaseOrderId);
    }

    /**
     * Which deal financed a line of an arriving document, and at what price it sells its plain
     * stock to the press — asked once per line at receipt.
     *
     * Null is the ordinary answer and means the company paid for it. The receiving clerk never
     * sees this question: it is answered from a claim somebody made before the goods left the
     * supplier.
     */
    public function dealForSupply(int $purchaseOrderId, int $stockItemId): ?SupplyFunding
    {
        $supply = InvestorDealSupply::query()
            ->with('deal')
            ->where('source_type', AuditSubject::PurchaseOrder->value)
            ->where('source_id', $purchaseOrderId)
            ->where('stock_item_id', $stockItemId)
            ->first();

        if ($supply === null) {
            return null;
        }

        return new SupplyFunding(
            dealId: (int) $supply->investor_deal_id,
            // Carried out with the id because the layer this answer opens must freeze both, and
            // asking twice would be two reads of one row for one decision.
            //
            // **The supply's own price wins, and the container's is the fallback.** سعر السادة is
            // agreed per lorry now, because a صندوق outlives every lorry it buys; a legacy صفقة
            // agreed it once for its whole life and still answers from its own column. Reading the
            // supply first is what lets both roads coexist without a `kind` check here.
            printingSalePrice: match (true) {
                $supply->printing_sale_price !== null => (string) $supply->printing_sale_price,
                $supply->deal?->printing_sale_price !== null => (string) $supply->deal->printing_sale_price,
                default => null,
            },
        );
    }

    /**
     * An order has become final — split what it earned among whoever financed its stock.
     *
     * Called from `ChangeOrderStatus` on the way into «تم الاستلام». Does nothing at all when the
     * order drew from no funded layer, which is the normal case.
     *
     * @return list<InvestorWalletEntry>
     */
    public function postEarningsForOrder(int $orderId): array
    {
        return ($this->postEarnings)($orderId);
    }

    /**
     * An order has been archived — take what it paid back out again.
     *
     * Called from `DeleteOrder` through {@see OrderProfitUnwound}, and not by re-running
     * {@see postEarningsForOrder()}: that road reads the order through a soft-delete-scoped
     * query and returns early on an archived one, having reversed nothing. See §٢٫١ of
     * Docs/orders/ORDER-DELETE-AND-ARCHIVE.md.
     *
     * @return list<InvestorWalletEntry> always empty; what this writes is reversals
     */
    public function unwindEarningsForOrder(int $orderId): array
    {
        return ($this->unwindEarnings)($orderId);
    }

    /**
     * The press has taken its plain material off the shelf — pay whoever sold it.
     *
     * Called from `ChangeOrderStatus` on the way into «جاهزة للطباعة» and «جاهزة», through
     * {@see OrderStockDrawn}. Does nothing at all unless a printed
     * line drew on a deal that sells to the press at سعر السادة, which is the normal case.
     *
     * @return list<InvestorWalletEntry>
     */
    public function postStockPurchasesForOrder(int $orderId): array
    {
        return ($this->postStockPurchases)($orderId);
    }

    /**
     * One further draw off the shelf — bags spoiled at the press — paid for on its own row.
     *
     * @return list<InvestorWalletEntry>
     */
    public function postStockPurchaseForMovement(int $stockMovementId): array
    {
        return $this->postStockPurchases->forMovement($stockMovementId);
    }

    /**
     * «هذه الطلبية — من أخذ منها، وكم، وهل أخذه فعلاً» — see {@see OrderInvestorSharesQuery}.
     *
     * Empty for every order that drew on nothing but the company's own stock.
     *
     * @return list<array<string, mixed>>
     */
    public function investorSharesOfOrder(int $orderId): array
    {
        return ($this->orderShares)($orderId);
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, Investor>
     */
    public function paginateInvestors(array $filters, int $perPage = 15)
    {
        return ($this->investorList)($filters, $perPage);
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, InvestorDeal>
     */
    public function paginateDeals(array $filters, int $perPage = 15)
    {
        return ($this->dealList)($filters, $perPage);
    }

    /**
     * What a deal's goods are doing — arrived, left, sold, damaged, short.
     *
     * @return array<string, mixed>
     */
    public function dealStock(int $dealId): array
    {
        return ($this->stockPosition)($dealId);
    }

    /**
     * The orders that sold a deal's goods, and what each one earned it.
     *
     * @return LengthAwarePaginator<int, array<string, mixed>>
     */
    public function dealOrders(int $dealId, int $perPage = 15)
    {
        return ($this->dealOrderList)($dealId, $perPage);
    }

    /**
     * What this deal has made and what it stands to make — its orders' profit, in two buckets.
     *
     * `delivered` is final money; `in_flight` is a forecast over goods that are off the shelf but
     * not yet in anybody's hands. See {@see DealOrdersQuery::totals()} for why the two are never
     * one figure.
     *
     * @return array{
     *     in_flight: array{orders: int, profit: string},
     *     delivered: array{orders: int, profit: string},
     *     total: array{orders: int, profit: string}
     * }
     */
    public function dealOrdersProfit(int $dealId): array
    {
        return $this->dealOrderList->totals($dealId);
    }

    /** Rounding, exposed so a controller never reimplements it. */
    public function round(string $amount): string
    {
        return Money::round($amount);
    }
}
