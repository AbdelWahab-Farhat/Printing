<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;

/**
 * يقدّم مؤشّر قراءة أحد الطرفين — بقواعد الدعم نفسها (SUPPORT-CHAT-DESIGN §٢):
 *
 * - **إلى آخر رسالةٍ عُرضت على القارئ**، لا إلى «الآن»: رسالةٌ وصلت بين قراءة الخيط وتحريك
 *   المؤشّر لم تكن على الشاشة.
 * - **لا يرجع**: قراءةٌ أبطأ حملت أقلّ لا تمحو ما قُرئ.
 * - **يُعلَن فقط حين قُرئ جديدٌ من الطرف الآخر**، فتصير ✓✓ عند الكاتب.
 *
 * **ومَن ليس طرفاً لا يحرّك شيئاً.** المدير يفتح تذكرةً بين اثنين فيقرؤها، ولا تصير ✓✓ عند أحدهما
 * كأن زميله قرأ.
 */
final class MarkInternalTicketRead
{
    public function __invoke(InternalTicket $ticket, User $reader, ?int $upToMessageId = null): void
    {
        $readerId = (int) $reader->getKey();
        $column = $ticket->readCursorColumnFor($readerId);

        if ($column === null) {
            return;
        }

        $before = $ticket->readUpToFor($readerId);
        $seen = $upToMessageId ?? $this->lastMessageIn($ticket);
        $after = max($before ?? 0, $seen ?? 0);

        if ($after <= ($before ?? 0)) {
            return;
        }

        $readSomethingNew = InternalTicketMessage::query()
            ->where('internal_ticket_id', $ticket->getKey())
            ->where('user_id', '!=', $readerId)
            ->when($before !== null, fn ($query) => $query->where('id', '>', $before))
            ->where('id', '<=', $after)
            ->exists();

        $ticket->forceFill([$column => $after])->save();

        if ($readSomethingNew) {
            InternalTicketChanged::dispatch((int) $ticket->getKey(), InternalTicketChange::Read);
        }
    }

    private function lastMessageIn(InternalTicket $ticket): ?int
    {
        $id = InternalTicketMessage::query()->where('internal_ticket_id', $ticket->getKey())->max('id');

        return $id === null ? null : (int) $id;
    }
}
