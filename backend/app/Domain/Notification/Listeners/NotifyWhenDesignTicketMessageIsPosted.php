<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Notification\Definitions\DesignTicketCommentPosted;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر الطرفَ الآخر من محادثة التذكرة أنّ هناك ردّاً.
 *
 * ### الإشعارُ نفسه، من حدثٍ آخر
 *
 * كانت المحادثةُ ملاحظاتٍ، وكان هذا الصنفُ يغربل `CommentPosted` عن كلّ ملاحظةٍ في النظام. صارت
 * رسائلَ على محرّك التذاكر الداخلية (DESIGN-TICKET-CHAT)، فصار يسمع `DesignConversationChanged`.
 * **وما سواه لم يتغيّر**: النوعُ نفسه، والجمهورُ نفسه، والجملةُ والوجهةُ نفسها — فالشارةُ على
 * البطاقة، وعدُّ الجرس، وإشعاراتُ الأمس التي تفتح `/comments`، كلُّها تعمل كما كانت.
 *
 * **والرسالةُ الجديدة وحدها خبر.** التعديلُ والسحبُ يُبثّان حيّاً ولا يُوقظان أحداً، كالتذاكر
 * الداخلية.
 *
 * ### مُدرَجٌ في الطابور، وبعد الإيداع
 *
 * كالجيران جميعاً في هذا المجلّد: دفعٌ فاشل لا يجوز أن يتراجع بكتابةٍ نجحت، وردٌّ أُعلن عن معاملةٍ
 * تراجعت لا يمكن سحبُه من هاتفٍ وصل إليه.
 *
 * ### مفتاحُ منعِ التكرار على الرسالة نفسها
 *
 * **وهو خلافُ ما يفعله الجيران عن قصد.** مفاتيحُهم على السجلّ وحالته، فتنطوي نوبةُ ذهابٍ وإياب في
 * صباحٍ واحد إلى خبرٍ واحد. والمحادثةُ ليست كذلك: رسالتان متتاليتان رسالتان، ونافذةُ الستّ ساعات
 * كانت ستُسكت الثانيةَ منهما — وهو بالضبط ما يُعيد الناسَ إلى واتساب. فالمفتاحُ معرِّفُ الرسالة:
 * لا يطوي ردَّين مختلفَين أبداً، ويمنع مهمّةً أُعيدت محاولتُها أن تنشر الخبرَ مرّتين. **وبادئتُه
 * `message` لا `comment`**: الرقمان من جدولين، وقد يلتقيان.
 */
final class NotifyWhenDesignTicketMessageIsPosted implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(DesignConversationChanged $event): void
    {
        if ($event->change !== DesignConversationChange::MessagePosted || $event->messageId === null) {
            return;
        }

        $message = DesignTicketMessage::query()->with('ticket')->find($event->messageId);
        $ticket = $message?->ticket;

        // تجوز أن تكون قد ذهبت بين الإيداع وتشغيل المهمّة، ولا شيء يُقال عن تذكرةٍ لم تعد موجودة.
        if ($ticket === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::DesignTicketComment,
            subject: $ticket,
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'code' => $ticket->code,
                'title' => $ticket->title,
                'message_id' => (int) $message->getKey(),
                // الطرفان يسافران معاً، ومَن يسمع منهما قرارُ التعريفة لا قرارُ هذا الصنف —
                // انظر {@see DesignTicketCommentPosted}.
                'requester_id' => $ticket->requested_by_user_id,
                // مَن يعمل عليها فعلاً: بعد إعادة الإسناد هو مَن قبلها لا مَن صارت باسمه.
                'designer_id' => $ticket->designerId(),
            ],
            causerId: $message->user_id,
            dedupeKey: 'design_ticket.message:'.$message->getKey(),
        ));
    }
}
