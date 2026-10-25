<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Exceptions\InternalTicketIsClosed;
use App\Domain\InternalTicket\Exceptions\InvalidNewOwner;
use App\Domain\InternalTicket\Exceptions\NotPartyToInternalTicket;
use App\Domain\InternalTicket\Models\InternalTicket;

/**
 * «تحويل»: صاحبُ التذكرة يسلّمها لموظفٍ آخر يحلّ **محلّه هو** — كبريمولا، لا محلَّ الزميل الذي
 * وُجّهت إليه. موظفٌ فتح سؤالاً ثم انتقل إلى عملٍ آخر يسلّم السؤال لمن سيتابعه، والزميلُ الذي
 * يجيب يبقى كما هو.
 *
 * يملكه صاحبُها والمدير. **والصاحبُ الجديد لم يقرأ شيئاً بعد**: مؤشّرُه يبدأ فارغاً، فيرى المحادثة
 * كلّها غير مقروءة — وهي كذلك بالنسبة إليه. والتذكيرُ يبدأ عدّه من جديد.
 */
final class TransferInternalTicket
{
    public function __invoke(InternalTicket $ticket, User $actor, User $newOwner): InternalTicket
    {
        if ($ticket->opened_by !== (int) $actor->getKey() && ! $actor->isAdmin()) {
            throw NotPartyToInternalTicket::make('يحوّل التذكرة صاحبُها وحده');
        }

        if (! $ticket->status->isOpen()) {
            throw InternalTicketIsClosed::make();
        }

        $newOwnerId = (int) $newOwner->getKey();

        if ($newOwnerId === $ticket->opened_by) {
            throw InvalidNewOwner::isAlreadyOwner();
        }

        if ($newOwnerId === $ticket->assignee_id) {
            throw InvalidNewOwner::isTheAssignee();
        }

        $formerOwnerId = $ticket->opened_by;

        $ticket->opened_by = $newOwnerId;
        $ticket->opener_read_message_id = null;
        // و«قرأتُها» كانت لصاحبها القديم: الجديدُ لم يرَ شيئاً، فتبدأ على بطاقته.
        $ticket->opener_seen_message_id = null;
        $ticket->reminder_count = 0;
        $ticket->last_reminder_at = null;
        $ticket->save();

        InternalTicketChanged::dispatch(
            (int) $ticket->getKey(),
            InternalTicketChange::Transferred,
            formerOwnerId: $formerOwnerId,
        );

        return $ticket->refresh();
    }
}
