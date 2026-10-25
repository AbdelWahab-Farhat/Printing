<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Exceptions\NotPartyToInternalTicket;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;

/**
 * «قرأتُها» — العلامةُ بجانب «رد» في بطاقة الرئيسية (طلبُ المالك ٢٠٢٦-١٠-٢٥): قرأتُ ما قاله زميلي
 * ولا ردّ عندي. تخرج التذكرةُ من بطاقتي ويسكت عنها تذكيرُ الصباح، **حتى يكتب زميلي من جديد**
 * ({@see InternalTicket::awaitsReplyOnHomeFrom()}).
 *
 * - **إلى آخر رسالةٍ كانت على البطاقة**، لا إلى «الآن»: رسالةٌ وصلت بعد رسم البطاقة لم يرها أحد،
 *   فلا تختفي معها. ورقمٌ أبعد من آخر رسالةٍ يُقصّ إليها — وإلا أخفى ما لم يُكتب بعد.
 * - **لا يرجع**، كمؤشّر القراءة: ضغطةٌ أبطأ حملت رقماً أقدم لا تعيد ما أُخرج.
 * - **وهي قراءةٌ أيضاً**: تحرّك مؤشّر القراءة إلى الرقم نفسه، فيرى زميلي ✓✓.
 *
 * **لطرفيها وحدهما**: المديرُ الذي ليس طرفاً لا بطاقةَ لها عنده، فلا ما يُخرجه منها.
 * **ولا تمسّ عدّاد الأيام الثلاثة**: الإغلاقُ يعدّ من آخر كلام، والعلامةُ ليست كلاماً.
 */
final class MarkInternalTicketSeen
{
    public function __construct(private readonly MarkInternalTicketRead $markRead) {}

    public function __invoke(InternalTicket $ticket, User $reader, ?int $upToMessageId = null): void
    {
        $readerId = (int) $reader->getKey();
        $column = $ticket->seenCursorColumnFor($readerId);

        if ($column === null) {
            throw NotPartyToInternalTicket::make();
        }

        $last = $this->lastMessageIn($ticket);

        if ($last === null) {
            return;
        }

        $seen = min($upToMessageId ?? $last, $last);
        $before = $ticket->seenUpToFor($readerId) ?? 0;

        if ($seen > $before) {
            $ticket->forceFill([$column => $seen])->save();
        }

        ($this->markRead)($ticket, $reader, $seen);
    }

    private function lastMessageIn(InternalTicket $ticket): ?int
    {
        $id = InternalTicketMessage::query()->where('internal_ticket_id', $ticket->getKey())->max('id');

        return $id === null ? null : (int) $id;
    }
}
