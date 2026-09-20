<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Investor\AnswerReturnedGoodsRequest;
use App\Application\Api\V1\Requests\Investor\BuyWithPoolMoneyRequest;
use App\Application\Api\V1\Requests\Investor\StoreCapitalRequestRequest;
use App\Application\Api\V1\Requests\Investor\StorePoolRequest;
use App\Application\Api\V1\Requests\Investor\StoreSettlementRequest;
use App\Application\Api\V1\Resources\InvestmentCapitalRequestResource;
use App\Application\Api\V1\Resources\InvestmentPeriodResource;
use App\Application\Api\V1\Resources\InvestmentPeriodShareResource;
use App\Application\Api\V1\Resources\InvestmentPoolResource;
use App\Application\Api\V1\Resources\InvestmentReturnedGoodsQuestionResource;
use App\Application\Api\V1\Resources\InvestmentSettlementResource;
use App\Application\Api\V1\Resources\InvestorDealExpenseResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Investor\DTOs\CapitalRequestData;
use App\Domain\Investor\DTOs\PoolData;
use App\Domain\Investor\DTOs\PoolPurchaseData;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Investment pools
 *
 * صناديق الاستثمار — one continuous pool per material. A pool never closes; its **periods** do.
 *
 * **A pool is opened empty.** It names the shelves it buys and nothing else: no partners, no
 * amounts, no purchase order. Capital arrives afterwards through its own endpoint, gated by the
 * grace window, and ownership is recomputed from that capital at every period close — which is
 * the whole difference from the صفقة that came before, where the partners and their percentages
 * were frozen at the moment the lorry was funded.
 *
 * **Each shelf belongs to exactly one pool**, guaranteed by a unique index rather than by a rule
 * anybody has to remember. That is what makes «which pool financed this stock?» a question with
 * one answer, and it is why the purchase screen no longer asks anyone to choose a container: the
 * material decides.
 *
 * A pool carries no stored money. Capital, deployable cash, stock at cost and unsettled profit
 * are all walked from the ledger and the cost layers when a screen asks.
 */
