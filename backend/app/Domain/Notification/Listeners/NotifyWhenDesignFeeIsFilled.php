<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Domain\Order\Events\OrderDesignFeeFilled;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * Tells whoever may see «أجرة التصميم» that an approved ticket filled it from «أجرة المصمم».
 *
 * Queued and after commit, like {@see NotifyWhenOrderEntersShortage}: an alert about an approval
 * that rolled back could not be taken back.
 */
final class NotifyWhenDesignFeeIsFilled implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(OrderDesignFeeFilled $event): void
    {
        $order = Order::query()->find($event->orderId);

        if ($order === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::OrderDesignFeeFilled,
            subject: $order,
            payload: [
                'order_id' => (int) $order->getKey(),
                'order_code' => (string) $order->code,
                'amount' => $event->amount,
            ],
            causerId: $event->actorId,
        ));
    }
}
