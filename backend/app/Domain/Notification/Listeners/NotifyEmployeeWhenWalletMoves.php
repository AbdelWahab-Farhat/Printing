<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\EmployeeWallet\Events\EmployeeWalletMoved;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يخبر الموظف أن محفظته تحرّكت.
 *
 * **في الطابور وبعد الالتزام**، للسبب الذي يعطيه جيرانها: إشعارٌ عن معاملةٍ تراجعت لا يُستردّ. وبلا
 * مفتاح تكرار: حركتان متتاليتان خبران لا خبرٌ واحد.
 */
final class NotifyEmployeeWhenWalletMoves implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(EmployeeWalletMoved $event): void
    {
        $this->notifications->publish(new PendingNotification(
            type: NotificationType::EmployeeWalletMoved,
            payload: [
                'employee_id' => $event->employeeId,
                'entry_id' => $event->entryId,
                'type' => $event->type,
                'is_credit' => $event->isCredit,
            ],
            subjectType: AuditSubject::EmployeeWalletEntry->value,
            subjectId: $event->entryId,
            causerId: $event->actorId,
        ));
    }
}
