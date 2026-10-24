<?php

declare(strict_types=1);

namespace App\Support\Media;

use InvalidArgumentException;

/**
 * ما في رسالة محادثةٍ بين الموظفين غير الكلام: صورة، أو رسالة صوتية. لا PDF ولا ملفات، كبريمولا
 * (السؤال ٢ في §١١ من INTERNAL-TICKETS-DESIGN، بافتراضه).
 *
 * **محادثتان على هذا الشيء الواحد**: التذاكر الداخلية، ومحادثة تذكرة التصميم
 * (DESIGN-TICKET-CHAT). كانت الثانية نصّاً فقط لأنها بُنيت قبله، والغايةُ من نقله إلى هنا أن ما
 * تقبله إحداهما تقبله الأخرى، بالحدود نفسها.
 *
 * **ومستقلٌّ عن `AttachmentKind` في الدعم** للسبب الذي جعل ذاك مستقلاً عن `DesignKind`: هناك PDF
 * وهنا صوت، والقائمتان مختلفتان أصلاً.
 */
enum ChatAttachmentKind: string
{
    case Image = 'image';
    case Voice = 'voice';

    /** الصور التي تقبلها المحادثة، بأنواعها المقروءة من البايتات. */
    public const IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

    /**
     * من نوع الملف **المقروء من بايتاته**، لا من ادّعاء الهاتف.
     *
     * **`video/mp4` صوتٌ هنا، وليس سهواً.** المسجّل يكتب AAC في حاوية MP4، وfinfo يسمّي تلك الحاوية
     * `audio/mp4` أو `audio/x-m4a` أو `video/mp4` بحسب العلامة التي كتبها الهاتف في رأسها — والعلامة
     * تختلف بين أندرويد وiOS. رفضُ الثالثة كان سيعني هاتفاً واحداً تُرفض رسائله ولا يعيد أحدٌ غيره
     * الخطأ. والملف لا يُعرض إلا مشغّلَ صوت من قرصٍ خاص، فلا يفتح القبولُ باباً.
     *
     * يرمي بدل أن يفترض، كنظيره في الدعم: التحقق رفض ما سوى هذا، والوصول إلى الاستثناء خطأٌ برمجيّ.
     */
    public static function fromMimeType(string $mimeType): self
    {
        if (in_array($mimeType, self::IMAGE_MIME_TYPES, true)) {
            return self::Image;
        }

        if (self::isVoiceMimeType($mimeType)) {
            return self::Voice;
        }

        throw new InvalidArgumentException("نوع ملف غير مدعوم: {$mimeType}");
    }

    public static function isVoiceMimeType(string $mimeType): bool
    {
        return str_starts_with($mimeType, 'audio/') || $mimeType === 'video/mp4';
    }

    public function label(): string
    {
        return match ($this) {
            self::Image => 'صورة',
            self::Voice => 'رسالة صوتية',
        };
    }

    /** سطرُ الرسالة التي لا كلام فيها، بعدد صورها: «صورة»، «صورتان»، «3 صور». */
    public static function imagesLabel(int $count): string
    {
        return match (true) {
            $count <= 1 => self::Image->label(),
            $count === 2 => 'صورتان',
            default => "{$count} صور",
        };
    }

    /** حدُّ الحجم بالكيلوبايت لهذا النوع — الصوت حدّه أصغر، والسبب في config/media.php. */
    public function maxKilobytes(): int
    {
        return match ($this) {
            self::Image => (int) config('media.chat_attachments.image_max_kilobytes'),
            self::Voice => (int) config('media.chat_attachments.voice_max_kilobytes'),
        };
    }
}
