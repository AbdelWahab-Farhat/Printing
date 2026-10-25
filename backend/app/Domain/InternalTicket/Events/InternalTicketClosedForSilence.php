<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Events;

use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * أُغلقت تذكرةٌ داخلية لأن أحداً من طرفيها لم يكتب ثلاثة أيام — CloseSilentInternalTickets.
 *
 * حدثٌ وحده لا حالةٌ من `InternalTicketChange`، كتذكير الصباح: الإغلاقُ بيد أحدٍ لا جرس عليه،
 * وهذا يُخبَر به الطرفان — والجرسُ يصغي إليه هو وحده.
 */
final readonly class InternalTicketClosedForSilence implements ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(public int $ticketId) {}
}
