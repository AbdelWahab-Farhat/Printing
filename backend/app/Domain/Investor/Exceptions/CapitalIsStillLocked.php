<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * رأسُ مالٍ ما زال محبوساً لا يخرج.
 *
 * قرارُ المالك: «مدة حجز رأس المال بعد دخوله تبقى سنة كاملة لا يمكنك سحبه وهي نسبة متغيرة»،
 * و«كل deposit Timer خاص به لوحده ويجمد معه».
 *
 * **ولماذا الحبسُ أصلاً.** مالُ المستثمر ليس في درجٍ ينتظره: هو بضاعةٌ على رفٍّ وطلبياتٌ في
 * الطريق. سحبٌ مفاجئ يعني بيعاً مستعجلاً بخسارة يدفعها من بقي. فالمدةُ تجعل ما يُشترى به مالُه
 * قابلاً لأن يدور ويعود نقداً قبل أن يُطلب.
 *
 * والرسالةُ تقول **أقربَ يومٍ يُفرَج فيه عن شيء**، لا «ممنوع» وحدها: من أودع على دفعاتٍ تُفكّ
 * دفعةً دفعة، والسائلُ يريد أن يعرف متى.
 */
final class CapitalIsStillLocked extends DomainException
{
    public static function make(string $available, string $requested, ?string $nextRelease): self
    {
        $when = $nextRelease === null
            ? ''
            : "؛ أقربُ إفراجٍ في {$nextRelease}";

        return new self(
            "المتاحُ للسحب {$available} د.ل والمطلوب {$requested} د.ل — الباقي ما زال محبوساً بمدّته{$when}"
        );
    }
}
