<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway;

/**
 * What the provider quoted for one amount — its own arithmetic, never ours. CUSTOMER-WALLET §٥.
 */
final readonly class GatewayQuote
{
    public function __construct(
        /** What the customer is charged, as the provider worked it out (it may carry three places). */
        public string $charge,
        /** What the provider keeps of that charge. */
        public string $fee,
        /** The rate, as a fraction — 0.025 for 2.5 %. */
        public string $rate,
    ) {}
}
