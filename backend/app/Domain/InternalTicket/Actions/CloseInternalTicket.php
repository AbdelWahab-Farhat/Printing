<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Exceptions\NotPartyToInternalTicket;
use App\Domain\InternalTicket\Models\InternalTicket;

/**
 * «إغلاق» — الإجراءُ الوحيد على حالة التذكرة الداخلية، ويملكه طرفاها والمدير.
 *
 * **نهائيّ**: لا إعادة فتح. **وغيرُ ضارٍّ إن تكرّر**، كإغلاق الدعم: ضغطةٌ ثانية لا تكتب شيئاً، ولا
 * تمحو اسم من أغلقها أولاً.
 */
final class CloseInternalTicket
{
    public function __invoke(InternalTicket $ticket, User $closer): InternalTicket
    {
        if (! $ticket->isParty($closer) && ! $closer->isAdmin()) {
            throw NotPartyToInternalTicket::make();
        }

        if (! $ticket->status->isOpen()) {
            return $ticket;
        }

        $ticket->status = InternalTicketStatus::Closed;
        $ticket->closed_at = now();
        $ticket->closed_by = $closer->getKey();
        $ticket->save();

        InternalTicketChanged::dispatch((int) $ticket->getKey(), InternalTicketChange::Closed);

        return $ticket->refresh();
    }
}
