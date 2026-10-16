<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway;

use App\Domain\OnlinePayment\Enums\OnlineMethod;

/**
 * A payment provider, as the rest of the context sees it — HTTP and nothing else.
 *
 * The state machine, the limits and the wallet credit live in the actions; a second provider is
 * one more class behind this interface. Every method throws a domain exception on failure
 * (RULES §5) — none returns a flag a caller must read.
 */
interface OnlinePaymentGateway
{
    public function key(): string;

    /** The master switch and the credentials both. */
    public function isEnabled(): bool;

    /**
     * What the merchant account offers: id => the least and the most one payment may charge
     * (null: no bound).
     *
     * @return array<int, array{min: ?string, max: ?string}>
     */
    public function methods(): array;

    /**
     * The provider's own price for `$amount`. `$reverse`: `$amount` is what must reach the
     * merchant, and the charge is worked out from it; otherwise `$amount` is the charge itself.
     */
    public function quote(OnlineMethod $method, string $amount, bool $reverse): GatewayQuote;

    public function start(OnlineMethod $method, PaymentRequest $request): StartedPayment;

    public function completeOtp(int $transactionId, OnlineMethod $method, string $otp): void;

    public function transaction(int $transactionId): ProviderTransaction;

    /**
     * What was paid through a payment link, as the provider lists it — how a card payment whose
     * webhook was lost is still found.
     *
     * @return list<array{transaction_id: ?int, amount: ?string}>
     */
    public function linkPayments(int $linkId): array;

    /** Whether the raw body carries the provider's signature. Fails closed without a secret. */
    public function verifyWebhook(string $body, ?string $signature): bool;
}
