<?php

declare(strict_types=1);

namespace App\Domain\Investor\DTOs;

/**
 * What it takes to open or rename a pool.
 *
 * **No capital and no percentages.** A pool is born empty: money arrives through
 * `investment_capital_requests` and the ordinary ledger, and ownership is recomputed from that
 * capital at every close. The old `FundPurchaseOrder` took the shelves, the funders and the
 * amounts in one breath because a deal *was* one lorry; a pool outlives every lorry it buys.
 *
 * `investorProfitSharePercent` is null on the ordinary path and seeded from the company default.
 * It is on the pool rather than read live at each close for the same reason it sat on a deal: the
 * men putting money in were shown a number, and editing the company default next year must not
 * quietly re-cut a pool they are already in.
 */
final readonly class PoolData
{
    /**
     * @param  list<int>  $stockItemIds  the shelves this pool owns — each may belong to no other
     */
    public function __construct(
        public string $name,
        public array $stockItemIds,
        public ?string $investorProfitSharePercent = null,
        public ?string $notes = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data  already validated
     */
    public static function fromArray(array $data): self
    {
        return new self(
            name: (string) $data['name'],
            stockItemIds: array_values(array_unique(array_map(
                'intval',
                $data['stock_item_ids'] ?? [],
            ))),
            investorProfitSharePercent: isset($data['investor_profit_share_percent'])
                ? number_format((float) $data['investor_profit_share_percent'], 2, '.', '')
                : null,
            notes: $data['notes'] ?? null,
        );
    }
}
