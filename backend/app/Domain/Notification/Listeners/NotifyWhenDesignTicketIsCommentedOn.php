<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Comment\Events\CommentPosted;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Notification\Definitions\DesignTicketCommentPosted;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * يُخبر الطرفَ الآخر من محادثة التذكرة أنّ هناك ردّاً.
 *
 * ### الغربلةُ هنا، وهذا هو موضعها
 *
 * `CommentPosted` يُطلق عن كلِّ ملاحظةٍ تُكتب في النظام — على عميلٍ أو مورّدٍ أو تذكرة — لأن
 * «كُتبت ملاحظة» واقعةٌ عن الملاحظات لا عن التصميم، وسياقُ الملاحظات لا شأن له بمن يعنيه ذلك.
 * **وهذا الصنف هو صاحبُ الرأي**: أنّ الردَّ داخل تذكرةٍ خبرٌ لطرفها الآخر، وأنّ ملاحظةً على ملفّ
 * عميلٍ ليست خبراً لأحدٍ اليوم. ولو وُضعت هذه القائمةُ في `PostComment` لاحتاج المستمِعُ الثاني —
 * حين تُريد الملاحظاتُ على العميل جرساً — أن يُعدّل سياقَ الملاحظات كي يسمع. وهي الحجّةُ نفسها
 * التي يسوقها {@see NotifyWhenOrderStatusChanges} لقائمة حالاته.
 *
 * ### مُدرَجٌ في الطابور، وبعد الإيداع
 *
 * كالجيران جميعاً في هذا المجلّد: دفعٌ فاشل لا يجوز أن يتراجع بكتابةٍ نجحت، وردٌّ أُعلن عن معاملةٍ
 * تراجعت لا يمكن سحبُه من هاتفٍ وصل إليه.
 *
 * ### مفتاحُ منعِ التكرار على التعليق نفسه
 *
 * **وهو خلافُ ما يفعله الجيران عن قصد.** مفاتيحُهم على السجلّ وحالته، فتنطوي نوبةُ ذهابٍ وإياب في
 * صباحٍ واحد إلى خبرٍ واحد. والمحادثةُ ليست كذلك: رسالتان متتاليتان رسالتان، ونافذةُ الستّ ساعات
 * كانت ستُسكت الثانيةَ منهما — وهو بالضبط ما يُعيد الناسَ إلى واتساب، والتعليقاتُ في التذكرة
 * وُجدت لتُخرجهم منه. فالمفتاحُ هنا معرِّفُ التعليق: لا يطوي ردَّين مختلفَين أبداً، ويمنع مهمّةً
 * أُعيدت محاولتُها أن تنشر الخبرَ مرّتين.
 */
final class NotifyWhenDesignTicketIsCommentedOn implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(CommentPosted $event): void
    {
        if ($event->commentableType !== AuditSubject::DesignTicket->value) {
            return;
        }

        $ticket = DesignTicket::query()->find($event->commentableId);

        // تجوز أن تكون قد ذهبت بين الإيداع وتشغيل المهمّة. ولا شيء يُقال عن تذكرةٍ لم تعد
        // موجودة — والملاحظةُ ذهبت معها بالحذف المتتالي أصلاً.
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
                'comment_id' => $event->commentId,
                // الطرفان يسافران معاً، ومَن يسمع منهما قرارُ التعريفة لا قرارُ هذا الصنف —
                // انظر {@see DesignTicketCommentPosted}.
                'requester_id' => $ticket->requested_by_user_id,
                // مَن يعمل عليها فعلاً: بعد إعادة الإسناد هو مَن قبلها لا مَن صارت باسمه.
                'designer_id' => $ticket->accepted_by_user_id ?? $ticket->assigned_designer_id,
            ],
            causerId: $event->authorId,
            dedupeKey: 'design_ticket.comment:'.$event->commentId,
        ));
    }
}
