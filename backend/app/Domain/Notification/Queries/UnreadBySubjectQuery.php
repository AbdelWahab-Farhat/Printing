<?php

declare(strict_types=1);

namespace App\Domain\Notification\Queries;

use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\NotificationRecipient;

/**
 * كم بقي لهذا القارئ غيرَ مقروءٍ عن سجلٍّ بعينه.
 *
 * **شارةُ المحادثة لا تحتاج جدولاً جديداً، لأن الجواب مكتوبٌ أصلاً.** كلُّ تعليقٍ يُنشئ صفَّ
 * إشعارٍ واحداً — مفتاحُ منع التكرار معرِّفُ التعليق — و`notification_recipients` تحمل `read_at`
 * لكلِّ شخصٍ على حدة. فالعدُّ استعلام، وحالةُ «قرأتُ الخيط» هي نفسها حالةُ «قرأتُ الجرس»: مَن فتح
 * المحادثة أطفأ خبرَها في الجرس أيضاً، وهو ما ينتظره المستخدم لا ما يفاجئه.
 *
 * **والبديل — جدولُ `last_read_at` لكلِّ خيط — يُشعل كلَّ تذكرةٍ قديمة يوم النشر**، لأن «لا صفَّ»
 * تعني «لم يُقرأ قطّ»، فيلزمه ترحيلُ تعبئةٍ لا يلزم هذا.
 *
 * **الجمعُ هو التابع الوحيد، والمفردُ حالةٌ منه.** صفحةُ التذاكر تحتاج عدّاً لكلِّ صفّ، واستعلامٌ
 * لكلِّ صفّ هو N+1 بعينه — وهو عيبٌ لا ذوق (RULES §3). فاستعلامٌ واحدٌ مجموعٌ للصفحة كلّها، ثم
 * `forSubject()` تسأله عن معرِّفٍ واحد.
 *
 * ولا يعرف هذا الصنف شيئاً عن تذاكر التصميم: يأخذ الاسمَ المستعار والنوعَ، فيخدم ملاحظاتِ العميل
 * يوم تريد شارةً دون سطرٍ جديد هنا.
 */
final readonly class UnreadBySubjectQuery
{
    /**
     * @param  list<int>  $subjectIds
     * @return array<int, int> معرِّفُ السجلّ ← العدد، وما لا شيء فيه لا مفتاح له
     */
    public function forSubjects(
        string $subjectType,
        array $subjectIds,
        int $userId,
        NotificationType $type,
    ): array {
        if ($subjectIds === []) {
            return [];
        }

        /** @var array<int, int> $counts */
        $counts = NotificationRecipient::query()
            ->join('notifications', 'notifications.id', '=', 'notification_recipients.notification_id')
            ->where('notification_recipients.user_id', $userId)
            ->whereNull('notification_recipients.read_at')
            ->where('notifications.type', $type->value)
            ->where('notifications.subject_type', $subjectType)
            ->whereIn('notifications.subject_id', $subjectIds)
            ->groupBy('notifications.subject_id')
            ->selectRaw('notifications.subject_id as subject_id, count(*) as total')
            ->pluck('total', 'subject_id')
            ->map(fn ($total): int => (int) $total)
            ->all();

        return $counts;
    }

    public function forSubject(string $subjectType, int $subjectId, int $userId, NotificationType $type): int
    {
        return $this->forSubjects($subjectType, [$subjectId], $userId, $type)[$subjectId] ?? 0;
    }
}
