<?php

declare(strict_types=1);

namespace App\Domain\Investor\DTOs;

use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Support\GraceWindow;

/**
 * Somebody's capital, offered to a pool or asked back from it.
 *
 * No period and no effective date: **both are derived**, by {@see GraceWindow}
 * from the pool's current period and the company's grace setting. A client that could name the
 * period it joins could put a man into a period he was never in.
 */
final readonly class CapitalRequestData
{
    public function __construct(
        public int $investorId,
        public CapitalRequestDirection $direction,
        public string $amount,
        public ?string $notes = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data  already validated
     */
    public static function fromArray(array $data): self
    {
        return new self(
            investorId: (int) $data['investor_id'],
            direction: CapitalRequestDirection::from((string) $data['direction']),
            amount: number_format((float) $data['amount'], 2, '.', ''),
            notes: $data['notes'] ?? null,
        );
    }
}
