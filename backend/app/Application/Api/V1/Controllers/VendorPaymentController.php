<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\PurchaseOrder\StoreVendorPaymentRequest;
use App\Application\Api\V1\Requests\Treasury\ReverseTreasuryOperationRequest;
use App\Application\Api\V1\Resources\VendorPaymentResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\PurchaseOrder\DTOs\VendorPaymentData;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\PurchaseOrderService;
use App\Domain\Vendor\Models\Vendor;
use App\Support\ResponseTrait;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;

/**
 * دفعات الموردين — what the company paid each vendor, and what it still owes.
 */
class VendorPaymentController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

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

    /**
     * `client_token` يجعل الإعادةَ آمنة: الرمزُ نفسه مرّةً ثانية يُرجع الدفعةَ الأولى بحالة 200
     * ولا يدفع شيئاً.
     */
    public function store(StoreVendorPaymentRequest $request, Vendor $vendor): JsonResponse
    {
        $payment = $this->orders->recordVendorPayment(
            $vendor,
            VendorPaymentData::fromArray($request->validated()),
            $request->user(),
        );
        $resource = new VendorPaymentResource($payment->load(self::RELATIONS));

        if (! $payment->wasRecentlyCreated) {
            return $this->success($resource, 'هذه الدفعة مسجَّلة من قبل');
        }

        return $this->created($resource, 'تم تسجيل الدفعة');
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

    /**
     * تاريخُ الدفعة — خلف `logs.view` كبقيّة السجلّات.
     *
     * **دفعةُ موردٍ آخر 404**، كما يفعل الربطُ المقيَّد في سجلّات ملاحظات المورد. ولا ربطَ مقيَّداً
     * هنا لأنه يحتاج علاقةً من `Vendor` إلى دفعاته، والاعتمادُ يسير PurchaseOrder → Vendor لا عكسه.
     */
    public function logs(
        ActivityLogFilterRequest $request,
        Vendor $vendor,
        VendorPayment $payment,
        AuditService $audit,
    ): JsonResponse {
        if ((int) $payment->vendor_id !== (int) $vendor->getKey()) {
            throw (new ModelNotFoundException)->setModel(VendorPayment::class, [$payment->id]);
        }

        return $this->auditTrailResponse($request, $payment, $audit);
    }
}
