<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A pool buys with the money it has, and no more.
 *
 * **Why this is refused rather than allowed to go negative.** A pool's cash is derived — book value
 * less stock at cost — so overspending does not fail anywhere; it simply produces a negative number
 * that no screen expects and every subsequent purchase compares against. The goods would arrive,
 * the layers would carry the pool, and the investors would own a lorry they did not pay for while
 * the company quietly carried the difference with nothing recording that it had.
 *
 * The honest remedies are both the owner's to choose: put more capital in, or let the company buy
 * this line — which is the yes/no the purchase screen already asks.
 */
final class PoolCannotAffordThePurchase extends DomainException
{
    public static function make(string $pool, string $cost, string $available): self
    {
        return new self(
            "الصندوق «{$pool}» لا يملك ما يكفي: التكلفة {$cost} والمتاح {$available}"
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['stock_item_ids' => [$this->getMessage()]];
    }
}
