<?php

declare(strict_types=1);

namespace App\Domain\Order\Events;

use App\Domain\Order\Actions\ReverseOrderStockDeduction;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * A cancelled order has given its material back to the shelf.
 *
 * Dispatched after {@see ReverseOrderStockDeduction} has run, so every
 * credit-back is already on the ledger and whoever listens can read what actually came back rather
 * than what was expected to.
 *
 * **Why anyone cares.** The goods are credited back **as good stock**, and paper that has been
 * through a press is not good stock. Nothing in Inventory can tell the difference — a movement
 * records a quantity, not whether there is ink on it — so a listener raises the question for a
 * person to answer, and the pool's period will not close until they do.
 *
 * Only a **printed** line whose material was **unpriced** raises one. A سادة line was never
 * printed; a وسيط line never touched a shelf of ours; and a priced draw was paid for the day it
 * left, so its cancellation hands those goods to the company rather than back to the pool. A prompt
 * with one possible answer is noise, and noise is what teaches people to click through prompts.
 *
 * **An event rather than a call**, for the reason {@see OrderProfitFinalised} sets out: Orders may
 * not depend on Investment, and a direct call would close a loop the container cannot build. It
 * fires on every cancellation, including the many where nothing of anybody's was involved.
 */
final readonly class OrderStockReturned
{
    use Dispatchable;

    public function __construct(public int $orderId) {}
}
