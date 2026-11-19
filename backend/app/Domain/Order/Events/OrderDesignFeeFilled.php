<?php

declare(strict_types=1);

namespace App\Domain\Order\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * «أجرة التصميم» was filled from «أجرة المصمم» because nobody had set it. Whoever may see the fee
 * is told, so they can set the price they actually want. See ORDER-DESIGN-FEE.md.
 */
final readonly class OrderDesignFeeFilled
{
    use Dispatchable;

    public function __construct(
        public int $orderId,
        public string $amount,
        public ?int $actorId = null,
    ) {}
}
