<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\DTOs;

use App\Domain\InternalTicket\Models\InternalTicket;

/**
 * بطاقةُ الرئيسية، كبطاقة بريمولا: ما ينتظر ردّي، وأرقامُ ما على مكتبي.
 */
final readonly class InternalTicketHome
{
    /**
     * @param  list<InternalTicket>  $tickets  حتى عشر، الأحدث بكلام الزميل أولاً
     */
    public function __construct(
        public array $tickets,
        /** كلُّ ما ينتظر ردّي، لا الصفحة وحدها. */
        public int $awaitingMyReply,
        public bool $hasMore,
        /** كلُّ المفتوح الذي أنا طرفٌ فيه — «كم على مكتبي» سؤالٌ غير «ماذا أفعل الآن». */
        public int $totalOpen,
        public int $unreadTickets,
    ) {}
}
