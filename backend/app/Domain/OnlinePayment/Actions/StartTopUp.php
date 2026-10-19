<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\OnlinePayment\DTOs\OnlineTopUpData;
use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Exceptions\GatewayUnavailable;
use App\Domain\OnlinePayment\Exceptions\OnlinePaymentRefused;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Gateway\PaymentRequest;
use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\Queries\MethodRates;
use App\Domain\OnlinePayment\Queries\TopUpCharge;
use App\Domain\OnlinePayment\Queries\TopUpLimits;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * A customer starts topping up their wallet online. CUSTOMER-WALLET §٥.
 *
 * 1. **The same request again is the first attempt** (`client_token`), and a card link of the
 *    same amount from the last hour is reused rather than a second one opened.
 * 2. The method is offered and every field it needs is present.
 * 3. **EzonePay quotes the real amount** ({@see TopUpCharge}, the same quote the screen showed),
 *    within the method's least and most, and the rate is stored on the attempt.
 * 4. **Under the customer's lock**: the limits (pending attempts counted), then the attempt is
 *    written with a reference the server made — committed before the provider is called, so a
 *    payment the provider makes is never without its row.
 * 5. The provider is asked to start. **No database lock is held across that call.** An OTP or a
 *    card link waits; a QR scan may be paid in the same answer and is credited at once.
 */
final class StartTopUp
{
    public function __construct(
        private readonly OnlinePaymentGateway $gateway,
        private readonly MethodRates $rates,
        private readonly TopUpCharge $charge,
        private readonly TopUpLimits $limits,
        private readonly TreasuryService $treasury,
        private readonly SettleTopUp $settle,
    ) {}

    public function __invoke(Customer $customer, OnlineTopUpData $data): PaymentIntent
    {
        if (! $this->gateway->isEnabled()) {
            throw GatewayUnavailable::notConfigured();
        }

        if (($sent = $this->alreadySent($customer, $data->clientToken)) !== null) {
            return $sent;
        }

        $this->guardMethod($data->method);
        $fields = $this->fields($customer, $data);
        $this->guardOrder($customer, $data->orderId);

        if ($data->method->flow() === PaymentFlow::Link && ($open = $this->openLink($customer, $data)) !== null) {
            return $open;
        }

        $payer = FeePayer::from((string) ($this->treasury->settings()->online_fee_payer ?? 'customer'));
        $charge = $this->charge->of($data->method, $data->net, $payer);

        $intent = DB::transaction(function () use ($customer, $data, $payer, $charge): PaymentIntent {
            Customer::query()->whereKey($customer->getKey())->lockForUpdate()->firstOrFail();

            if (($sent = $this->alreadySent($customer, $data->clientToken)) !== null) {
                return $sent;
            }

            $this->limits->guard((int) $customer->getKey(), $data->method, $data->net);

            $intent = new PaymentIntent;
            $intent->forceFill([
                'uuid' => (string) Str::uuid(),
                'gateway' => $this->gateway->key(),
                'customer_id' => $customer->getKey(),
                'order_id' => $data->orderId,
                'order_amount' => $data->orderAmount,
                'method' => $data->method,
                'flow' => $data->method->flow(),
                'net_amount' => $data->net,
                'fee_rate' => $charge['rate'],
                'fee_payer' => $payer,
                'gross_amount' => $charge['gross'],
                'status' => IntentStatus::Created,
                'our_reference' => 'TOPUP-'.Str::upper((string) Str::ulid()),
                'customer_info' => $this->customerInfo($customer),
                'client_token' => $data->clientToken,
                'expires_at' => now()->addMinutes($data->method->flow() === PaymentFlow::Link
                    ? (int) config('ezone_pay.link_ttl_minutes', 60)
                    : (int) config('ezone_pay.intent_ttl_minutes', 30)),
            ])->save();

            return $intent;
        });

        if ($intent->status !== IntentStatus::Created || $intent->provider_transaction_id !== null || $intent->payment_url !== null) {
            return $intent;
        }

        return $this->start($intent, $customer, $fields);
    }

    /**
     * @param  array{card_number: ?string, service_mobile_number: ?string, birth_year: ?string, qr_content: ?string}  $fields
     */
    private function start(PaymentIntent $intent, Customer $customer, array $fields): PaymentIntent
    {
        /** @var array{first_name: string, last_name: string, phone: string} $info */
        $info = $intent->customer_info;

        $started = $this->gateway->start($intent->method, new PaymentRequest(
            amount: (string) $intent->gross_amount,
            orderReference: (string) $intent->our_reference,
            internalReference: (string) $intent->uuid,
            firstName: $info['first_name'],
            lastName: $info['last_name'],
            phone: $info['phone'],
            cardNumber: $fields['card_number'],
            serviceMobileNumber: $fields['service_mobile_number'],
            birthYear: $fields['birth_year'],
            qrContent: $fields['qr_content'],
            redirectUrl: config('ezone_pay.redirect_url'),
            expiresAt: $intent->expires_at,
        ));

        $intent->forceFill([
            'status' => IntentStatus::Pending,
            'provider_transaction_id' => $started->transactionId,
            'provider_link_id' => $started->linkId,
            'payment_url' => $started->paymentUrl,
            'provider_response' => $started->raw,
        ])->save();

        // A QR payment is finished in the same answer — confirmed with the provider, then credited.
        if ($started->completed && $started->transactionId !== null) {
            return ($this->settle)($intent, $this->gateway->transaction($started->transactionId));
        }

        return $intent;
    }

