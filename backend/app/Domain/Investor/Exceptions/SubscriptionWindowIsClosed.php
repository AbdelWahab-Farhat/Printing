<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * مالٌ وصل بعد أن أُغلقت نافذةُ الاكتتاب.
 *
 * قرارُ المالك: «يمكنه فقط في بداية الفترة اول اسبوع او اول يوم مدة يحددها المدير». والسببُ أن
 * نسبَ الفترة تُلتقط لحظةَ إغلاق النافذة: مالٌ يدخل بعدها كان سيغيّر قسمةَ شهرٍ نصفُه قد مضى،
 * فيُقسَّم ربحُ طلبيةٍ من أوّله بنسب آخره.
 *
 * **وهو تأجيلٌ لا رفض** — يُقبل المالُ في الفترة التالية، والرسالةُ تقول متى تفتح.
 */
final class SubscriptionWindowIsClosed extends DomainException
{
    public static function make(string $code, string $closedOn, string $nextOpensOn): self
    {
        return new self(
            "نافذةُ الاكتتاب في الفترة «{$code}» أُغلقت يوم {$closedOn} — يُقبل رأسُ المال من {$nextOpensOn}"
        );
    }
}
