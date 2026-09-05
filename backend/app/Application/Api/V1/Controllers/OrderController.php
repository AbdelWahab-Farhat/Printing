<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Order\ChangeOrderStatusRequest;
use App\Application\Api\V1\Requests\Order\RecordScrapLossRequest;
use App\Application\Api\V1\Requests\Order\ReinstateOrderRequest;
use App\Application\Api\V1\Requests\Order\ReviewOrderDesignRequest;
use App\Application\Api\V1\Requests\Order\SetOrderShortagesRequest;
use App\Application\Api\V1\Requests\Order\StoreOrderDesignRequest;
use App\Application\Api\V1\Requests\Order\StoreOrderRequest;
use App\Application\Api\V1\Requests\Order\UpdateOrderRequest;
use App\Application\Api\V1\Resources\OrderDesignResource;
use App\Application\Api\V1\Resources\OrderResource;
use App\Application\Api\V1\Resources\ProductionCostEntryResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Carrier\CarrierService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Order\Queries\OrderFilters;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Orders
 *
 * A job of work: bags printed for a customer and got to them.
 *
 * An order moves through a state machine — جديدة، قيد التصميم، قيد الطباعة، جاهزة، نواقص، then
 * out for delivery or waiting at a branch, then delivered, returned or cancelled. Every legal
 * move is defined once, on `OrderStatus`, and each one costs its own permission so the business
 * can compose a designer, a printer and a delivery coordinator out of the catalogue.
 *
 * **Read `available_transitions` on an order rather than reimplementing the rules.** It is
 * already narrowed to what the signed-in user may do, so a client that renders exactly those
 * buttons can never offer a move the server will refuse.
 *
 * Money is never accepted from the client: line prices come from the catalogue's own quote, the
 * delivery price is copied from the destination city, and the totals are derived from the lines.
 */
