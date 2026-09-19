<?php

declare(strict_types=1);

namespace App\Domain\Notification\Actions;

use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Notification\Models\NotificationRecipient;
use Illuminate\Support\Carbon;

/**
 * قرأ هذا الشخصُ كلَّ ما قيل له عن هذا السجلّ.
 *
 * **يُستدعى حين تُفتح المحادثة، لا حين يُفتح الجرس.** مَن قرأ الردود في مكانها قرأها، وإبقاءُ
 * خبرِها في الجرس بعد ذلك يجعل الرقمَ فوق الجرس كذبةً صغيرةً تتكرّر — وهي الطريقة المضمونة
 * لتعليم الناس تجاهلَه.
 *
 * **تحديثٌ جماعيّ لا صفّاً صفّاً**، على شكل {@see MarkAllAsRead}: الصفوف لا تُدقَّق ولا يستمع
 * أحدٌ لأحداثها، ومحادثةٌ فيها اثنا عشر ردّاً لا تستحقّ اثني عشر استعلاماً.
 *
 * وهي عديمةُ الأثر عند التكرار: `whereNull('read_at')` تترك أوّلَ مرّةٍ قُرئ فيها الخبرُ كما هي،
 * فنقرتان على المحادثة لا تعيدان كتابة التاريخ — القاعدة نفسها التي تشرحها {@see MarkAsRead}.
 */
final readonly class MarkSubjectAsRead
{
    /**
     * @return int كم صفّاً كان ما يزال غيرَ مقروء
     */
    public function handle(string $subjectType, int $subjectId, int $userId, NotificationType $type): int
    {
        $now = Carbon::now();

        return NotificationRecipient::query()
            ->where('user_id', $userId)
            ->whereNull('read_at')
            // استعلامٌ فرعيّ لا قائمةُ معرِّفات: المحادثة الطويلة لا يُقرأ طرفاها إلى الذاكرة
            // لأجل جملةٍ تستطيع قاعدةُ البيانات كتابتها وحدها.
            ->whereIn('notification_id', Notification::query()
                ->select('id')
                ->where('type', $type)
                ->where('subject_type', $subjectType)
                ->where('subject_id', $subjectId))
            ->update(['read_at' => $now, 'updated_at' => $now]);
    }
}
