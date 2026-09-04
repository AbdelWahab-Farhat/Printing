<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Investor\StoreDealExpenseRequest;
use App\Application\Api\V1\Requests\Investor\StoreInvestorDealRequest;
use App\Application\Api\V1\Resources\InvestorDealResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\InvestorDealData;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestorDeal;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Investor deals
 *
 * صفقات المستثمرين — one financed purchase of stock. A deal names the shelves it funds and the
 * people who are in it; from there the system does the rest.
 *
 * **Nobody chooses a deal when goods arrive or when they are sold.** The funding is declared
 * against a purchase order before the lorry gets here, and the sale draws from the oldest cost
 * layer first exactly as it always has. The deal's numbers are read out of that afterwards.
 *
 * A deal carries no stored money: capital, profit and quantities are all walked from the ledgers
 * when a screen asks.
 */
class InvestorDealController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly InvestorService $investors) {}

    /**
     * List deals
     *
     * Newest first. Filter by `status`, by `investor_id`, or search the name and code.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        return $this->successWithPagination(
            InvestorDealResource::collection(
                $this->investors->paginateDeals($request->only(['search', 'status', 'investor_id']), $perPage),
            ),
        );
    }

    /**
     * Create a deal
     *
     * Born as a draft: its shelves, its participants and their percentages are all still
     * editable, and no stock may be claimed for it yet. `investor_profit_share_percent` may be
     * omitted, in which case the company default fills it.
     */
    public function store(StoreInvestorDealRequest $request): JsonResponse
    {
        $deal = $this->investors->createDeal(
            InvestorDealData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->created(new InvestorDealResource($deal), 'تم إنشاء الصفقة');
    }

    /**
     * Show a deal
     *
     * The whole screen in one payload: the deal, its shelves, its investors, what its goods are
     * doing, and what each investor is holding and has earned.
     */
    public function show(InvestorDeal $deal): JsonResponse
    {
        $deal->load(['product', 'items.stockItem', 'shares.investor']);

        $deal->setAttribute('balances', $this->investors->dealBalances((int) $deal->getKey()));
        $deal->setAttribute('stock', $this->investors->dealStock((int) $deal->getKey()));

        return $this->success(new InvestorDealResource($deal));
    }

    /**
     * Open a deal
     *
     * Goods may now be claimed for it — and its terms close in the same breath, because they are
     * what the money will be split by.
     */
    public function open(InvestorDeal $deal): JsonResponse
    {
        return $this->success(
            new InvestorDealResource($this->investors->openDeal($deal)),
            'تم فتح الصفقة',
        );
    }

    /**
     * Close a deal
     *
     * Settles each investor's result and returns his money to his wallet — and this is the only
     * moment his profit becomes withdrawable.
     *
     * Refused while any stock is left, and refused while any order that took this deal's goods
     * has not reached the customer: stock leaves the shelf days before a parcel is delivered,
     * and a parcel that comes home and is cancelled puts the goods back into this deal's layers.
     */
    public function close(InvestorDeal $deal): JsonResponse
    {
        return $this->success(
            new InvestorDealResource($this->investors->closeDeal($deal)),
            'تم إغلاق الصفقة وتسوية حسابات المستثمرين',
        );
    }

    /**
     * Cancel a deal
     *
     * From a draft only. A deal that already owns goods is closed, not cancelled — FIFO would go
     * on drawing from its layers whatever its status said.
     */
    public function cancel(Request $request, InvestorDeal $deal): JsonResponse
    {
        $reason = (string) $request->validate([
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ])['reason'];

        return $this->success(
            new InvestorDealResource($this->investors->cancelDeal($deal, $reason)),
            'تم إلغاء الصفقة',
        );
    }

    /**
     * Declare which purchase-order line this deal finances
     *
     * Made before the goods arrive. At receipt the system resolves it per line, so the person
     * receiving the shipment never sees a deal field at all.
     */
    public function claimSupply(Request $request, InvestorDeal $deal): JsonResponse
    {
        $validated = $request->validate([
            'purchase_order_id' => ['required', 'integer', 'exists:purchase_orders,id'],
            'stock_item_id' => ['required', 'integer', 'exists:stock_items,id'],
        ]);

        $this->investors->claimSupply(
            $deal,
            (int) $validated['purchase_order_id'],
            (int) $validated['stock_item_id'],
            $request->user()?->id,
        );

        return $this->successMessage('تم إقرار تمويل البند');
    }

    /**
     * Record a deal expense
     *
     * Shipping, customs, transport, storage. The investors are charged their share of it at
     * once, by the same percentages a profit is split by.
     *
     * Costs typed on a purchase order are **not** entered here: they are already inside what the
     * goods cost, and charging them again pays for one invoice twice.
     */
    public function storeExpense(StoreDealExpenseRequest $request, InvestorDeal $deal): JsonResponse
    {
        $this->investors->recordDealExpense(
            $deal,
            DealExpenseData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->successMessage('تم تسجيل المصروف وخصم حصة المستثمرين منه');
    }

    /**
     * A deal's history
     */
    public function logs(ActivityLogFilterRequest $request, AuditService $audit, InvestorDeal $deal): JsonResponse
    {
        return $this->auditTrailFor($request, $audit, $deal);
    }
}
