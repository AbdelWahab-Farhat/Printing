<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * لا تُقفَل فترةٌ ونافذتُها ما زالت تستقبل.
 *
 * **لأن الطلبية تخصّ فترةَ تاريخها.** فترةٌ نافذتُها إلى ١٤ أكتوبر تُقفَل في ٢ منه تترك اثني
 * عشر يوماً تقع طلبياتُها داخل نافذةٍ **مغلقة**: يأتي ربحُها فلا يجد فترةً مفتوحةً تقع فيها،
 * ولا فترةً مغلقةً يجوز أن يدخلها. فالإقفالُ المبكّر ثقبٌ في الزمن لا تعجيلُ عمل.
 *
 * ويبقى بابُ التجاوز مفتوحاً بسببٍ يُكتب — لمن يقرّر إنهاء دورةٍ مبكراً وهو يعلم ما يفعل.
 */
final class PeriodHasNotEndedYet extends DomainException
{
    public static function make(string $code, string $endsOn): self
    {
        return new self(
            "الفترة «{$code}» نافذتُها إلى {$endsOn} وما زالت تستقبل — تُقفَل بعدها، أو بتجاوزٍ مُسبَّب"
        );
    }
}
