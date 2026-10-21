<?php

declare(strict_types=1);

namespace App\Application\Rules;

use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Http\UploadedFile;

/**
 * مرفقُ تذكرةٍ داخلية: صورة، أو رسالة صوتية — كقاعدة `TicketAttachmentFile` في بريمولا.
 *
 * **قاعدةٌ لا `mimes:` و`max:`**، لأن للنوعين حدّين مختلفين (config/media.php)، و`max:` واحدةٌ لا
 * تقول ذلك. **والنوعُ هو المقروء من البايتات** (`getMimeType()` بـfinfo)، لا ما ادّعاه الهاتف — فليس
 * فحصُ «audio/» شكلياً. ولماذا يُقبل `video/mp4` صوتاً: {@see InternalAttachmentKind::fromMimeType()}.
 */
final class InternalTicketAttachmentFile implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // `file` يملك حالة «هذا ليس ملفاً أصلاً» ورسالتها.
        if (! $value instanceof UploadedFile) {
            return;
        }

        $mimeType = (string) $value->getMimeType();

        $kind = match (true) {
            in_array($mimeType, InternalAttachmentKind::IMAGE_MIME_TYPES, true) => InternalAttachmentKind::Image,
            InternalAttachmentKind::isVoiceMimeType($mimeType) => InternalAttachmentKind::Voice,
            default => null,
        };

        if ($kind === null) {
            $fail('المرفق يجب أن يكون صورة (JPG أو PNG أو WEBP) أو رسالة صوتية');

            return;
        }

        if ($value->getSize() / 1024 > $kind->maxKilobytes()) {
            $fail(sprintf(
                '%s لا يمكن أن تتجاوز %s ميغابايت',
                $kind === InternalAttachmentKind::Image ? 'الصورة' : 'الرسالة الصوتية',
                (int) ($kind->maxKilobytes() / 1024),
            ));
        }
    }
}
