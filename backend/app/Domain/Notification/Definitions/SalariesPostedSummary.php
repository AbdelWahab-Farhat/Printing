<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * The monthly run posted salaries — one summary for whoever reads the employee wallets.
 * EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * Opens «المعاملات المالية» on the employees tab, where the new lines are.
 */
final readonly class SalariesPostedSummary implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::permission(PermissionName::ViewEmployeeWallets);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $month = (string) ($payload['month_label'] ?? '');
        $count = (int) ($payload['count'] ?? 0);
        $skipped = (int) ($payload['skipped_manual'] ?? 0);
        $total = preg_replace('/\.00$/', '', number_format((float) ($payload['total'] ?? 0), 2));

        $body = "{$count} موظف · المجموع {$total} د.ل";

        if ($skipped > 0) {
            $body .= " · لم يُضَف لـ{$skipped} سُجّل راتبهم يدوياً";
        }

        return new RenderedNotification(
            title: "أُضيفت رواتب {$month} إلى المحافظ",
            body: $body,
            route: '/wallet-transactions?tab=employees',
        );
    }

    /** Nobody caused it: the system wrote it. */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