    private function alreadySent(Customer $customer, ?string $clientToken): ?PaymentIntent
    {
        return $clientToken === null ? null : PaymentIntent::query()
            ->where('customer_id', $customer->getKey())
            ->where('client_token', $clientToken)
            ->first();
    }

    private function guardMethod(OnlineMethod $method): void
    {
        $setting = OnlinePaymentMethod::query()->where('method', $method->value)->first();
        $offered = $this->rates->merchantMethods();

        if ($setting === null || ! $setting->is_active || ($offered !== [] && ! array_key_exists($method->value, $offered))) {
            throw OnlinePaymentRefused::methodUnavailable($method->label());
        }
    }

    /**
     * What the method needs from the customer. Libyana's number is the customer's own phone when
     * none was typed.
     *
     * @return array{card_number: ?string, service_mobile_number: ?string, birth_year: ?string, qr_content: ?string}
     */
    private function fields(Customer $customer, OnlineTopUpData $data): array
    {
        $method = $data->method;
        $mobile = $data->serviceMobileNumber ?? ($method === OnlineMethod::Libyana ? (string) $customer->phone : null);

        if ($method->requiresCardNumber() && $data->cardNumber === null) {
            throw OnlinePaymentRefused::fieldRequired('card_number', 'رقم البطاقة أو المحفظة');
        }

        if ($method->requiresServiceMobileNumber() && $mobile === null) {
            throw OnlinePaymentRefused::fieldRequired('service_mobile_number', 'رقم الهاتف');
        }

        if ($method->requiresBirthYear() && $data->birthYear === null) {
            throw OnlinePaymentRefused::fieldRequired('birth_year', 'سنة الميلاد');
        }

        if ($method->flow() === PaymentFlow::Qr && $data->qrContent === null) {
            throw OnlinePaymentRefused::fieldRequired('qr_content', 'رمز QR');
        }

        return [
            'card_number' => $data->cardNumber,
            'service_mobile_number' => $mobile,
            'birth_year' => $data->birthYear,
            'qr_content' => $data->qrContent,
        ];
    }

    private function guardOrder(Customer $customer, ?int $orderId): void
    {
        if ($orderId !== null && ! Order::query()->whereKey($orderId)->where('customer_id', $customer->getKey())->exists()) {
            throw OnlinePaymentRefused::notAnOrderOfYours();
        }
    }

    /** A card link for the same amount and order, still open — the customer reopens it. */
    private function openLink(Customer $customer, OnlineTopUpData $data): ?PaymentIntent
    {
        return PaymentIntent::query()
            ->where('customer_id', $customer->getKey())
            ->where('method', $data->method->value)
            ->where('status', IntentStatus::Pending->value)
            ->where('net_amount', $data->net)
            ->where(fn ($q) => $data->orderId === null ? $q->whereNull('order_id') : $q->where('order_id', $data->orderId))
            ->whereNotNull('payment_url')
            ->where('expires_at', '>', now())
            ->latest('id')
            ->first();
    }

    /**
     * The customer as the provider wants them: a first and last name out of one name, and the
     * phone. Kept on the attempt, so what was sent is on record.
     *
     * @return array{first_name: string, last_name: string, phone: string}
     */
    private function customerInfo(Customer $customer): array
    {
        $parts = preg_split('/\s+/u', trim((string) $customer->name)) ?: [];
        $first = array_shift($parts) ?? 'عميل';

        return [
            'first_name' => $first,
            'last_name' => $parts === [] ? $first : implode(' ', $parts),
            'phone' => $this->localPhone((string) $customer->phone),
        ];
    }

    /**
     * `09XXXXXXXX`, the form EzonePay's own examples use — a card link for one payment needs the
     * customer, and a phone saved as `+218 91-…` must not be what refuses it. A number that is
     * not Libyan is sent as it was typed, digits only.
     */
    private function localPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        if (preg_match('/^(?:00)?218(9\d{8})$/', $digits, $match) === 1) {
            return '0'.$match[1];
        }

        if (preg_match('/^9\d{8}$/', $digits) === 1) {
            return '0'.$digits;
        }

        return $digits !== '' ? $digits : $phone;
    }
}
