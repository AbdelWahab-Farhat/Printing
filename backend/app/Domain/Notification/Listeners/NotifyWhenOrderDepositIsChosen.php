<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\Definitions\CustomerChoseDeposit;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Domain\Order\Events\OrderDepositChosen;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر من يقبل الطلبيات أنّ العميل اختار عربونَه — انظر {@see CustomerChoseDeposit}.
 *
 * **مُدرَجٌ في الطابور، وبعد الإيداع**، كجيرانه: جرسٌ فاشل لا يُسقط اختيارَ عميل، وخبرٌ عن معاملةٍ
 * تراجعت لا يُسحب من هاتفٍ وصل إليه. ومفتاحُ منعِ التكرار الطلبيةُ: يُختار عربونُها مرّةً واحدة.
 */
final class NotifyWhenOrderDepositIsChosen implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(OrderDepositChosen $event): void
    {
        $order = Order::query()->with('customer')->find($event->orderId);

        if ($order === null || $order->deposit_expected_amount === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::OrderDepositChosen,
            subject: $order,
            // مجمّدةٌ الآن، فتبقى الجملةُ صحيحةً بعد أن تتحرّك الطلبية.
            payload: [
                'order_id' => (int) $order->getKey(),
                'order_code' => (string) $order->code,
                'customer_name' => (string) ($order->customer?->name ?? ''),
                'status' => $order->status->value,
                'deposit_amount' => (string) $order->deposit_expected_amount,
            ],
            dedupeKey: 'order.deposit_chosen:'.$order->getKey(),
        ));
    }
}
