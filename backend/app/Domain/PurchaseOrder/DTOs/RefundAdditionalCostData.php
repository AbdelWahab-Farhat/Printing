<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

/**
 * Money coming back on one of a purchase order's costs.
 */
final readonly class RefundAdditionalCostData
{
    public function __construct(
        public string $amount,
        /** Why it came back. Required by the request that builds this. */
        public string $reason,
        /** Stamped from the authenticated user, never read from the payload. */
        public int $recordedBy,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated, int $recordedBy): self
    {
        return new self(
            amount: (string) $validated['amount'],
            reason: trim((string) $validated['reason']),
            recordedBy: $recordedBy,
        );
    }
}
