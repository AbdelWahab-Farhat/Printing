<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\ChangePurchaseOrderStatusRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\ReceivePurchaseOrderArrivalRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\StorePurchaseOrderRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\UpdatePurchaseOrderRequest;
use App\Application\Api\V1\Resources\PurchaseOrderResource;
use App\Application\Api\V1\Resources\StockArrivalResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderTransitionNotAllowed;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\PurchaseOrderService;
use App\Domain\PurchaseOrder\Queries\PurchaseOrderFilters;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Purchase orders
 *
 * Stock ordered from a vendor ahead of it arriving: `new → arrived → completed`, with
 * `cancelled` reachable from either open status — see `PurchaseOrderStatus`. Reading needs
 * `purchase_orders.view`; drafting, editing, sending and cancelling need
 * `purchase_orders.manage`. Receiving a shipment against one needs `inventory.manage` instead —
 * see {@see receiveArrival()} — the same guard `POST /stock-arrivals` already sits behind,
 * because posting a shipment is squarely part of that area regardless of which door it came in.
 *
 * No destroy route: a purchase order is paperwork with real history behind it the moment
 * anything ships against it, the same reasoning that leaves `StockArrival` without one.
 */
class PurchaseOrderController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly PurchaseOrderService $purchaseOrders) {}

    /**
     * List purchase orders
     *
     * Newest first. Filter with `vendor_id`, `warehouse_id` and `status`.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = PurchaseOrderFilters::fromArray($request->only(['vendor_id', 'warehouse_id', 'status']));
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        return $this->successWithPagination(
            PurchaseOrderResource::collection($this->purchaseOrders->paginate($filters, $perPage)),
        );
    }

    /**
     * Create a purchase order
     *
     * Always drafted as `new`. Nothing is sent to the vendor and no stock moves until it is
     * marked as sent or a shipment is received against it.
     */
    public function store(StorePurchaseOrderRequest $request): JsonResponse
    {
        $order = $this->purchaseOrders->create(PurchaseOrderData::fromArray($request->validated()));

        return $this->created(new PurchaseOrderResource($order), 'تم إنشاء أمر الشراء بنجاح');
    }

    /**
     * Get one purchase order
     */
    public function show(PurchaseOrder $purchaseOrder): JsonResponse
    {
        return $this->success(new PurchaseOrderResource(
            $purchaseOrder->load(['vendor', 'warehouse', 'items.productVariant.product', 'additionalCosts']),
        ));
    }

    /**
     * Update a purchase order
     *
     * Only while it is still `new` — refused with 422 otherwise. Lines are replaced wholesale:
     * an item carrying an `id` updates that line, one without creates a new line, and any
     * existing line missing from the set is removed.
     */
    public function update(UpdatePurchaseOrderRequest $request, PurchaseOrder $purchaseOrder): JsonResponse
    {
        $updated = $this->purchaseOrders->update($purchaseOrder, PurchaseOrderData::fromArray($request->validated()));

        return $this->success(new PurchaseOrderResource($updated), 'تم تحديث أمر الشراء بنجاح');
    }

    /**
     * Change a purchase order's status
     *
     * Manual moves only: `arrived` (marks it as sent to the vendor) or `cancelled`. `completed`
     * is never set this way — it is reached only once {@see PurchaseOrderService::receiveArrival()}
     * finds every line fully received.
     */
    public function changeStatus(ChangePurchaseOrderStatusRequest $request, PurchaseOrder $purchaseOrder): JsonResponse
    {
        $updated = match ($target = $request->status()) {
            PurchaseOrderStatus::Arrived => $this->purchaseOrders->send($purchaseOrder),
            PurchaseOrderStatus::Cancelled => $this->purchaseOrders->cancel($purchaseOrder),
            // Unreachable while ChangePurchaseOrderStatusRequest keeps restricting the input to
            // the two cases above — kept so a future third manual target fails loudly with a
            // readable message instead of an UnhandledMatchError leaking as a raw 500.
            default => throw PurchaseOrderTransitionNotAllowed::make($purchaseOrder->status, $target),
        };

        return $this->success(new PurchaseOrderResource($updated), 'تم تحديث حالة أمر الشراء بنجاح');
    }

    /**
     * Receive a shipment against a purchase order
     *
     * Posts a stock arrival the same way `POST /stock-arrivals` does — into the order's own
     * vendor and warehouse, which is why neither is part of this payload — and updates the
     * order's own lines and status from what came in. A line's total received quantity may never
     * exceed what was ordered, and the order moves to `completed` the moment every line is.
     *
     * `received_by` is stamped from the authenticated user, never read from the body, so a
     * receipt can never be attributed to a colleague.
     */
    public function receiveArrival(ReceivePurchaseOrderArrivalRequest $request, PurchaseOrder $purchaseOrder): JsonResponse
    {
        $arrival = $this->purchaseOrders->receiveArrival(
            $purchaseOrder,
            ReceivePurchaseOrderData::fromArray($request->validated(), (int) $request->user()->id),
        );

        return $this->created(new StockArrivalResource($arrival), 'تم تسجيل استلام الشحنة بنجاح');
    }

    /**
     * A purchase order's history
     *
     * Every change to the order and its lines, newest first — who made it and what it was
     * before. Filter with `event`, `causer_id`, `from` and `to`.
     */
    public function logs(ActivityLogFilterRequest $request, PurchaseOrder $purchaseOrder, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $purchaseOrder, $audit);
    }
}
