<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Order\ChangeOrderStatusRequest;
use App\Application\Api\V1\Requests\Order\ReviewOrderDesignRequest;
use App\Application\Api\V1\Requests\Order\StoreOrderDesignRequest;
use App\Application\Api\V1\Requests\Order\StoreOrderRequest;
use App\Application\Api\V1\Requests\Order\UpdateOrderRequest;
use App\Application\Api\V1\Resources\OrderDesignResource;
use App\Application\Api\V1\Resources\OrderResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
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

    public function __construct(private readonly OrderService $orders) {}

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
            OrderResource::collection($this->orders->paginate($filters, $perPage)),
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
     * without it.
     */
    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->orders->create(
            OrderData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->created(
            new OrderResource($this->orders->loadForDisplay($order)),
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
        return $this->success(new OrderResource($this->orders->loadForDisplay($order)));
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
            new OrderResource($this->orders->loadForDisplay($updated)),
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

        return $this->success(
            new OrderResource($this->orders->loadForDisplay($updated)),
            "تم نقل الطلبية إلى «{$updated->status->label()}»",
        );
    }

    /**
     * Propose a design
     *
     * Chosen from the customer's own library rather than uploaded here — upload it against the
     * customer first. Another customer's design is refused with 422.
     *
     * Each call adds the next version; the order stays «قيد التصميم» while versions come and go.
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
}
