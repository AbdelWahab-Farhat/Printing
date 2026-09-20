<?php

declare(strict_types=1);

namespace App\Domain\Investor\DTOs;

/**
 * «these lines of this purchase order are bought with pool money» — and at what price the press
 * will buy the plain stock, per line.
 *
 * **No pool is named, anywhere in here.** The material decides which pool pays, through
 * `investment_pool_items`, so a payload that could name one could route an investor's money to a
 * heading he never agreed to. The only decision this carries is the yes/no: pool money, or the
 * company's.
 */
final readonly class PoolPurchaseData
{
    /**
     * @param  list<PoolPurchaseLineData>  $lines
     */
    public function __construct(public array $lines) {}

    /**
     * @param  array<string, mixed>  $data  already validated
     */
    public static function fromArray(array $data): self
    {
        return new self(array_map(
            static fn (array $line): PoolPurchaseLineData => new PoolPurchaseLineData(
                stockItemId: (int) $line['stock_item_id'],
                printingSalePrice: isset($line['printing_sale_price'])
                    ? number_format((float) $line['printing_sale_price'], 3, '.', '')
                    : null,
            ),
            array_values($data['lines'] ?? []),
        ));
    }
}
