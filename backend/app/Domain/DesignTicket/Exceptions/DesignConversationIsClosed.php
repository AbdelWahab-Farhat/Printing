<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Support\Exceptions\DomainException;

/**
 * كُتب شيءٌ على محادثة تذكرةٍ انتهت، أو أُعيدت كتابةُ ما قيل فيها أو سُحب.
 *
 * **والتذكرة هي التي تقول لماذا**: «اعتُمد التصميم وأُغلقت المحادثة» تقول ما حدث وأنّ شيئاً لم
 * يضع — انظر {@see DesignTicket::conversationClosedNote()}.
 *
 * و422 لا 403: لم يُرفض أحدٌ لِمن هو. ومَن يرى التذاكر كلّها يلقى هذه أيضاً — فالمُعلَن هنا حالُ
 * التذكرة.
 */
final class DesignConversationIsClosed extends DomainException
{
    public static function make(DesignTicket $ticket): self
    {
        return new self($ticket->conversationClosedNote() ?? 'أُغلقت المحادثة على هذه التذكرة');
    }
}
