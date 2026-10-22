<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Enums;

/**
 * ما الذي تغيّر في تذكرةٍ داخلية — ليعرف من يستمع هل يعنيه.
 *
 * كنظيره في الدعم: ليس سجلاً ولا حالة. هو جوابُ سؤالٍ يسأله البثُّ الحيّ والجرس: لمن يُقال، وبأيّ
 * جملة.
 */
enum InternalTicketChange: string
{
    /** فُتحت، ومعها أولى رسائلها. */
    case Opened = 'opened';

    case MessagePosted = 'message_posted';

    /** غيّر صاحبُ الرسالة نصّها خلال المهلة. لا جرس عليه، كبريمولا: بثٌّ حيٌّ فقط. */
    case MessageEdited = 'message_edited';

    /** سحبها صاحبها: «تم حذف هذه الرسالة». لا جرس عليه أيضاً. */
    case MessageRetracted = 'message_retracted';

    /** قرأ أحدُ الطرفين ما كتبه الآخر — علامة ✓✓ عند الكاتب. */
    case Read = 'read';

    case Closed = 'closed';

    /** صار لها صاحبٌ جديد. */
    case Transferred = 'transferred';
}
