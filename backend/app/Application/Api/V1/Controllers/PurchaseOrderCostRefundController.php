<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\PurchaseOrder\RefundAdditionalCostRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\ReverseCostRefundRequest;
use App\Application\Api\V1\Resources\PurchaseOrderResource;
use App\Application\Controller;
use App\Domain\PurchaseOrder\DTOs\RefundAdditionalCostData;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderCostRefund;
use App\Domain\PurchaseOrder\PurchaseOrderService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * Purchase order cost refunds
 *
 * Money coming back on a cost paid from a drawer or owed to a manual payable, on an order past
 * `new` — cancelled ones included — and taking such a refund back. Both need `treasury.reverse`
 * and `purchase_orders.view`. See PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
 */
class PurchaseOrderCostRefundController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly PurchaseOrderService $purchaseOrders) {}

    /**
     * Refund a cost
     *
     * The money returns to the account that paid; the order's totals, the vendor's debt and the
     * stock's cost do not move. Refused past what is left of the cost.
     */
    public function store(
        RefundAdditionalCostRequest $request,
        PurchaseOrder $purchaseOrder,
        PurchaseOrderAdditionalCost $additionalCost,
    ): JsonResponse {
        $this->purchaseOrders->refundCost(
            $purchaseOrder,
            $additionalCost,
            RefundAdditionalCostData::fromArray($request->validated(), (int) $request->user()->id),
        );

        return $this->success(
            new PurchaseOrderResource($this->purchaseOrders->find((int) $purchaseOrder->getKey())),
            'تم استرداد المبلغ بنجاح',
        );
    }

    /**
     * Take a refund back
     *
     * For a refund recorded in error: the expense stands again for that much.
     */
    public function reverse(
        ReverseCostRefundRequest $request,
        PurchaseOrder $purchaseOrder,
        PurchaseOrderAdditionalCost $additionalCost,
        PurchaseOrderCostRefund $refund,
    ): JsonResponse {
        $this->purchaseOrders->reverseCostRefund(
            $purchaseOrder,
            $additionalCost,
            $refund,
            trim((string) $request->validated('reason')),
            (int) $request->user()->id,
        );

        return $this->success(
            new PurchaseOrderResource($this->purchaseOrders->find((int) $purchaseOrder->getKey())),
            'تم التراجع عن الاسترداد بنجاح',
        );
    }
}
