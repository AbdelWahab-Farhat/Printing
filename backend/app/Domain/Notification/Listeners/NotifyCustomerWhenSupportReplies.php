<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\DTOs\CustomerPush;
use App\Domain\Notification\NotificationService;
use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر العميلَ على هاتفه أن المحلَّ ردَّ عليه في الدعم.
 *
 * الوجهُ الآخر لـ{@see NotifyWhenCustomerWritesToSupport}، على الحدث نفسه: رسالةُ العميل خبرٌ للمحل،
 * وردُّ المحل خبرٌ للعميل. **ولا رسائلَ آليّة في الدعم** — كلُّ رسالةٍ كتبها موظفٌ أو العميل، والجدولُ
 * يفرض ذلك بـ`CHECK` — فكلُّ رسالةٍ ليست من العميل ردٌّ حقيقي.
 *
 * ### ردودٌ متتالية دفعةٌ واحدة، حتى يقرأ العميل
 *
 * موظفٌ يكتب «أهلاً» ثم الجواب ثم رقمَ الطلبية في دقيقة لا يوقظ العميل ثلاث مرات. فالسؤال: هل في
 * التذكرة ردٌّ أسبقُ من هذا لم يقرأه العميل بعد (بعد `customer_read_message_id`)؟ إن كان، فقد دُفع
 * لأجله، وهذا ينضمّ إليه. فإذا قرأ العميلُ الخيط — بفتحه، أو بالردّ عليه — تقدّم مؤشّره، وصار الردُّ
 * التالي خبراً جديداً.
 *
 * وكذلك ردٌّ قرأه العميلُ قبل أن يصل الطابورُ إلى هذا المستمِع — كان الخيطُ مفتوحاً فوصله حيّاً —
 * لا يُدفع: قد عرفه.
 *
 * ### النصُّ موضوعُ التذكرة، لا نصُّ الرسالة
 *
 * قاعدةُ الشاشة المقفلة نفسها التي عند الموظفين: الردُّ قد يحمل مبلغاً أو رقماً، ويقرؤه مَن يحمل
 * الهاتف. الموضوعُ يقول أيَّ محادثةٍ هي، والتطبيقُ يعرض الردَّ بعد اللمس.
 *
 * ### مُدرَجٌ في الطابور، وبعد الإيداع
 *
 * كالجيران جميعاً.
 */
final class NotifyCustomerWhenSupportReplies implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(TicketChanged $event): void
    {
        if ($event->change !== TicketChange::MessagePosted || $event->messageId === null) {
            return;
        }

        $message = TicketMessage::query()->find($event->messageId);

        // رسالةُ العميل نفسه لا تُدفع إليه — كتبها وهو يراها.
        if ($message === null || $message->isFromCustomer()) {
            return;
        }

        $ticket = SupportTicket::query()->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $messageId = (int) $message->getKey();
        $readUpTo = (int) ($ticket->customer_read_message_id ?? 0);

        if ($readUpTo >= $messageId || $this->anEarlierReplyIsUnread($ticket, $readUpTo, $messageId)) {
            return;
        }

        $this->notifications->pushToCustomer(new CustomerPush(
            customerId: (int) $ticket->customer_id,
            title: 'ردٌّ من الدعم',
            body: (string) $ticket->subject,
            route: '/support/'.$ticket->getKey(),
        ));
    }

    /**
     * هل سبق هذا الردَّ ردٌّ آخر من المحل لم يقرأه العميل؟ فذاك دُفع لأجله، وهذا ينضمّ إليه.
     */
    private function anEarlierReplyIsUnread(SupportTicket $ticket, int $readUpTo, int $messageId): bool
    {
        return TicketMessage::query()
            ->where('support_ticket_id', $ticket->getKey())
            ->whereNotNull('user_id')
            ->where('id', '>', $readUpTo)
            ->where('id', '<', $messageId)
            ->exists();
    }
}
