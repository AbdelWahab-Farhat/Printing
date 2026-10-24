<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Identity\Models\User;

/**
 * يقدّم مؤشّر قراءة أحد الطرفين — بقواعد `MarkInternalTicketRead`:
 *
 * - **إلى آخر رسالةٍ عُرضت على القارئ**، لا إلى «الآن»: رسالةٌ وصلت بين قراءة الخيط وتحريك
 *   المؤشّر لم تكن على الشاشة.
 * - **لا يرجع**: قراءةٌ أبطأ حملت أقلّ لا تمحو ما قُرئ.
 * - **ولا يتجاوز المحادثة**: رقمٌ أكبر من آخر رسالةٍ فيها يُقصّ إليها، فلا تصير رسائلُ لم تُكتب
 *   بعدُ مقروءةً سلفاً.
 * - **يُعلَن فقط حين قُرئ جديدٌ من غير القارئ**، فتصير ✓✓ عند الكاتب.
 *
 * **ومَن ليس طرفاً لا يحرّك شيئاً.** مديرٌ يفتح المحادثة فيقرؤها، ولا تصير ✓✓ عند أحد.
 */
final class MarkDesignTicketRead
{
    public function __invoke(DesignTicket $ticket, User $reader, ?int $upToMessageId = null): void
    {
        $readerId = (int) $reader->getKey();
        $column = $ticket->readCursorColumnFor($readerId);

        if ($column === null) {
            return;
        }

        $last = DesignTicketMessage::query()->where('design_ticket_id', $ticket->getKey())->max('id');

        if ($last === null) {
            return;
        }

        $before = $ticket->readUpToFor($readerId) ?? 0;
        $seen = min($upToMessageId ?? (int) $last, (int) $last);

        if ($seen <= $before) {
            return;
        }

        $readSomethingNew = DesignTicketMessage::query()
            ->where('design_ticket_id', $ticket->getKey())
            ->where('user_id', '!=', $readerId)
            ->where('id', '>', $before)
            ->where('id', '<=', $seen)
            ->exists();

        $ticket->forceFill([$column => $seen])->save();

        if ($readSomethingNew) {
            DesignConversationChanged::dispatch((int) $ticket->getKey(), DesignConversationChange::Read);
        }
    }
}
