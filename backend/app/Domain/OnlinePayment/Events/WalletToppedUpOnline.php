<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * A wallet was credited for an online payment. Carries the attempt's id alone — a listener reads
 * what it needs, after the commit.
 */
final class WalletToppedUpOnline
{
    use Dispatchable;

    public function __construct(public readonly int $intentId) {}
}
