<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\Definitions\CustomerWroteToSupport;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر المحلَّ أنّ عميلاً كتب إلى الدعم.
 *
 * ### الغربلةُ هنا
 *
 * `TicketChanged` يُطلَق عن كل تغييرٍ في تذكرة — رسالةٌ من أيّ الطرفين، إسنادٌ، إغلاق، قراءة —
 * لأن سياق Support يقول ما حدث ولا يعرف مَن يعنيه. **وهذا الصنف صاحبُ الرأي**: أنّ رسالةَ العميل
 * خبرٌ للمحل، وأنّ ردَّ المحل خبرٌ للعميل لا للمحل. والبثُّ الحيُّ مستمعٌ ثانٍ للحدث نفسه.
 *
 * ### رسائلُ متتالية جرسٌ واحد، حتى يقرأ المكتب
 *
 * **وهو خلافُ مفتاح تعليقات التصميم عن قصد**، وهي رسالةٌ برسالة. تلك محادثةٌ بين اثنين يتناوبان،
 * وهذه عميلٌ يكتب «السلام عليكم» ثم سؤاله ثم رقمَ طلبيته في دقيقة، والجرسُ يصل إلى كل مَن يستطيع
 * الردّ حين لا يكون على التذكرة أحد. فالمفتاحُ التذكرةُ وحدُّ قراءة المكتب فيها
 * (`staff_read_message_id`): ما دام المكتبُ لم يقرأ فالرسالةُ التالية تنضمّ إلى الجرس القائم، فإذا
 * قرأ — أو ردّ، والردُّ يقدّم الحدّ — تغيّر المفتاحُ وصارت التاليةُ خبراً جديداً.
 *
 * ### مُدرَجٌ في الطابور، وبعد الإيداع
 *
 * كالجيران جميعاً. والجمهورُ والجملة قرارُ {@see CustomerWroteToSupport}.
 */
final class NotifyWhenCustomerWritesToSupport implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(TicketChanged $event): void
    {
        if ($event->change !== TicketChange::MessagePosted || $event->messageId === null) {
            return;
        }

        $message = TicketMessage::query()->find($event->messageId);

        // ردُّ المحل خبرٌ للعميل، يحمله البثُّ الحيّ إلى تطبيقه — لا جرسٌ في المحل نفسه.
        if ($message === null || ! $message->isFromCustomer()) {
            return;
        }

        $ticket = SupportTicket::query()->with('customer')->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        // أولى رسائل التذكرة هي التي فتحتها — `OpenTicket` لا يُعلن شيئاً بنفسه.
        $isOpening = ! TicketMessage::query()
            ->where('support_ticket_id', $ticket->getKey())
            ->where('id', '<', $message->getKey())
            ->exists();

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::SupportCustomerMessage,
            subject: $ticket,
            // بلا نصّ الرسالة: الدفعُ يُقرأ على شاشةٍ مقفلة، ولا يُخزَّن ما لا يجوز أن يُقال.
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'subject' => (string) $ticket->subject,
                'customer_name' => (string) ($ticket->customer?->name ?? ''),
                // مَن على المكتب ساعةَ كُتبت، لا ساعةَ يُقرأ الجرس.
                'assignee_id' => $ticket->assigned_to !== null ? (int) $ticket->assigned_to : null,
                'is_opening' => $isOpening,
                'message_id' => (int) $message->getKey(),
            ],
            dedupeKey: 'support.customer_message:'.$ticket->getKey().':'.(int) ($ticket->staff_read_message_id ?? 0),
        ));
    }
}
