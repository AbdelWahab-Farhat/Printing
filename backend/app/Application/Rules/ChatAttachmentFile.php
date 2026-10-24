<?php

declare(strict_types=1);

namespace App\Application\Rules;

use App\Support\Media\ChatAttachmentKind;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Http\UploadedFile;

/**
 * مرفقُ رسالةٍ في محادثة الموظفين — تذكرةٌ داخلية أو تذكرةُ تصميم: صورة، أو رسالة صوتية. كقاعدة
 * `TicketAttachmentFile` في بريمولا.
 *
 * **قاعدةٌ لا `mimes:` و`max:`**، لأن للنوعين حدّين مختلفين (config/media.php)، و`max:` واحدةٌ لا
 * تقول ذلك. **والنوعُ هو المقروء من البايتات** (`getMimeType()` بـfinfo)، لا ما ادّعاه الهاتف — فليس
 * فحصُ «audio/» شكلياً. ولماذا يُقبل `video/mp4` صوتاً: {@see ChatAttachmentKind::fromMimeType()}.
 *
 * **[imagesOnly] لصور الألبوم** (`files.*`): الألبومُ صورٌ وحدها، كبريمولا، والصوتُ رسالةٌ وحده.
 */
final class ChatAttachmentFile implements ValidationRule
{
    public function __construct(private readonly bool $imagesOnly = false) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // `file` يملك حالة «هذا ليس ملفاً أصلاً» ورسالتها.
        if (! $value instanceof UploadedFile) {
            return;
        }

        $mimeType = (string) $value->getMimeType();

        $kind = match (true) {
            in_array($mimeType, ChatAttachmentKind::IMAGE_MIME_TYPES, true) => ChatAttachmentKind::Image,
            ChatAttachmentKind::isVoiceMimeType($mimeType) => ChatAttachmentKind::Voice,
            default => null,
        };

        if ($this->imagesOnly && $kind !== ChatAttachmentKind::Image) {
            $fail('الصورة يجب أن تكون JPG أو PNG أو WEBP');

            return;
        }

        if ($kind === null) {
            $fail('المرفق يجب أن يكون صورة (JPG أو PNG أو WEBP) أو رسالة صوتية');

            return;
        }

        if ($value->getSize() / 1024 > $kind->maxKilobytes()) {
            $fail(sprintf(
                '%s لا يمكن أن تتجاوز %s ميغابايت',
                $kind === ChatAttachmentKind::Image ? 'الصورة' : 'الرسالة الصوتية',
                (int) ($kind->maxKilobytes() / 1024),
            ));
        }
    }
}
