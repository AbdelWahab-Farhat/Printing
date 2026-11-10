<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\EmployeeWallet\Events\SalariesPosted;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * Tells whoever reads the employee wallets that the monthly run posted salaries.
 *
 * Queued and after commit, like its neighbours. No dedupe key: a catch-up run that posts more
 * lines later in the month is news of its own.
 */
final class NotifyWhenSalariesPosted implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(SalariesPosted $event): void
    {
        $this->notifications->publish(new PendingNotification(
            type: NotificationType::SalariesPosted,
            payload: [
                'month' => $event->monthKey,
                'month_label' => $event->monthLabel,
                'count' => $event->count,
                'total' => $event->total,
                'skipped_manual' => $event->skippedManual,
            ],
        ));
    }
}
