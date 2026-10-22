<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * جرسُ التذاكر الداخلية، كبريمولا: تذكرةٌ جديدة لمن وُجّهت إليه، ورسالةٌ جديدة للطرف الآخر.
 *
 * **والباقي لا جرس عليه.** التعديلُ والسحبُ والإغلاقُ والقراءةُ تصل حيّةً فقط — جرسٌ على كل
 * تصحيحٍ إملائيّ يُزعج الطرف الآخر بلا خبر، وهو قرار بريمولا.
 *
 * **رسائلُ متتالية جرسٌ واحد حتى يقرأ**، كمفتاح الدعم: المفتاحُ التذكرةُ والمستقبِلُ ومؤشّرُ قراءته —
 * ما دام لم يقرأ فالتاليةُ تنضمّ إلى الجرس القائم، فإذا قرأ تغيّر المفتاح. زميلٌ يرسل «السلام عليكم»
 * ثم سؤاله ثم صورةً في دقيقة يوقظ زميله مرّةً لا ثلاثاً.
 *
 * مُدرَجٌ في الطابور، وبعد الإيداع، كالجيران جميعاً.
 */
final class NotifyOnInternalTicketActivity implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(InternalTicketChanged $event): void
    {
        if ($event->change !== InternalTicketChange::Opened && $event->change !== InternalTicketChange::MessagePosted) {
            return;
        }

        $ticket = InternalTicket::query()->with(['opener', 'assignee'])->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        if ($event->change === InternalTicketChange::Opened) {
            $this->notifications->publish(PendingNotification::about(
                type: NotificationType::InternalTicketOpened,
                subject: $ticket,
                payload: [
                    'ticket_id' => (int) $ticket->getKey(),
                    'code' => (string) $ticket->code,
                    'title' => (string) $ticket->title,
                    'assignee_id' => $ticket->assignee_id,
                    'opener_name' => (string) ($ticket->opener?->name ?? ''),
                ],
                causerId: $ticket->opened_by,
            ));

            return;
        }

        $message = $event->messageId === null
            ? null
            : InternalTicketMessage::query()->with(['author', 'attachments'])->find($event->messageId);

        if ($message === null || $message->author === null) {
            return;
        }

        $recipientId = $ticket->counterpartIdOf($message->author);

        if ($recipientId === null) {
            return;
        }

        $this->notifications->publish(PendingNotification::about(
            type: NotificationType::InternalTicketMessage,
            subject: $ticket,
            // بلا نصّ الرسالة: الدفعُ يُقرأ على شاشةٍ مقفلة.
            payload: [
                'ticket_id' => (int) $ticket->getKey(),
                'title' => (string) $ticket->title,
                'recipient_id' => $recipientId,
                'author_name' => (string) $message->author->name,
                'kind' => $this->kindOf($message),
                'message_id' => (int) $message->getKey(),
            ],
            causerId: $message->user_id,
            dedupeKey: 'internal_ticket.message:'.$ticket->getKey().':'.$recipientId.':'
                .(int) ($ticket->readUpToFor($recipientId) ?? 0),
        ));
    }

    /** ما في الرسالة إن لم يكن فيها كلام: صوتٌ أو صورة — ليقول الجرسُ ذلك. */
    private function kindOf(InternalTicketMessage $message): string
    {
        if ($message->body !== null && $message->body !== '') {
            return 'text';
        }

        return match ($message->attachments->first()?->kind) {
            InternalAttachmentKind::Voice => 'voice',
            InternalAttachmentKind::Image => 'image',
            null => 'text',
        };
    }
}
