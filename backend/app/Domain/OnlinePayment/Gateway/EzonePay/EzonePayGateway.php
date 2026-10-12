<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway\EzonePay;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Exceptions\GatewayRejected;
use App\Domain\OnlinePayment\Gateway\GatewayQuote;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Gateway\PaymentRequest;
use App\Domain\OnlinePayment\Gateway\ProviderTransaction;
use App\Domain\OnlinePayment\Gateway\StartedPayment;

/**
 * EzonePay's endpoints, in our words. Docs/payments/CUSTOMER-WALLET.md §٥.
 *
 * **The shapes are EzonePay's own documentation** (`EzonePay_Api_Docs_Public.html` and
 * `EzonePay_OnlinePayment_Integration_v2.html`, 2026-10-11), and Primula's for what it had already
 * run: the PascalCase sign-in, `shopId` as an integer, amounts at two places, the webhook
 * signature. EzonePay is ASP.NET, so a field is read whatever its case — `StatusName` and
 * `statusName` alike.
 *
 * What the documentation does not settle — the `Status` numbers, whether `Amount` is the whole
 * charge — is read so that a doubt is never credited: see {@see transaction()}.
 */
final class EzonePayGateway implements OnlinePaymentGateway
{
    /**
     * A paid transaction as the sandbox really answered it (OnePay, 7252, 2026-10-11):
     * `"status": 3, "statusName": "تم الدفع"` with `paidUtc` set — the name in Arabic, and 3, not
     * the webhook's event value 2. «Paid» is the documentation's word. Never the name or the
     * number alone: always beside a paid date, and any other name beside one waits for a person.
     */
    private const PAID = ['paid', 'تم الدفع'];

    private const PAID_STATUS = 3;

    private const FAILED = ['cancelled', 'canceled', 'failed', 'ملغاة', 'فشل', 'فشلت'];

    /**
     * @param  array<string, mixed>  $config
     */
    public function __construct(
        private readonly EzonePayClient $client,
        private readonly array $config,
    ) {}

    public function key(): string
    {
        return 'ezone';
    }

    public function isEnabled(): bool
    {
        return (bool) ($this->config['enabled'] ?? false) && $this->client->isConfigured();
    }

    public function methods(): array
    {
        $rows = $this->client->get('/LookUp/paymentMethods', 'method');
        $methods = [];

        foreach ($rows as $row) {
            if (! is_array($row) || ! is_numeric($this->read($row, 'id'))) {
                continue;
            }

            $methods[(int) $this->read($row, 'id')] = [
                'min' => $this->bound($this->read($row, 'minPayment')),
                'max' => $this->bound($this->read($row, 'maxPayment')),
            ];
        }

        return $methods;
    }

    /**
     * `/online-payment/commission/quote`. Reversed, EzonePay works out the charge that leaves
     * `$amount` with the merchant — its own rule per method, EdfaLi's lower rate under 100
     * included, so nothing here guesses it.
     */
    public function quote(OnlineMethod $method, string $amount, bool $reverse): GatewayQuote
    {
        $quote = $this->client->post('/online-payment/commission/quote', [
            'paymentMethod' => $method->value,
            'amount' => (float) $amount,
            'isReverseCalculation' => $reverse,
        ], 'method');

        $rate = $this->read($quote, 'totalCommissionPercentage');
        $fee = $this->read($quote, 'totalCommissionAmount');
        $charge = $this->read($quote, 'amountToCharge');

        if (! is_numeric($rate) || ! is_numeric($fee) || ! is_numeric($charge)) {
            throw GatewayRejected::make('تعذّر حساب عمولة هذه الطريقة', 'method');
        }

        // A fraction — 0.025 for 2.5 %. A provider that someday sends 2.5 is read as percent.
        $rate = (float) $rate > 1 ? (float) $rate / 100 : (float) $rate;

        return new GatewayQuote(
            charge: number_format((float) $charge, 3, '.', ''),
            fee: number_format((float) $fee, 3, '.', ''),
            rate: number_format($rate, 6, '.', ''),
        );
    }

    public function start(OnlineMethod $method, PaymentRequest $request): StartedPayment
    {
        return match ($method->flow()) {
            PaymentFlow::Link => $this->link($method, $request),
            PaymentFlow::Qr => $this->scan($method, $request),
            PaymentFlow::Otp => $this->initiate($method, $request),
        };
    }

