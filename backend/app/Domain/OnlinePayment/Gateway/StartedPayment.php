<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway;

/**
 * What the provider answered when a payment was started.
 */
final readonly class StartedPayment
{
    /**
     * @param  array<string, mixed>  $raw
     */
    public function __construct(
        /** OTP and QR: known at once. A card link: known when the webhook arrives. */
        public ?int $transactionId,
        /** A QR payment finishes in the same request. */
        public bool $completed = false,
        public ?int $linkId = null,
        public ?string $paymentUrl = null,
        public array $raw = [],
    ) {}
}
