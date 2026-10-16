<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway\Fake;

use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Exceptions\GatewayRejected;
use App\Domain\OnlinePayment\Gateway\GatewayQuote;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Gateway\PaymentRequest;
use App\Domain\OnlinePayment\Gateway\ProviderTransaction;
use App\Domain\OnlinePayment\Gateway\StartedPayment;
use App\Domain\OnlinePayment\Support\FeeCalculator;
use App\Domain\OnlinePayment\Support\Money;
use Illuminate\Support\Facades\Cache;

/**
 * A pretend EzonePay, for trying the top-up on an emulator before the sandbox credentials exist —
 * `EZONE_PAY_DRIVER=fake`. CUSTOMER-WALLET §٥.
 *
 * **Only EzonePay is pretended.** Everything on our side runs for real: the intent, the limits,
 * `SettleTopUp`, the wallet credit, «Ezone», the fee expense, «اشحن وادفع», the notification.
 *
 * - Every method, at 2.5 %, with no cap.
 * - OTP: no SMS. Any code pays, **except `0000`**, which is refused as a wrong code.
 * - QR: paid in the same request.
 * - Card link: the link is a test page on this server ({@see payLink()}); «ادفع» there takes the
 *   path a real EzonePay webhook takes.
 *
 * **Never bound in production** — `AppServiceProvider` binds the real gateway there whatever the
 * driver says, and the test page's routes are not registered.
 *
 * Transactions live in the cache, so they survive between requests and vanish with it.
 */
final class FakeEzonePayGateway implements OnlinePaymentGateway
{
    public const RATE = '0.025';

    public const WRONG_OTP = '0000';

    private const PREFIX = 'fake-ezone:';

    /**
     * @param  array<string, mixed>  $config  `config('ezone_pay')`
     */
    public function __construct(private readonly array $config) {}

    public function key(): string
    {
        return 'ezone';
    }

    public function isEnabled(): bool
    {
        return (bool) ($this->config['enabled'] ?? false);
    }

    public function methods(): array
    {
        $all = [];

        foreach (OnlineMethod::cases() as $method) {
            $all[$method->value] = ['min' => null, 'max' => null];
        }

        return $all;
    }

    /** EzonePay's arithmetic as the shop expects it: reversed, the charge that leaves `$amount`. */
    public function quote(OnlineMethod $method, string $amount, bool $reverse): GatewayQuote
    {
        $fees = new FeeCalculator;
        $charge = $reverse ? $fees->charge($amount, self::RATE, FeePayer::Customer)['gross'] : Money::round($amount);

        return new GatewayQuote(charge: $charge, fee: $fees->expectedFee($charge, self::RATE), rate: self::RATE);
    }

    public function start(OnlineMethod $method, PaymentRequest $request): StartedPayment
    {
        if ($method->flow() === PaymentFlow::Link) {
            $linkId = $this->nextId();

            Cache::put(self::PREFIX."link:{$linkId}", [
                'amount' => $request->amount,
                'reference' => $request->orderReference,
                'method' => $method->value,
            ], now()->addDay());

            return new StartedPayment(
                transactionId: null,
                linkId: $linkId,
                paymentUrl: url("/api/v1/fake-ezone/pay/{$linkId}"),
                raw: ['fake' => true],
            );
        }

        $transactionId = $this->nextId();
        $paid = $method->flow() === PaymentFlow::Qr;

        $this->keep($transactionId, $method, $request->amount, $request->orderReference, $paid ? 'paid' : 'pending');

        return new StartedPayment(transactionId: $transactionId, completed: $paid, raw: ['fake' => true]);
    }

    public function completeOtp(int $transactionId, OnlineMethod $method, string $otp): void
    {
        if ($otp === self::WRONG_OTP) {
            throw GatewayRejected::make('رمز التحقق غير صحيح (تجريبي: 0000 خاطئ دائماً)', 'otp');
        }

        $this->mark($transactionId, 'paid');
    }

    public function transaction(int $transactionId): ProviderTransaction
    {
        /** @var array{amount: string, reference: string, status: string, method: int}|null $tx */
        $tx = Cache::get(self::PREFIX."tx:{$transactionId}");

        return new ProviderTransaction(
            transactionId: $transactionId,
            paid: ($tx['status'] ?? null) === 'paid',
            failed: false,
            amount: $tx['amount'] ?? null,
            // What EzonePay keeps, by its own rule — 2.5 % of the whole charge, as the sandbox
            // answered: 2.56 of a 102.57 charge, and «Ezone» holding 100.01.
            fee: $tx === null ? null : (new FeeCalculator)->expectedFee($tx['amount'], self::RATE),
            orderReference: $tx['reference'] ?? null,
            raw: ['fake' => true] + ($tx ?? []),
        );
    }

    public function linkPayments(int $linkId): array
    {
        /** @var array{amount: string, transaction_id?: int}|null $link */
        $link = Cache::get(self::PREFIX."link:{$linkId}");

        return isset($link['transaction_id'])
            ? [['transaction_id' => $link['transaction_id'], 'amount' => Money::round($link['amount'])]]
            : [];
    }

    /** Nothing reaches the webhook from outside while pretending — the test page goes inside. */
    public function verifyWebhook(string $body, ?string $signature): bool
    {
        return false;
    }

    /**
     * The test page's «ادفع»: the link becomes a paid transaction. Returns the body a real
     * EzonePay webhook would carry, or null for a link this cache does not know.
     *
     * @return array{event: int, transactionId: int, orderReference: string}|null
     */
    public function payLink(int $linkId): ?array
    {
        /** @var array{amount: string, reference: string, method: int, transaction_id?: int}|null $link */
        $link = Cache::get(self::PREFIX."link:{$linkId}");

        if ($link === null) {
            return null;
        }

        // Pressed twice: the same transaction, so the second webhook is the first one again.
        $transactionId = $link['transaction_id'] ?? $this->nextId();

        $this->keep($transactionId, OnlineMethod::from($link['method']), $link['amount'], $link['reference'], 'paid');
        Cache::put(self::PREFIX."link:{$linkId}", $link + ['transaction_id' => $transactionId], now()->addDay());

        return ['event' => 2, 'transactionId' => $transactionId, 'orderReference' => $link['reference']];
    }

    /** @return array{amount: string, reference: string}|null */
    public function link(int $linkId): ?array
    {
        return Cache::get(self::PREFIX."link:{$linkId}");
    }

    private function keep(int $transactionId, OnlineMethod $method, string $amount, string $reference, string $status): void
    {
        Cache::put(self::PREFIX."tx:{$transactionId}", [
            'method' => $method->value,
            'amount' => Money::round($amount),
            'reference' => $reference,
            'status' => $status,
        ], now()->addDay());
    }

    private function mark(int $transactionId, string $status): void
    {
        $tx = Cache::get(self::PREFIX."tx:{$transactionId}");

        if (is_array($tx)) {
            Cache::put(self::PREFIX."tx:{$transactionId}", ['status' => $status] + $tx, now()->addDay());
        }
    }

    /** Far above anything the sandbox would hand out, so the two never meet in one table. */
    private function nextId(): int
    {
        Cache::add(self::PREFIX.'next', 900000, now()->addYear());

        return (int) Cache::increment(self::PREFIX.'next');
    }
}
