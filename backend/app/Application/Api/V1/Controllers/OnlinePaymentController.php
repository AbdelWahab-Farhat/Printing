<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\OnlinePayment\RecordEzonePayoutRequest;
use App\Application\Api\V1\Requests\OnlinePayment\UpdateOnlinePaymentMethodRequest;
use App\Application\Api\V1\Resources\OnlinePaymentMethodResource;
use App\Application\Api\V1\Resources\PaymentIntentResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\OnlinePaymentService;
use App\Domain\OnlinePayment\Support\Money;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/**
 * Online payments
 *
 * «المدفوعات الإلكترونية» for staff — Docs/payments/CUSTOMER-WALLET.md §٥: every attempt to top up
 * a wallet through EzonePay, «إعادة التحقق» on one, the methods and their limits, and «تحويل Ezone
 * إلى المصرف» (step 6).
 */
class OnlinePaymentController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly OnlinePaymentService $payments,
        private readonly TreasuryService $treasury,
    ) {}

    /**
     * Every attempt
     *
     * Newest first. `meta.enabled` says whether online payments are switched on, and
     * `meta.ezone_balance` what EzonePay holds for the shop.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'status' => ['nullable', Rule::enum(IntentStatus::class)],
            'method' => ['nullable', 'integer', Rule::enum(OnlineMethod::class)],
            'customer_id' => ['nullable', 'integer'],
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        return $this->successWithPagination(
            PaymentIntentResource::collection($this->payments->intents($filters, $perPage)),
            extraMeta: [
                'enabled' => $this->payments->isEnabled(),
                'ezone_balance' => $this->treasury->balanceOf($this->treasury->systemAccount(TreasuryAccount::EZONE)),
            ],
        );
    }

    /**
     * Ask EzonePay again
     *
     * Paid: credited, once. Not paid and past its time: expired. A lost webhook is caught here or
     * by the five-minute recheck.
     */
    public function recheck(PaymentIntent $intent): JsonResponse
    {
        return $this->success(
            new PaymentIntentResource($this->payments->recheck($intent)->load('customer')),
            'تم التحقق من العملية',
        );
    }

    /**
     * The methods and their limits
     */
    public function methods(): JsonResponse
    {
        return $this->success([
            'enabled' => $this->payments->isEnabled(),
            'fee_payer' => $this->payments->feePayer()->value,
            'methods' => OnlinePaymentMethodResource::collection($this->payments->methodSettings()),
        ]);
    }

    /**
     * Switch a method, or set its limits
     *
     * An empty limit is no cap. Limits are per customer, in what reaches the wallet.
     */
    public function updateMethod(UpdateOnlinePaymentMethodRequest $request, OnlinePaymentMethod $method): JsonResponse
    {
        $user = $request->user();

        return $this->success(
            new OnlinePaymentMethodResource($this->payments->updateMethod(
                $method,
                $request->validated(),
                $user instanceof User ? $user : null,
            )),
            'تم حفظ الطريقة',
        );
    }

    /**
     * EzonePay paid out
     *
     * A transfer from «Ezone» to the account the money reached — the bank's default when none is
     * named — and, when EzonePay kept
     * something — an expense under «عمولة الدفع الإلكتروني». Every hand rule holds; undone like any
     * operation. `client_token` makes a retry return the first transfer.
     */
    public function payout(RecordEzonePayoutRequest $request): JsonResponse
    {
        $user = $request->user();
        $kept = $request->validated('kept');
        $at = $request->validated('occurred_at');

        $transfer = $this->payments->recordPayout(
            Money::normalize($request->validated('amount')),
            $kept === null ? null : Money::normalize($kept),
            $request->validated('to_account_id') === null ? null : (int) $request->validated('to_account_id'),
            $at === null ? Carbon::now() : Carbon::parse($at),
            $request->validated('reference'),
            $user instanceof User ? $user : null,
            $request->validated('client_token'),
        );

        $data = [
            'operation_id' => $transfer->id,
            'ezone_balance' => $this->treasury->balanceOf($this->treasury->systemAccount(TreasuryAccount::EZONE)),
        ];

        return $transfer->wasRecentlyCreated
            ? $this->created($data, 'تم تسجيل التحويل')
            : $this->success($data, 'هذا التحويل مسجَّل من قبل');
    }
}
