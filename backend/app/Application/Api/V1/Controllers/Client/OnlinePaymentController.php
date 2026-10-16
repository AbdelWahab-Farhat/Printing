<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Requests\Client\Payment\ConfirmTopUpOtpRequest;
use App\Application\Api\V1\Requests\Client\Payment\QuoteOnlineTopUpRequest;
use App\Application\Api\V1\Requests\Client\Payment\StartOnlineTopUpRequest;
use App\Application\Api\V1\Resources\Client\ClientPaymentIntentResource;
use App\Application\Controller;
use App\Domain\Customer\Models\Customer;
use App\Domain\OnlinePayment\DTOs\OnlineTopUpData;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\OnlinePaymentService;
use App\Domain\OnlinePayment\Support\Money;
use App\Domain\Wallet\WalletService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Online top-up
 *
 * «اشحن محفظتك» through EzonePay — Docs/payments/CUSTOMER-WALLET.md §٥. Always the signed-in
 * customer's own: an attempt is found by its public id *and* the customer, so another customer's
 * is a 404.
 *
 * While online payments are off, `methods` answers `enabled: false` with no methods, and the rest
 * answer 503.
 */
class OnlinePaymentController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly OnlinePaymentService $payments,
        private readonly WalletService $wallet,
    ) {}

    /**
     * The methods I can top up with
     *
     * Each with its fee and what is left of its limits; the most-used first. `fee_payer`:
     * `customer` — the fee is added to what is charged — or `shop`.
     */
    public function methods(Request $request): JsonResponse
    {
        $customer = $this->customer($request);

        return $this->success([
            'enabled' => $this->payments->isEnabled(),
            'fee_payer' => $this->payments->feePayer()->value,
            'methods' => array_map(fn (array $row) => [
                'id' => $row['method']->value,
                'label' => $row['method']->label(),
                'flow' => $row['method']->flow()->value,
                'needs_card_number' => $row['method']->requiresCardNumber(),
                // Libyana's is the customer's own phone, filled in when left out.
                'needs_service_mobile_number' => $row['method']->requiresServiceMobileNumber() && $row['method'] !== OnlineMethod::Libyana,
                'needs_birth_year' => $row['method']->requiresBirthYear(),
                // «2.5» for 0.025 — a label, never arithmetic: the charge is the server's quote.
                'fee_percentage' => (string) (float) bcmul($row['rate'], '100', 4),
                'max_amount' => $row['max_net'],
                'limits' => $row['limits'],
            ], $this->payments->methodsFor($customer)),
        ]);
    }

    /**
     * What a top-up would cost
     */
    public function quote(QuoteOnlineTopUpRequest $request): JsonResponse
    {
        $quote = $this->payments->quote(
            OnlineMethod::from((int) $request->validated('method')),
            Money::normalize($request->validated('amount')),
        );

        return $this->success([
            'amount' => $quote['net'],
            'total' => $quote['gross'],
            'fee' => $quote['fee'],
            'fee_payer' => $quote['fee_payer']->value,
        ]);
    }

    /**
     * Start a top-up
     *
     * OTP methods answer `requires_otp: true` — the provider texts the code; QR answers already
     * paid or failed; a bank card answers a `payment_url` to open, then poll `show`. `client_token`
     * makes a retry return the first attempt.
     */
    public function start(StartOnlineTopUpRequest $request): JsonResponse
    {
        $customer = $this->customer($request);
        $intent = $this->payments->start($customer, OnlineTopUpData::fromArray($request->validated()));

        return $this->created($this->answer($intent, $customer), 'بدأت عملية الشحن');
    }

    /**
     * Send the OTP
     *
     * A wrong code leaves the attempt waiting with one try fewer, and answers EzonePay's own words.
     */
    public function confirm(ConfirmTopUpOtpRequest $request, string $intent): JsonResponse
    {
        $customer = $this->customer($request);
        $found = $this->payments->findForCustomer($customer, $intent);
        $confirmed = $this->payments->confirmOtp($found, (string) $request->validated('otp'));

        return $this->success($this->answer($confirmed, $customer), 'تم التحقق');
    }

    /**
     * Where my top-up stands
     *
     * Polled every few seconds by the card page and by «نتحقق من الدفع» (throttled). A read —
     * except while EzonePay has taken the code and not yet said the payment is paid
     * (`is_confirming`): then EzonePay is asked, at most every ten seconds. Works while online
     * payments are off, so an attempt started before keeps reporting.
     */
    public function show(Request $request, string $intent): JsonResponse
    {
        $customer = $this->customer($request);
        $found = $this->payments->watch($this->payments->findForCustomer($customer, $intent));

        return $this->success($this->answer($found, $customer));
    }

    /**
     * @return array<string, mixed>
     */
    private function answer(PaymentIntent $intent, Customer $customer): array
    {
        return [
            'intent' => new ClientPaymentIntentResource($intent->refresh()),
            'balance' => $this->wallet->balanceOf((int) $customer->getKey()),
        ];
    }

    private function customer(Request $request): Customer
    {
        $customer = $request->user();

        assert($customer instanceof Customer);

        return $customer;
    }
}
