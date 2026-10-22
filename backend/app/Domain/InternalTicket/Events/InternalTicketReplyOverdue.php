<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Events;

use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * تأخّر ردُّ أحد الطرفين في تذكرةٍ داخلية، وحان تذكيره.
 *
 * السياقُ يقول مَن يُنتظر ومَن ينتظر، والجرسُ يصغي — الاتجاهُ نفسه الذي في بقية الأحداث.
 */
final readonly class InternalTicketReplyOverdue implements ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        /** مَن يُنتظر ردّه — إليه التذكير. */
        public int $awaitedUserId,
        /** مَن ينتظر — اسمُه في التذكير. */
        public int $waitingUserId,
    ) {}
}
