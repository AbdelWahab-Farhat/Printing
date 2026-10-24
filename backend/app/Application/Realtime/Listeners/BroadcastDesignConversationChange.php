<?php

declare(strict_types=1);

namespace App\Application\Realtime\Listeners;

use App\Application\Realtime\Events\DesignTicketThreadChanged;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;

use function Illuminate\Support\defer;

/**
 * ينقل تغيّرَ محادثة التذكرة إلى قناتها (`design-tickets.{id}`) — كـBroadcastInternalTicketChange،
 * وللأسباب نفسها: بعد إرسال الرد (`defer`)، لا عبر الطوابير، ولا يُسقط أحداً إن كان Reverb نائماً.
 *
 * **ولا قناةَ موظفٍ هنا**: قائمةُ تذاكر التصميم لا تعيش على المقبس، وشارتُها من الجرس.
 */
final class BroadcastDesignConversationChange
{
    /** ما يرسمه الشريط — بلا الرسائل، فالشاشةُ تضيف الرسالة الواحدة. */
    private const TICKET = ['requester', 'designer', 'acceptedBy'];

    private const MESSAGE = ['ticket', 'author', 'attachments', 'replyTo.author', 'replyTo.attachments'];

    public function handle(DesignConversationChanged $event): void
    {
        defer(fn () => $this->broadcast($event));
    }

    private function broadcast(DesignConversationChanged $event): void
    {
        $ticket = DesignTicket::query()->with(self::TICKET)->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $message = $event->messageId === null
            ? null
            : DesignTicketMessage::query()->with(self::MESSAGE)->find($event->messageId);

        event(new DesignTicketThreadChanged($ticket, $event->change, $message));
    }
}
