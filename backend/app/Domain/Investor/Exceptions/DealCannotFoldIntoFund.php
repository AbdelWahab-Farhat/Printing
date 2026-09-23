<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * صفقةٌ لا تدخل الصندوق — والسببُ بلفظه، لأن من يشغّل التحويل يقرّر بعده ماذا يفعل.
 */
final class DealCannotFoldIntoFund extends DomainException
{
    public static function isTheFund(): self
    {
        return new self('الصندوقُ لا يدخل نفسَه — التحويلُ لصفقةٍ قديمة وحدها');
    }

    public static function notOpen(string $code, string $status): self
    {
        return new self("الصفقة {$code} «{$status}» — التحويلُ لصفقةٍ مفتوحة");
    }

    public static function noPeriodTakesCapital(): self
    {
        return new self('لا فترةَ مفتوحةٌ تقبل رأسَ مالٍ اليوم — يُحوَّل في نافذة اكتتاب');
    }

    public static function nobodyToFold(string $code): self
    {
        return new self("الصفقة {$code} بلا شركاء لهم رأسُ مالٍ فيها — لا شيءَ يُحوَّل");
    }

    /**
     * §١٣أ: الشريكُ يشتري حصّةَ الشركة من البضاعة بنقده المحقَّق — فإن لم يكفِ فلا تحويل.
     */
    public static function cashCannotBuyTheCompanyShare(string $code, string $name, string $short): self
    {
        return new self(
            "الصفقة {$code}: نقدُ {$name} المحقَّق لا يكفي لشراء حصة الشركة من البضاعة على الرفّ — ينقصه {$short} د.ل"
        );
    }
}
