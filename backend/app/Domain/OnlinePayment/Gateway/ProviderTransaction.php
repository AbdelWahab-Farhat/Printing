<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Gateway;

/**
 * What the provider says about one transaction — asked of it directly, never read off a webhook.
 */
final readonly class ProviderTransaction
{
    /**
     * @param  array<string, mixed>  $raw
     */
    public function __construct(
        public int $transactionId,
        public bool $paid,
        public bool $failed,
        /** What was charged, when the provider says. Null: it did not. */
        public ?string $amount,
        /** What the provider kept, when it says. */
        public ?string $fee,
        public ?string $orderReference = null,
        public array $raw = [],
        /**
         * The answer half-says «paid» — a paid date without a paid status, or the reverse. Never
         * credited: it waits, and a person looks once the attempt's time is up.
         */
        public ?string $unclear = null,
    ) {}

    /**
     * Whether the charge is what we asked for — or the provider did not say, which is not a no.
     *
     * The provider may report the whole charge or what reached the merchant after its fee; either
     * way the customer paid `$expected`, so both match. Anything else does not.
     */
    public function amountMatches(string $expected): bool
    {
        if ($this->amount === null || bccomp($this->amount, $expected, 2) === 0) {
            return true;
        }

        return $this->fee !== null && bccomp(bcadd($this->amount, $this->fee, 2), $expected, 2) === 0;
    }
}
