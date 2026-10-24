<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Enums;

/**
 * ما الذي تغيّر في محادثة تذكرة تصميم — ليعرف مَن يستمع هل يعنيه.
 *
 * كنظيره في التذاكر الداخلية: ليس سجلاً ولا حالة. هو جوابُ سؤالٍ يسأله البثُّ الحيّ والجرس.
 */
enum DesignConversationChange: string
{
    case MessagePosted = 'message_posted';

    /** غيّر صاحبُ الرسالة نصّها خلال المهلة. لا جرس عليه: بثٌّ حيٌّ فقط. */
    case MessageEdited = 'message_edited';

    /** سحبها صاحبها: «تم حذف هذه الرسالة». لا جرس عليه أيضاً. */
    case MessageRetracted = 'message_retracted';

    /** قرأ أحدُ الطرفين ما كتبه الآخر — علامة ✓✓ عند الكاتب. */
    case Read = 'read';
}