class InvestmentPoolController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly InvestorService $investors) {}

    /**
     * List pools
     *
     * By name, so the order is the same every time. Filter by `investor_id` or `stock_item_id`,
     * or search the name and code.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        return $this->successWithPagination(
            InvestmentPoolResource::collection(
                $this->investors->paginatePools(
                    $request->only(['search', 'investor_id', 'stock_item_id']),
                    $perPage,
                ),
            ),
        );
    }

    /**
     * Open a pool
     *
     * Names the material and the shelves it covers. The profit share may be given once, here, and
     * is seeded from the company default when it is not — after that it is the term the partners
     * were shown and is not editable.
     *
     * Refused if any shelf already belongs to another pool, or if any product standing on a shelf
     * is outside the investable headings.
     */
    public function store(StorePoolRequest $request): JsonResponse
    {
        $pool = $this->investors->createPool(
            PoolData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->created(new InvestmentPoolResource($pool), 'تم فتح الصندوق');
    }

    /**
     * Read a pool
     */
    public function show(InvestorDeal $pool): JsonResponse
    {
        $pool->load(['poolItems.stockItem', 'shares.investor']);

        // Attached rather than resolved inside the resource: the resource must stay a shape, and
        // the timing is a domain answer that GraceWindow owns. One screen, one round trip.
        $pool->capitalTiming = $this->timingPayload((int) $pool->getKey());

        // Read once here rather than per member inside the resource, which would be one settings
        // query per partner on a pool with nine of them.
        $pool->minimumTermMonths = $this->investors->minimumTermMonths();

        // One ledger walk for the whole roster, attached here rather than resolved per member
        // inside the resource — which would be a walk per partner on a pool with nine of them.
        $balances = $this->investors->dealBalances((int) $pool->getKey());
        $pool->memberCapital = $balances['per_investor'];
        $pool->poolCapital = $balances['capital'];

        return $this->success(new InvestmentPoolResource($pool));
    }

    /**
     * The grace-window answer, flattened for the wire.
     *
     * @return array<string, mixed>
     */
    private function timingPayload(int $poolId): array
    {
        $timing = $this->investors->capitalTimingFor($poolId);

        return [
            'current_period' => $timing['period'] === null
                ? null
                : new InvestmentPeriodResource($timing['period']),
            'grace_window_ends_on' => $timing['grace_window_ends_on'],
            'capital_takes_effect_on' => $timing['capital_takes_effect_on'],
            'is_inside_grace_window' => $timing['is_inside_grace_window'],
        ];
    }

    /**
     * Rename a pool, or change which shelves it buys
     *
     * **Changing the shelves moves no stock.** Cost layers keep the pool they were opened with for
     * ever, because they are what that pool's investors paid for; this decides where the next
     * lorry goes and nothing else, which is why it is safe while a period is open.
     */
    public function update(StorePoolRequest $request, InvestorDeal $pool): JsonResponse
    {
        $updated = $this->investors->updatePool(
            $pool,
            PoolData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->success(new InvestmentPoolResource($updated), 'تم تحديث الصندوق');
    }

    /**
     * Open the pool's next accounting period
     *
     * The dates come from the company calendar — the day after the last period ended, for
     * `profit_period_months` — never from the caller. **Also lets in the capital that was queued
     * for this boundary**, and reports anyone whose wallet could no longer cover what they had
     * asked for: their request stays pending, and the period opens regardless.
     */
    public function openPeriod(InvestorDeal $pool): JsonResponse
    {
        $result = $this->investors->openPeriod($pool);

        return $this->created([
            'period' => new InvestmentPeriodResource($result['period']),
            'applied' => InvestmentCapitalRequestResource::collection($result['applied']),
            // Keyed by request id. Empty on the ordinary open, which is most of them.
            'short' => $result['short'],
        ], 'تم فتح الفترة');
    }

    /**
     * The pool's periods
     */
    public function periods(InvestorDeal $pool): JsonResponse
    {
        $periods = $pool->periods()->orderByDesc('starts_on')->orderByDesc('id')->get();

        // Asked once, of the pool. A returned-goods question blocks whichever period is open, and
        // asking per row would be one query per period on a pool with a year of them.
        $open = $periods->first(fn (InvestmentPeriod $period) => $period->isOpen());

        if ($open !== null) {
            $open->blockedByReturnedGoods = $this->investors->periodFigures($open)['has_unanswered_returns'];
        }

        return $this->success(InvestmentPeriodResource::collection($periods));
    }

    /**
     * Offer capital to the pool, or ask for it back
     *
     * **Inside the grace window capital is taken now** and works for the whole period; outside it
     * the request is queued for the next boundary and the money stays in the investor's wallet
     * until then. A withdrawal is always queued, and executes at the close **after** that period's
     * profit has been distributed.
     *
     * Read `capital_timing` on the pool first: it says when the window shuts and what would happen
     * if this were submitted now, computed by the same function that then acts on it.
     */
    public function storeCapitalRequest(StoreCapitalRequestRequest $request, InvestorDeal $pool): JsonResponse
    {
        $capitalRequest = $this->investors->requestPoolCapital(
            $pool,
            CapitalRequestData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->created(
            new InvestmentCapitalRequestResource($capitalRequest->load('investor')),
            $capitalRequest->isPending()
                ? 'سُجّل الطلب — ينفَّذ مع بداية الفترة القادمة'
                : 'تم تنفيذ الطلب',
        );
    }

    /**
     * The pool's capital queue
     */
    public function capitalRequests(InvestorDeal $pool): JsonResponse
    {
        return $this->success(
            InvestmentCapitalRequestResource::collection(
                $pool->capitalRequests()->with('investor')->orderByDesc('requested_at')->orderByDesc('id')->get(),
            ),
        );
    }

    /**
     * Cancel a queued capital request
     *
     * Only before it has taken effect. Nothing is unwound, because a pending request never moved
     * money: the investor's deposit has been in his wallet the whole time.
     */
    public function cancelCapitalRequest(InvestmentCapitalRequest $capitalRequest): JsonResponse
    {
        return $this->success(
            new InvestmentCapitalRequestResource($this->investors->cancelCapitalRequest($capitalRequest)),
            'تم إلغاء الطلب',
        );
    }

    /**
     * Material a cancelled order gave back, waiting to be looked at
     *
     * **This is the list that holds the close up.** A printed order that is cancelled credits its
     * paper back to the shelf as good stock, and nothing in the system can tell whether there is
     * ink on it — so it is asked here, and {@see closePeriod} refuses while an answer is missing.
     *
     * Newest first, and open ones first within that, because the open ones are the work. Pass
     * `only_open=1` for just those — which is what a close screen should show.
     */
    public function returnedGoods(Request $request, InvestorDeal $pool): JsonResponse
    {
        $questions = $pool->returnedGoodsQuestions()
            ->with(['order', 'stockItem', 'answeredBy'])
            ->when(
                $request->boolean('only_open'),
                fn ($query) => $query->where('verdict', ReturnedGoodsVerdict::Open->value),
            )
            // Open before answered, so the outstanding work is never below the fold.
            ->orderByRaw("CASE WHEN verdict = 'open' THEN 0 ELSE 1 END")
            ->orderByDesc('id')
            ->get();

        return $this->success(InvestmentReturnedGoodsQuestionResource::collection($questions));
    }

    /**
     * «صالحة» أو «تالفة»
     *
     * **«تالفة» posts a damage adjustment, not an expense.** Ruined paper has to leave the shelf:
     * charged as a cost alone the pool would go on counting goods it does not have, its deployable
     * cash would be overstated by that amount, and the next lorry would be bought with money that
     * was never there.
     *
     * **«صالحة» writes nothing** — the goods really are back and really are usable. All that
     * changed is that somebody looked, and that is enough to let the period close.
     *
     * Answered once. A verdict is not a draft, and reopening one would mean unwinding a movement
     * the shelf has already been counted against.
     */
    public function answerReturnedGoods(
        AnswerReturnedGoodsRequest $request,
        InvestmentReturnedGoodsQuestion $returnedGoodsQuestion,
    ): JsonResponse {
        $answered = $this->investors->answerReturnedGoods(
            $returnedGoodsQuestion,
            ReturnedGoodsVerdict::from((string) $request->validated('verdict')),
            (int) $request->validated('warehouse_id'),
            (int) $request->user()?->id,
            $request->validated('notes'),
        );

        return $this->success(
            new InvestmentReturnedGoodsQuestionResource($answered->load(['order', 'stockItem', 'answeredBy'])),
            $answered->verdict === ReturnedGoodsVerdict::Damaged
                ? 'سُجّلت البضاعة تالفة وخُصمت من المخزون'
                : 'سُجّلت البضاعة صالحة',
        );
    }

    /**
     * What has been charged to this pool
     *
     * **Newest first, and `is_deducted` is what a screen leads with.** Shipping and customs typed
     * on a purchase order are already inside the cost of the goods; they are listed here and not
     * subtracted, and a row that looks identical to a deducted one invites somebody to add up a
     * total the close does not use.
     */
    public function expenses(InvestorDeal $pool): JsonResponse
    {
        return $this->success(
            InvestorDealExpenseResource::collection(
                $pool->expenses()->orderByDesc('incurred_on')->orderByDesc('id')->get(),
            ),
        );
    }

    /**
     * What the pool can spend
     *
     * Derived on every read — book value less the goods it is already holding. **Undrawn profit is
     * not in it**: once a period closes, an investor's share is his, and a purchase made with it
     * would be spending settled earnings. The screen shows the two figures and never their total.
     */
    public function deployableCash(InvestorDeal $pool): JsonResponse
    {
        return $this->success($this->investors->deployableCashFor((int) $pool->getKey()));
    }

    /**
     * Buy purchase-order lines with pool money
     *
     * **No pool is chosen here.** Each material belongs to exactly one pool, so the only decision
     * is pool money or the company's, one line at a time — and the storekeeper is still never asked
     * anything at receipt.
     *
     * `printing_sale_price` per line is سعر السادة for this lorry: what the press pays the pool for
     * a unit of its plain stock. Omit it and those goods ride the sale instead.
     *
     * Refused once a line has been received — the cost layer is stamped at the gate and can never
     * be stamped afterwards — and refused if a pool cannot cover its whole share of the lorry.
     */
    public function buyWithPoolMoney(BuyWithPoolMoneyRequest $request, PurchaseOrder $purchaseOrder): JsonResponse
    {
        $supplies = $this->investors->buyPurchaseOrderLinesFromPools(
            (int) $purchaseOrder->getKey(),
            PoolPurchaseData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->created(
            ['lines' => count($supplies)],
            'تم تحديد البنود التي تُشترى من مال الصناديق',
        );
    }

    /**
     * What a period made, and whether anything is holding its close up
     *
     * **The same arithmetic the close then performs.** A close is an irreversible payout, so the
     * screen that asks somebody to press the button prints its working from this — two
     * implementations of the sum is how a person approves one figure and the ledger writes another.
     *
     * `recorded_only_expenses` is the «محسوبة مسبقاً» total: costs already inside the goods, shown
     * beside the sum and never part of it.
     */
    public function periodFigures(InvestmentPeriod $period): JsonResponse
    {
        return $this->success(
            $this->investors->periodFigures($period) + [
                'period' => new InvestmentPeriodResource($period),
            ],
        );
    }

    /**
     * Who got what, in a closed period
     *
     * **The frozen record, not a fresh calculation.** These are the weights the close actually
     * applied and the amounts it actually paid — the answer to «لماذا أخذت هذا المبلغ في سبتمبر؟»
     * asked in December, when the live weights on the pool's screen bear no relation to the ones
     * that were used.
     *
     * Empty on an open period: nothing has been divided yet.
     */
    public function periodShares(InvestmentPeriod $period): JsonResponse
    {
        return $this->success(
            InvestmentPeriodShareResource::collection(
                $period->shares()->with('investor')->orderByDesc('net_share')->get(),
            ),
        );
    }

    /**
     * Close a period
     *
     * Divides what the period made, writes losses down against capital, releases profit into
     * wallets where it becomes withdrawable, pays whoever asked to leave — and opens the next
     * period in the same breath, so the pool is never without one.
     *
     * Refused while any returned-goods question is unanswered: a cancelled printed order credits
     * its material back **as good stock**, and closing over that divides profit the pool did not
     * earn on goods it does not have.
     */
    public function closePeriod(Request $request, InvestmentPeriod $period): JsonResponse
    {
        return $this->success(
            new InvestmentPeriodResource($this->investors->closePeriod($period, $request->user()?->id)),
            'تم إقفال الفترة وتوزيع الأرباح',
        );
    }

    /**
     * Where this pool's money is, right now
     *
     * **Worked out twice** — once from the wallet ledger and the periods, once by walking the
     * capital movements, the earnings, the expenses and every cost layer the pool ever bought. The
     * two never consult each other, so `drift` is a real comparison rather than the same
     * subtraction written backwards.
     *
     * **A non-zero drift is a finding.** The plain cause is a stock adjustment posted straight
     * through Inventory in a period that has since closed: the goods left the shelf, no loss was
     * charged to anybody, and nothing else in the system would ever mention it.
     *
     * `undeployed_current_profit` is the open period's undivided profit — real money the company is
     * holding that `deployable_cash` does **not** count as spendable. Shown beside it, never added
     * to it.
     */
    public function settlementSnapshot(InvestorDeal $pool): JsonResponse
    {
        return $this->success($this->investors->settlementSnapshotFor((int) $pool->getKey()));
    }

    /**
     * The pool's settlements
     */
    public function settlements(InvestorDeal $pool): JsonResponse
    {
        return $this->success(
            InvestmentSettlementResource::collection(
                $pool->settlements()->with('approvedBy')
                    ->orderByDesc('settled_on')->orderByDesc('id')->get(),
            ),
        );
    }

    /**
     * Sign off a settlement
     *
     * Freezes the figures above and puts a name to them. **Nothing moves** — no wallet row, no
     * stock movement, no period touched, and the pool trades on through it exactly as before.
     *
     * The payload carries no amounts and no period range: every figure is walked at the moment of
     * signing, because a settlement somebody could type the numbers into would approve a position
     * the system does not hold.
     *
     * A drift is written down and **left standing**. Posting an adjustment to zero it would destroy
     * the only thing the record is for.
     */
    public function storeSettlement(StoreSettlementRequest $request, InvestorDeal $pool): JsonResponse
    {
        $settlement = $this->investors->recordSettlement(
            $pool,
            $request->validated('settled_on'),
            $request->validated('approved_by') === null ? null : (int) $request->validated('approved_by'),
            $request->validated('notes'),
            $request->user()?->id,
        );

        return $this->created(
            new InvestmentSettlementResource($settlement->load('approvedBy')),
            $settlement->hasDrift()
                ? 'سُجّلت التسوية — وفيها فرق يحتاج تفسيراً'
                : 'سُجّلت التسوية',
        );
    }

    /**
     * The pool's change log
     */
    public function logs(ActivityLogFilterRequest $request, AuditService $audit, InvestorDeal $pool): JsonResponse
    {
        return $this->auditTrailFor($request, $audit, $pool);
    }
}
