<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Events;

use Illuminate\Foundation\Events\Dispatchable;

/**
 * The monthly run posted salaries. Announced once per run that wrote at least one, for whoever
 * reads the employee wallets. Each employee also hears about their own line through
 * {@see EmployeeWalletMoved}.
 */
final class SalariesPosted
{
    use Dispatchable;

    public function __construct(
        public readonly string $monthKey,
        public readonly string $monthLabel,
        public readonly int $count,
        public readonly string $total,
        public readonly int $skippedManual,
    ) {}
}
