<?php

declare(strict_types=1);

namespace App\Domain\Support\Actions;

use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;

/**
 * Moves one side's read cursor forward.
 *
 * Its own action although it is a single assignment, because *which* cursor is the whole of the
 * decision and it must not be made twice in two controllers. Called whenever a thread is opened
 * — reading a conversation is what marks it read, and a separate «mark as read» button would be
 * a thing to forget to press.
 *
 * **المؤشّر يتقدّم إلى آخر رسالةٍ عُرضت على القارئ، لا إلى «الآن».** الشاشة تقرأ الخيط ثم يتحرّك
 * المؤشّر؛ ورسالةٌ كُتبت بين الاثنين لم تكن على الشاشة، فلا تُعلَّم مقروءة. لذلك يمرّر المستدعي
 * رقمَ آخر ما حمّله (`$upToMessageId`)، وحين لا يمرّره يُؤخذ آخر ما في الخيط الآن.
 *
 * **ولا يرجع إلى الوراء.** قراءةٌ أبطأ حملت رسائل أقل قد تصل بعد قراءةٍ أحدث، فلا تمحو ما قُرئ.
 */
final class MarkTicketRead
{
    public function __invoke(SupportTicket $ticket, bool $staff, ?int $upToMessageId = null): void
    {
        $before = $ticket->readUpTo($staff);
        $seen = $upToMessageId ?? $this->lastMessageIn($ticket);
        $after = max($before ?? 0, $seen ?? 0);

        // **يُقال فقط حين كان هناك ما يُقرأ**: فتحُ خيطٍ مقروء ليس خبراً، ومن يفتح الخيوط طوال
        // اليوم لا يملأ المقابس بلا شيء. وحين يقرأ المكتب — وهو يقرأ بمؤشّرٍ واحد — تنطفئ الشارة
        // عند زملاء القارئ أيضاً، ويرى العميل ✓✓ على رسائله.
        $readSomethingNew = $after > ($before ?? 0) && $this->otherSideWroteBetween($ticket, $staff, $before, $after);

        $ticket->forceFill([
            $staff ? 'staff_read_at' : 'customer_read_at' => now(),
            $staff ? 'staff_read_message_id' : 'customer_read_message_id' => $after > 0 ? $after : $before,
        ])->save();

        if ($readSomethingNew) {
            TicketChanged::dispatch(
                (int) $ticket->getKey(),
                $staff ? TicketChange::ReadByDesk : TicketChange::ReadByCustomer,
            );
        }
    }

    private function lastMessageIn(SupportTicket $ticket): ?int
    {
        $id = TicketMessage::query()->where('support_ticket_id', $ticket->getKey())->max('id');

        return $id === null ? null : (int) $id;
    }

    /** هل كتب الطرفُ الآخر شيئاً بين المؤشّر القديم والجديد؟ */
    private function otherSideWroteBetween(SupportTicket $ticket, bool $staff, ?int $before, int $after): bool
    {
        return TicketMessage::query()
            ->where('support_ticket_id', $ticket->getKey())
            ->whereNotNull($staff ? 'customer_id' : 'user_id')
            ->when($before !== null, fn ($q) => $q->where('id', '>', $before))
            ->where('id', '<=', $after)
            ->exists();
    }
}
