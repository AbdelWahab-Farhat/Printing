<?php

declare(strict_types=1);

namespace App\Application\Realtime\Listeners;

use App\Application\Realtime\Events\InternalTicketThreadChanged;
use App\Application\Realtime\Events\StaffInternalTicketsChanged;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;

use function Illuminate\Support\defer;

/**
 * ينقل تغيّرَ التذكرة الداخلية إلى قناتيه — كـBroadcastTicketChange في الدعم، وللأسباب نفسها: بعد
 * إرسال الرد (`defer`)، لا عبر الطوابير، ولا يُسقط أحداً إن كان Reverb نائماً.
 *
 * - **المحادثة** (`internal-tickets.{id}`): كلُّ تغيير، بالتذكرة والرسالة.
 * - **قناةُ كلِّ طرف** (`staff.{id}`): الإشارةُ وحدها. **وصاحبُها السابق معهما بعد التحويل**:
 *   خرج منها، وبطاقتُه تحتاج أن تعرف ذلك لتُسقطها.
 */
final class BroadcastInternalTicketChange
{
    /** ما ترسمه المحادثةُ للتذكرة والرسالة — بلا الخيط، فالشاشةُ تضيف الرسالة الواحدة. */
    private const TICKET = ['opener', 'assignee', 'closer', 'category', 'customer', 'order'];

    private const MESSAGE = ['ticket', 'author', 'attachments', 'replyTo.author', 'replyTo.attachments'];

    public function handle(InternalTicketChanged $event): void
    {
        defer(fn () => $this->broadcast($event));
    }

    private function broadcast(InternalTicketChanged $event): void
    {
        $ticket = InternalTicket::query()->with(self::TICKET)->find($event->ticketId);

        if ($ticket === null) {
            return;
        }

        $message = $event->messageId === null
            ? null
            : InternalTicketMessage::query()->with(self::MESSAGE)->find($event->messageId);

        event(new InternalTicketThreadChanged($ticket, $event->change, $message));

        $people = array_values(array_unique(array_filter([
            $ticket->opened_by,
            $ticket->assignee_id,
            $event->change === InternalTicketChange::Transferred ? $event->formerOwnerId : null,
        ])));

        event(new StaffInternalTicketsChanged($people, (int) $ticket->getKey(), $event->change));
    }
}
