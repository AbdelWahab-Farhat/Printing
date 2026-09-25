<?php

declare(strict_types=1);

namespace App\Domain\Support\Enums;

use InvalidArgumentException;

/**
 * أيُّ ملفٍّ في رسالة الدعم — وهو ما يقرّر هل يرسمه التطبيق داخل المحادثة أم يسلّمه لعارض الهاتف.
 *
 * **مستقلٌّ عن `DesignKind` وإن تشابها.** ذاك في سياق العملاء ويصف تصميماً يُطبع، وهذا في سياق
 * الدعم ويصف ما قيل في محادثة؛ استيرادُ أحدهما في الآخر كان سيربط سياقين لا يعرف أحدهما الآخر،
 * ليوفّر أربعة أسطر.
 */
enum AttachmentKind: string
{
    case Image = 'image';
    case Pdf = 'pdf';

    /**
     * من نوع الملف **المقروء من بايتاته**، لا من ادّعاء العميل.
     *
     * يرمي بدل أن يفترض: التحقق رفض كل ما سوى هذه الأربعة، فالوصول إلى الاستثناء يعني أن التحقق
     * وهذا الملف افترقا — وخطأُ ٥٠٠ هنا أصدق من ملفٍّ مجهول يُرسم صورةً على هاتف أحد.
     */
    public static function fromMimeType(string $mimeType): self
    {
        return match ($mimeType) {
            'application/pdf' => self::Pdf,
            'image/jpeg', 'image/png', 'image/webp' => self::Image,
            default => throw new InvalidArgumentException("نوع ملف غير مدعوم: {$mimeType}"),
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::Image => 'صورة',
            self::Pdf => 'PDF',
        };
    }
}
