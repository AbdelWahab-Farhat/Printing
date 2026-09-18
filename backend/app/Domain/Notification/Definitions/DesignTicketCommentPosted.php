<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * كُتب ردٌّ داخل تذكرة تصميم، والطرفُ الآخر لم يره بعد.
 *
 * **الجمهورُ هو الطرفان دائماً، ولا فرعَ هنا يسأل أيُّهما كتب.** يكفي أن يُقال «هذان اثنان» وأن
 * يتكفّل `ResolveRecipients` بإخراج الكاتب منهما — فيصح الحكمُ في الحالات الثلاث بجملةٍ واحدة:
 * كتب الطالبُ فيسمع المصمّم، وكتب المصمّمُ فيسمع الطالب، وكتب مديرٌ يرى التذاكر كلَّها فيسمعان
 * معاً. والبديلُ — أن نسأل «مَن الكاتب؟» ونردّ بـ`user()` واحدة — يكتب الفرعَ الثالث خطأً أو
 * يُسقطه صامتاً.
 *
 * **وتذكرةٌ لم يأخذها أحدٌ بعد جمهورُها الطالبُ وحده، وهو الكاتب، فلا يسمعها أحد.** وهذه نتيجةٌ
 * مقصودة لا ثغرة: تذكرةٌ في الصفّ المشترك ليست محادثةً بعدُ، وإيقاظُ كلِّ مصمّمٍ لأجل سطرٍ أضافه
 * الطالبُ إلى طلبه يعلّم المصمّمين أن يتجاوزوا الجرس. ولو أُريد غيرُ ذلك يوماً فهو فرعٌ واحد
 * هنا — `designer_id === null ? permission(PermissionName::AcceptDesignTickets) : users([...])` —
 * على شكل {@see DesignTicketAssignedToYou} نفسه، بلا ترحيلٍ ولا نسخةِ تطبيق.
 *
 * **ونصُّ التعليق لا يُذكر في الجملة.** `render()` واحدةٌ تخدم البريدَ الداخلي والدفعَ معاً، والدفعُ
 * يُقرأ على شاشةٍ مقفلة — §٦٫٤ من وثيقة الإشعارات. فما يُقال هو أنّ هناك ردّاً وعلى أيِّ تذكرة،
 * والردُّ نفسه على بعد نقرة.
 */
final readonly class DesignTicketCommentPosted implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        // `array_filter` تُسقط الصفر، وهو ما يصير إليه المصمّمُ الغائب أو الطالبُ الذي حُذف
        // حسابه. وقائمةٌ فارغة جمهورٌ فارغ — يُكتب صفُّ الإشعار ولا يُبلَّغ أحد، وهي النتيجة
        // العاديّة التي بُني عليها `PublishNotification`.
        return NotificationAudience::users(array_values(array_filter([
            (int) ($payload['requester_id'] ?? 0),
            (int) ($payload['designer_id'] ?? 0),
        ])));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $title = (string) ($payload['title'] ?? '');
        $code = (string) ($payload['code'] ?? '');

        return new RenderedNotification(
            title: 'ردٌّ جديد على تذكرة التصميم',
            // عنوانُ التذكرة لا اسمُ العميل ولا نصُّ الردّ: ما يكفي القارئَ ليعرف أهذه التذكرةُ
            // التي ينتظرها. و«تذكرة {code}» حين لا عنوان، لأن الجملة يجب أن تبقى جملة.
            body: $title !== '' ? $title : "تذكرة {$code}",
            // إلى المحادثة مباشرةً لا إلى رأس التذكرة: الخبرُ ردٌّ، والوجهةُ هي المكان الذي
            // يُقرأ فيه. والمسارُ مسجَّلٌ في التطبيق أصلاً، فلا يحتاج هذا النوعُ نسخةً جديدة.
            route: '/design-tickets/'.($payload['ticket_id'] ?? '').'/comments',
        );
    }

    /**
     * مَن كتب الردَّ قرأه وهو يكتبه.
     *
     * **وهي حاملةٌ هنا لا مجرّد ترتيب**: الجمهورُ الطرفان معاً، وهذه وحدها هي التي تُبقي الكاتبَ
     * خارجَ بريده حين يكون أحدَهما — وهو الحالُ في كلِّ ردٍّ إلا ردَّ ثالثٍ من خارجهما.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
