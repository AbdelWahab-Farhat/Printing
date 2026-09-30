<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\PurchaseOrder\StoreVendorPaymentRequest;
use App\Application\Api\V1\Requests\Treasury\ReverseTreasuryOperationRequest;
use App\Application\Api\V1\Resources\VendorPaymentResource;
use App\Application\Controller;
use App\Domain\PurchaseOrder\DTOs\VendorPaymentData;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\PurchaseOrderService;
use App\Domain\Vendor\Models\Vendor;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * دفعات الموردين — what the company paid each vendor, and what it still owes.
 */
class VendorPaymentController extends Controller
{
    use ResponseTrait;

    private const RELATIONS = ['treasuryAccount', 'recorder', 'reversal'];

    public function __construct(private readonly PurchaseOrderService $orders) {}

    public function index(Vendor $vendor): JsonResponse
    {
        return $this->success([
            'summary' => $this->orders->vendorPaymentSummary((int) $vendor->getKey()),
            'payments' => VendorPaymentResource::collection(
                VendorPayment::query()
                    ->where('vendor_id', $vendor->getKey())
                    ->with(self::RELATIONS)
                    ->orderByDesc('paid_at')
                    ->orderByDesc('id')
                    ->get(),
            ),
        ]);
    }

    public function forPurchaseOrder(PurchaseOrder $purchaseOrder): JsonResponse
    {
        return $this->success([
            'summary' => $this->orders->purchaseOrderPaymentSummary($purchaseOrder),
            'payments' => VendorPaymentResource::collection(
                VendorPayment::query()
                    ->where('purchase_order_id', $purchaseOrder->getKey())
                    ->with(self::RELATIONS)
                    ->orderByDesc('paid_at')
                    ->orderByDesc('id')
                    ->get(),
            ),
        ]);
    }

    public function store(StoreVendorPaymentRequest $request, Vendor $vendor): JsonResponse
    {
        $payment = $this->orders->recordVendorPayment(
            $vendor,
            VendorPaymentData::fromArray($request->validated()),
            $request->user(),
        );

        return $this->created(new VendorPaymentResource($payment->load(self::RELATIONS)), 'تم تسجيل الدفعة');
    }

    public function reverse(ReverseTreasuryOperationRequest $request, Vendor $vendor, VendorPayment $payment): JsonResponse
    {
        if ((int) $payment->vendor_id !== (int) $vendor->getKey()) {
            throw VendorPaymentRefused::notThisVendors();
        }

        $reversal = $this->orders->reverseVendorPayment(
            $payment,
            (string) $request->validated('reason'),
            $request->user(),
        );

        return $this->created(new VendorPaymentResource($reversal->load(self::RELATIONS)), 'تم عكس الدفعة');
    }
}