    public function completeOtp(int $transactionId, OnlineMethod $method, string $otp): void
    {
        $this->client->post('/online-payment/complete', [
            'transactionId' => $transactionId,
            'paymentMethod' => $method->value,
            'otp' => $otp,
        ], 'otp');
    }

    /**
     * `GET /payments/transactions/{id}/online` — `PaymentTransactionDetailsResponse`.
     *
     * - **Paid** only when `PaidUtc` is set, `StatusName` is «تم الدفع» / «Paid» or `Status` is 3,
     *   and nothing cancelled or failed it.
     * - **Failed** when it was cancelled or failed, or its status says so, and it was never paid.
     * - **Unclear** when one says paid and the other does not — kept waiting, never credited.
     *
     * `Comission` is EzonePay's spelling.
     */
    public function transaction(int $transactionId): ProviderTransaction
    {
        $data = $this->client->get("/payments/transactions/{$transactionId}/online");

        $name = mb_strtolower(trim((string) ($this->read($data, 'statusName') ?? '')));
        $paidAt = $this->read($data, 'paidUtc');
        // `failedUtc` is not in the documentation; the sandbox sends it, and it ends a payment too.
        $cancelledAt = $this->read($data, 'cancelledUtc', 'failedUtc');
        $code = $this->read($data, 'status');
        $saysPaid = in_array($name, self::PAID, true) || (is_numeric($code) && (int) $code === self::PAID_STATUS);

        $paid = $saysPaid && $paidAt !== null && $cancelledAt === null;
        $failed = ! $paid && $paidAt === null && ($cancelledAt !== null || in_array($name, self::FAILED, true));
        $unclear = ! $paid && ! $failed && ($saysPaid || $paidAt !== null)
            ? sprintf('أجابت EzonePay بحالة «%s» وتاريخ دفع %s%s',
                $name !== '' ? $name : '—',
                is_string($paidAt) ? $paidAt : 'غير موجود',
                $cancelledAt !== null ? ' وتاريخ إلغاء' : '')
            : null;

        $reference = $this->read($data, 'orderReference');

        return new ProviderTransaction(
            transactionId: $transactionId,
            paid: $paid,
            failed: $failed,
            amount: $this->money($this->read($data, 'amount')),
            fee: $this->money($this->read($data, 'comission', 'commission')),
            orderReference: is_string($reference) ? $reference : null,
            raw: $data,
            unclear: $unclear,
        );
    }

    /**
     * `GET /payment-link/{id}/transactions` — the paid transactions on one link, newest first.
     * One page of fifty: a link we open takes one payment ({@see link()}).
     */
    public function linkPayments(int $linkId): array
    {
        $answer = $this->client->get("/payment-link/{$linkId}/transactions?PageNumber=1&PageSize=50");
        $payments = [];

        foreach ($this->rows($answer) as $row) {
            if (! is_array($row)) {
                continue;
            }

            $payments[] = [
                'transaction_id' => $this->id($this->read($row, 'transactionId', 'id')),
                'amount' => $this->money($this->read($row, 'amount', 'amountPaid')),
            ];
        }

        return $payments;
    }

    /**
     * `X-Signature` = Base64(raw HMAC-SHA256 of the raw body), the `SecretKey` used as-is — exactly
     * as EzonePay signs. Fails closed: no secret, no signature, no match — refused.
     */
    public function verifyWebhook(string $body, ?string $signature): bool
    {
        $secret = (string) ($this->config['webhook_secret'] ?? '');

        if ($secret === '' || $signature === null || $signature === '') {
            return false;
        }

        $expected = base64_encode(hash_hmac('sha256', $body, $secret, true));

        // The expected value is never logged (Primula did).
        return hash_equals($expected, $signature);
    }

    /**
     * `/Webhook/subscribe` — the answer carries the `SecretKey` for `.env`.
     *
     * @return array<string, mixed>
     */
    public function subscribeWebhook(string $url): array
    {
        return $this->client->post('/Webhook/subscribe', ['Url' => $url, 'Event' => 2]);
    }

    public function fireTestWebhook(): void
    {
        $this->client->post('/Webhook/test-event/2', []);
    }

    /**
     * @return array<string, mixed>
     */
    public function subscriptions(): array
    {
        return $this->client->get('/Webhook/subscriptions');
    }

    private function initiate(OnlineMethod $method, PaymentRequest $request): StartedPayment
    {
        $answer = $this->client->post("/online-payment/{$method->slug()}/initiate", $this->body($method, $request));

        return new StartedPayment(transactionId: $this->id($this->read($answer, 'transactionId')), raw: $answer);
    }

