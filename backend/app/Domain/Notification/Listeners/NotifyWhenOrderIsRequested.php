<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\Definitions\OrderAwaitsReview;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderRequested;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر المراجِعين أنّ طلبيةً وصلت من التطبيق.
 *
 * **مُدرَجٌ في الطابور، وبعد الإيداع**، كجيرانه في هذا المجلّد: دفعٌ فاشل لا يجوز أن يُسقط طلبيةً
 * كتبها عميل، وإعلانٌ عن طلبيةٍ تراجعت معاملتُها لا يمكن سحبُه من هاتفٍ وصل إليه.
 *
 * **ومفتاحُ منعِ التكرار الطلبيةُ نفسها**: تولد مرّةً واحدة، فمهمّةٌ أُعيدت محاولتُها لا تنشر الخبرَ
 * مرّتين. والجمهورُ والجملة قرارُ {@see OrderAwaitsReview}.
 */
final class NotifyWhenOrderIsRequested implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(OrderRequested $event): void
    {
        $order = Order::query()->with('customer')->find($event->orderId);

        // ذهبت بين الإيداع وتشغيل المهمّة، أو راجعها أحدٌ قبل أن تصل المهمّة إليها: لا شيء
        // ينتظر أحداً بعد، وجرسٌ عن طلبيةٍ قُبلت للتوّ يرسل المراجِعَ إلى عملٍ انتهى.
        if ($order === null || $order->status !== OrderStatus::Requested) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::OrderRequested,
            subject: $order,
            // مجمّدةٌ الآن، فتبقى الجملةُ صحيحةً بعد أن تُعدَّل الطلبية أو تُحذف.
            payload: [
                'order_id' => (int) $order->getKey(),
                'order_code' => (string) $order->code,
                'customer_name' => (string) ($order->customer?->name ?? ''),
            ],
            dedupeKey: 'order.requested:'.$order->getKey(),
        ));
    }
}