class OrderController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(
        private readonly OrderService $orders,
        // **The carrier is wired in here rather than inside the domain**, because `Order` may not
        // import `Carrier` — dependencies run one way — and because a carrier outage must never
        // roll back a status change that describes something physical.
        private readonly CarrierService $carrier,
    ) {}

    /**
     * List orders
     *
     * Newest first. `search` matches the order number, the tracking number, or the customer's
     * name, code or phone. Filter with `status` (repeatable), `payment_status` (repeatable —
     * `unpaid`, `partially_paid`, `paid`, `overpaid`), `customer_id`, `city_id`, `from` and `to`.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = OrderFilters::fromArray(
            $request->only(['search', 'status', 'payment_status', 'customer_id', 'city_id', 'from', 'to']),
        );
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        return $this->successWithPagination(
            OrderResource::collection($this->withParcelCodes($this->orders->paginate($filters, $perPage))),
        );
    }

    /**
     * How many orders are in each status
     *
     * The number beside each row of the status filter. Accepts the same filters as the list —
     * `search`, `payment_status`, `customer_id`, `city_id`, `from`, `to` — so the counts describe
     * the set the user is actually looking at.
     *
     * `status` itself is ignored here on purpose: counts narrowed to the status already chosen
     * would every one of them equal the list's own length. `payment_status` is *not* ignored,
     * because it narrows a different axis — «كم طلبية غير مدفوعة في كل حالة؟» is a real question,
     * and it is the whole reason the two were never merged into one enum.
     *
     * Every status is present, zeros included. A missing key would leave a client choosing
     * between a blank and a zero, and those mean different things.
     */
    public function statusCounts(Request $request): JsonResponse
    {
        $filters = OrderFilters::fromArray(
            $request->only(['search', 'payment_status', 'customer_id', 'city_id', 'from', 'to']),
        );

        $counts = $this->orders->statusCounts($filters);
        $paymentCounts = $this->orders->paymentStatusCounts($filters);

        return $this->success([
            'counts' => $counts,
            'total' => array_sum($counts),
            // **A second axis, sent beside the first rather than folded into it.** «جاهزة» says
            // nothing about whether an order is paid, so the two sets of numbers describe the
            // same orders along lines that cross — which is exactly why the filter offers both.
            'payment_counts' => $paymentCounts,
        ]);
    }

    /**
     * Take an order
     *
     * Lines are priced by the catalogue, so `unit_price` is ignored for any product with listed
     * prices. A product the catalogue prices on request has no number to fall back on and
     * requires one.
     *
     * A non-zero `discount` needs the `orders.discount` permission and is refused with 403
     * without it. A non-zero `additional_cost` needs `orders.additional_cost`, its own grant
     * rather than the discount's — and it must name a reason, because that is the axis this
     * money is read along afterwards.
     *
     * `design_ids` attaches artwork from the customer's library as the order is taken — for the
     * customer who arrives with the file already agreed, so the order never has to visit
     * «قيد التصميم» to hold it. Versions are numbered in the order sent. All of it is one
     * transaction: a design belonging to another customer is a 422 and no order is created.
     */
    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->orders->create(
            OrderData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->created(
            new OrderResource($this->withParcelCode($this->orders->loadForDisplay($order))),
            'تم إنشاء الطلبية بنجاح',
        );
    }

    /**
     * Get one order
     *
     * Includes the lines, every design version and the full status timeline.
     */
    public function show(Order $order): JsonResponse
    {
        return $this->success(new OrderResource($this->withParcelCode($this->orders->loadForDisplay($order))));
    }

    /**
     * Update an order
     *
     * Sending `items` replaces the whole set; omitting it leaves the lines untouched. The lines
     * close once printing starts, and the destination freezes once the parcel is with a courier
     * or a carrier.
     *
     * The customer cannot be changed: an order belongs to whoever placed it.
     */
    public function update(UpdateOrderRequest $request, Order $order): JsonResponse
    {
        $updated = $this->orders->update(
            $order,
            OrderData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->success(
            new OrderResource($this->withParcelCode($this->orders->loadForDisplay($updated))),
            'تم تحديث الطلبية بنجاح',
        );
    }

    /**
     * Move an order
     *
     * Refuses with 422 any move not on the map, and with 403 when the signed-in user lacks the
     * permission that status costs.
     *
     * **Dispatch is decided by the destination.** Sending either `office_pickup` or
     * `out_for_delivery` produces whichever one the order's city implies — the clerk says "it is
     * going out" and the address settles what that means.
     *
     * Cancelling requires `reason`.
     */
    public function changeStatus(ChangeOrderStatusRequest $request, Order $order): JsonResponse
    {
        $updated = $this->orders->changeStatus(
            $order,
            OrderStatus::from((string) $request->validated('status')),
            $request->validated('reason'),
            $this->actor($request),
            // Whatever this particular move asked for. Already narrowed by the request to the
            // keys the transition offered, so nothing reaches the domain that was not described.
            (array) $request->validated('fields', []),
        );

        $this->tellTheCarrier($updated);

        return $this->success(
            new OrderResource($this->withParcelCode($this->orders->loadForDisplay($updated))),
            "تم نقل الطلبية إلى «{$updated->status->label()}»",
        );
    }

    /**
     * Hands the parcel to Nawris once the move has already committed.
     *
     * **After the status change, never inside it**, and the ordering is the point: the order is
     * physically going out, so a carrier that is down, misconfigured or refusing must not undo
     * that. If lodging fails the exception surfaces — the clerk needs to know the parcel is not
     * with the carrier — and the order stays dispatched, findable through
     * `CarrierService::ordersNotLodged()` and retryable.
     *
     * Silent for everything that is not a Nawris delivery: an office pickup, an unmapped city, or
     * a deployment with no credentials yet. None of those is an error.
     */
    private function tellTheCarrier(Order $order): void
    {
        if (! $this->carrier->shouldDispatch($order)) {
            return;
        }

        if ($order->status === OrderStatus::OutForDelivery && $this->carrier->openParcelFor($order) === null) {
            $this->carrier->dispatchOrder($order);
        }
    }

    /**
     * Undo a cancellation
     *
     * Puts an order written off by mistake back **exactly where it stood** when it was
     * cancelled, read from its own timeline. There is no destination to send: an undo that let
     * a caller name one would be a second, unguarded way into statuses the state machine
     * deliberately makes unreachable from «إلغاء تام». Read `reinstate_to_label` on the order to
     * show somebody where it is going before they tap.
     *
     * **No stock moves.** The cancellation already credited the goods back to the shelf, and
     * this does not take them out again — putting the warehouse right afterwards is done by
     * hand, on purpose.
     *
     * The cancellation stays in the order's history with its reason; this move is written above
     * it, and the order stops carrying `cancelled_at` and `cancellation_reason`. `reason` here
     * is an optional note on that row.
     *
     * Refused with 422 on an order that is not cancelled, and on one whose timeline does not
     * record what it was cancelled from.
     */
    public function reinstate(ReinstateOrderRequest $request, Order $order): JsonResponse
    {
        $updated = $this->orders->reinstate(
            $order,
            $request->validated('reason'),
            $this->actor($request),
        );

        return $this->success(
            new OrderResource($this->orders->loadForDisplay($updated)),
            "تم التراجع عن الإلغاء، وأُعيدت الطلبية إلى «{$updated->status->label()}»",
        );
    }

    /**
     * Correct an order's shortages
     *
     * What is missing from each line, and therefore what the customer is charged: a line is
     * billed for the quantity ordered less the quantity missing, at the price it was agreed at.
     * The price is never re-quoted for the smaller quantity — the shortage is the shop's, not
     * the customer's.
     *
     * **The set is replaced.** Send every line that is short; a line left out of the payload is
     * recorded as having nothing missing. That is how a shortage is un-recorded, and doing so
     * puts the invoice back to the number it was, exactly.
     *
     * Accepted while the order's lines are still open — «جديدة», «قيد التصميم», «نواقص» and
     * «قيد الطباعة» — and refused with 422 from «جاهزة» onwards, when the run has been made and
     * counted. If the invoice drops below what has already been collected, the order simply
     * reads as overpaid and the difference is refunded through the ledger.
     */
    public function setShortages(SetOrderShortagesRequest $request, Order $order): JsonResponse
    {
        $updated = $this->orders->setShortages(
            $order,
            (array) $request->validated('shortages', []),
        );

        return $this->success(
            new OrderResource($this->withParcelCode($this->orders->loadForDisplay($updated))),
            'تم تحديث نواقص الطلبية',
        );
    }

    /**
     * Propose a design
     *
     * Chosen from the customer's own library rather than uploaded here — upload it against the
     * customer first. Another customer's design is refused with 422.
     *
     * Each call adds the next version. Accepted while the order is «جديدة» or «قيد التصميم»,
     * and refused with 422 from «قيد الطباعة» onwards — the press is running against a settled
     * file, and changing it starts by sending the order back to design.
     *
     * The first version may also arrive with the order itself, through `design_ids` on
     * `POST /orders`.
     */
    public function storeDesign(StoreOrderDesignRequest $request, Order $order): JsonResponse
    {
        $design = $this->orders->addDesign(
            $order,
            (int) $request->validated('customer_design_id'),
            $request->validated('notes'),
        );

        return $this->created(
            new OrderDesignResource($design->load('customerDesign')),
            'تم إضافة التصميم بنجاح',
        );
    }

    /**
     * Approve or reject a design
     *
     * A version is judged once. Approving supersedes whatever was approved before, which is
     * recorded on the old version rather than erased. Rejecting requires `rejection_reason`.
     */
    public function reviewDesign(
        ReviewOrderDesignRequest $request,
        Order $order,
        OrderDesign $design,
    ): JsonResponse {
        $reviewed = $this->orders->reviewDesign(
            $order,
            $design,
            OrderDesignStatus::from((string) $request->validated('status')),
            $request->validated('rejection_reason'),
            $this->actor($request),
        );

        return $this->success(
            new OrderDesignResource($reviewed->load('customerDesign')),
            $reviewed->status === OrderDesignStatus::Approved
                ? 'تم اعتماد التصميم'
                : 'تم رفض التصميم',
        );
    }

    /**
     * Record scrap
     *
     * Bags spoiled producing this line — a misprint, a run gone wrong. Only possible once the
     * order has reached printing; refused with 422 before then.
     *
     * The cost is drawn from the same FIFO layers the line's own fulfillment used, never typed —
     * the number the storekeeper enters is a quantity, not a price.
     */
    public function storeScrapLoss(RecordScrapLossRequest $request, Order $order, OrderItem $item): JsonResponse
    {
        $entry = $this->orders->recordScrapLoss(
            $order,
            $item,
            (string) $request->validated('quantity'),
            (string) $request->validated('notes'),
            $this->actor($request),
        );

        return $this->created(new ProductionCostEntryResource($entry), 'تم تسجيل التلف بنجاح');
    }

    /**
     * An order's history
     *
     * Every change to the order, its lines, its designs and its status moves, newest first —
     * who made it and what it was before.
     *
     * Filter with `event`, `causer_id`, `from` and `to`.
     */
    public function logs(ActivityLogFilterRequest $request, Order $order, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $order, $audit);
    }

    /**
     * The signed-in user, typed for the domain.
     *
     * The actions take the actor as an argument rather than reaching for the auth facade, so a
     * console command or a test can say who is acting without a global to set up.
     */
    private function actor(Request $request): ?User
    {
        $user = $request->user();

        return $user instanceof User ? $user : null;
    }

    /**
     * Hangs the carrier's parcel code on one order, for the resource to publish.
     *
     * **Here rather than in `OrderService`, and that is the architecture rather than taste.**
     * `Order` may not know that a carrier exists — the back-reference is the cycle RULES §3
     * forbids, and `CarrierService::ordersNotLodged()` refuses the same convenience in the same
     * words. A controller is the one place allowed to know both contexts, so this is where the
     * two are joined.
     *
     * Applied at **every** site that returns one order, not only `show`: the app patches a row in
     * the list from whatever a status change or an edit hands back, so an endpoint that omitted
     * the key would blank a code that is still perfectly true.
     */
    private function withParcelCode(Order $order): Order
    {
        $codes = $this->carrier->parcelCodesFor([(int) $order->getKey()]);

        if (isset($codes[(int) $order->getKey()])) {
            $order->setAttribute('nawris_parcel', $codes[(int) $order->getKey()]);
        }

        return $order;
    }

    /**
     * The same for a page of them, in one query rather than one per row.
     *
     * @template TPaginator of \Illuminate\Contracts\Pagination\LengthAwarePaginator<int, Order>
     *
     * @param  TPaginator  $orders
     * @return TPaginator
     */
    private function withParcelCodes($orders)
    {
        $codes = $this->carrier->parcelCodesFor(
            $orders->getCollection()->map(fn (Order $order) => (int) $order->getKey())->all(),
        );

        foreach ($orders->getCollection() as $order) {
            if (isset($codes[(int) $order->getKey()])) {
                $order->setAttribute('nawris_parcel', $codes[(int) $order->getKey()]);
            }
        }

        return $orders;
    }
}
