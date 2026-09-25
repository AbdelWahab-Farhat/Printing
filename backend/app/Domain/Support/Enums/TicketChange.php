<?php

declare(strict_types=1);

namespace App\Domain\Support\Enums;

/**
 * ما الذي تغيّر في تذكرة — ليعرف من يستمع هل يعنيه.
 *
 * **ليس سجلاً ولا حالة.** الحالة في {@see TicketStatus}، والأثر في سجلّ التدقيق. هذا جوابُ سؤالٍ
 * واحد يسأله البثُّ الحيّ: لمن يُقال؟
 */
enum TicketChange: string
{
    /** رسالةٌ جديدة من أيّ الطرفين، ومنها أولى رسائل التذكرة ساعةَ تُفتح. */
    case MessagePosted = 'message_posted';

    /** وُضعت على مكتب موظف، أو أُعيدت إلى الطابور. */
    case Assigned = 'assigned';

    case Closed = 'closed';

    /** أعاد الموظف فتحها عن قصد — ردُّ العميل الذي يفتحها رسالةٌ لا هذا. */
    case Reopened = 'reopened';

    /**
     * قرأ المكتبُ رسائل العميل التي لم تُقرأ: انطفأت شارتها عند كل الموظفين، وصارت ✓✓ عند العميل.
     */
    case ReadByDesk = 'read_by_desk';

    /** قرأ العميلُ ردودَ المحل التي لم يقرأها — يراها المكتبُ علامةَ قراءةٍ على ردوده. */
    case ReadByCustomer = 'read_by_customer';

    /**
     * هل يعني العميلَ هذا التغيير؟
     *
     * **الإسنادُ لا يعنيه**، ولا قراءتُه هو: على أيّ مكتبٍ تجلس تذكرته ترتيبٌ داخليٌّ للمحل لا
     * يراه في تطبيقه، وما قرأه بنفسه يعرفه. فالحدث الذي لا يغيّر شيئاً مما يراه لا يُرسَل إليه.
     *
     * **وقراءةُ المكتب تعنيه منذ ٢٠٢٦-٠٩-٢٥**: طلب صاحب المحل علامة القراءة ✓✓ في تطبيق العميل،
     * فالحدث يحمل التذكرة بحدّها الجديد (`support_read_up_to`) — الحدّ وحده، لا متى ولا مَن.
     *
     * `match` بلا `default`: حالةٌ جديدة تكسر البناء حتى يقول أحدٌ لمن تُقال.
     */
    public function reachesCustomer(): bool
    {
        return match ($this) {
            self::MessagePosted, self::Closed, self::Reopened, self::ReadByDesk => true,
            self::Assigned, self::ReadByCustomer => false,
        };
    }
}
