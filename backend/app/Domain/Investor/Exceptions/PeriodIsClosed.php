<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Domain\Investor\Queries\PeriodForEntry;
use App\Support\Exceptions\DomainException;

/**
 * لا يدخل صفٌّ فترةً أُقفلت.
 *
 * **لأن الإقفال إعلان.** الفترةُ المغلقة تحمل أرقامها مجمّدةً على صفّها، وقد خرج مالُها إلى
 * جيوب أصحابه بتلك الأرقام. صفٌّ يدخلها بعد ذلك يجعل الصفَّ يكذب على من قرأه، ولا سبيل إلى
 * استرجاع ما وُزّع.
 *
 * والتصحيحُ لا يُمنع — يقع على **الفترة المفتوحة اليوم**، وهو ما يفعله
 * {@see PeriodForEntry::floorOf()} تلقائياً في كل مسارٍ يكتب. فمن
 * يصل إلى هنا كتب الختمَ بيده متجاوزاً الحلّال: حارسٌ لمن يأتي بعدنا، لا رسالةٌ يراها مستخدم.
 */
final class PeriodIsClosed extends DomainException
{
    public static function make(string $code): self
    {
        return new self(
            "الفترة «{$code}» مغلقة وأرقامُها مُعلنة — التصحيحُ يُقيَّد في الفترة المفتوحة اليوم"
        );
    }
}