    /** One step: the QR carries the amount, and the answer says whether it is paid. */
    private function scan(OnlineMethod $method, PaymentRequest $request): StartedPayment
    {
        $answer = $this->client->post(
            "/online-payment/{$method->slug()}/scan",
            $this->body($method, $request) + ['qrContent' => (string) $request->qrContent],
            'qr_content',
        );

        return new StartedPayment(
            transactionId: $this->id($this->read($answer, 'transactionId')),
            completed: $this->read($answer, 'isComplete') === true,
            raw: $answer,
        );
    }

    /**
     * A hosted page for bank cards. Every other method the merchant has is excluded, so the page
     * offers the cards alone — the app chose the method already.
     *
     * **One payment, and only until the attempt ends**: `maxUsageCount: 1` (which is why EzonePay
     * wants the customer) and `expiresAt`. Without them a second payment on the same link would be
     * charged and never credited.
     */
    private function link(OnlineMethod $method, PaymentRequest $request): StartedPayment
    {
        $others = array_values(array_filter(
            array_keys($this->methods()),
            fn (int $id) => $id !== $method->value,
        ));

        $answer = $this->client->post('/payment-link/new', array_filter([
            'title' => 'شحن المحفظة',
            'shopId' => $this->client->shopId(),
            'amount' => (float) $request->amount,
            'orderReference' => $request->orderReference,
            'internalReference' => $request->internalReference,
            'expiresAt' => $request->expiresAt?->copy()->utc()->format('Y-m-d\TH:i:s\Z'),
            'maxUsageCount' => 1,
            'customer' => $this->customer($request),
            'redirectUrl' => $request->redirectUrl,
            'ExcludedPaymentMethods' => $others,
        ], fn ($value) => $value !== null));

        $url = $this->read($answer, 'link', 'url', 'paymentLink');

        if (! is_string($url) || $url === '') {
            throw GatewayRejected::make('لم يُرجع مزوّد الدفع رابط الدفع');
        }

        return new StartedPayment(
            transactionId: null,
            linkId: $this->id($this->read($answer, 'id', 'paymentLinkId')),
            paymentUrl: $url,
            raw: $answer,
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function body(OnlineMethod $method, PaymentRequest $request): array
    {
        return array_filter([
            'shopId' => $this->client->shopId(),
            // Two places at most — EzonePay refused three on Libyana (2026-09-21, Primula).
            'amount' => (float) $request->amount,
            'orderReference' => $request->orderReference,
            'internalReference' => $request->internalReference,
            'customer' => $this->customer($request),
            'cardNumber' => $method->requiresCardNumber() ? $request->cardNumber : null,
            'serviceMobileNumber' => $method->requiresServiceMobileNumber() ? $request->serviceMobileNumber : null,
            'birthYear' => $method->requiresBirthYear() ? $request->birthYear : null,
        ], fn ($value) => $value !== null);
    }

    /**
     * @return array{firstName: string, lastName: string, phoneNumber: string}
     */
    private function customer(PaymentRequest $request): array
    {
        return [
            'firstName' => $request->firstName,
            'lastName' => $request->lastName,
            'phoneNumber' => $request->phone,
        ];
    }

    /**
     * The first of `$names` present and not null, whatever the case of the key.
     *
     * @param  array<array-key, mixed>  $data
     */
    private function read(array $data, string ...$names): mixed
    {
        $lower = array_change_key_case($data, CASE_LOWER);

        foreach ($names as $name) {
            $value = $lower[strtolower($name)] ?? null;

            if ($value !== null) {
                return $value;
            }
        }

        return null;
    }

    /**
     * The rows of a list answer — the list itself, or under `items` / `data` / `results`.
     *
     * @param  array<array-key, mixed>  $answer
     * @return array<array-key, mixed>
     */
    private function rows(array $answer): array
    {
        if (array_is_list($answer)) {
            return $answer;
        }

        $rows = $this->read($answer, 'items', 'data', 'results');

        return is_array($rows) ? $rows : [];
    }

    private function id(mixed $value): ?int
    {
        return is_numeric($value) ? (int) $value : null;
    }

    private function money(mixed $value): ?string
    {
        return is_numeric($value) ? number_format((float) $value, 2, '.', '') : null;
    }

    /** A limit EzonePay sets on a method — null or zero is none. */
    private function bound(mixed $value): ?string
    {
        return is_numeric($value) && (float) $value > 0 ? number_format((float) $value, 2, '.', '') : null;
    }
}
