<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * لا تُفتح فترةٌ وأخرى قائمة.
 *
 * **حارسٌ في الفعل فوق فهرسٍ في القاعدة.** الفهرس يمنع الصفَّ الثاني مهما كان الطريق؛ وهذا
 * يُخرج رسالةً عربيةً يقرأها من ضغط الزرّ بدل خطأ فهرسٍ بخمسمئة.
 */
final class APeriodIsAlreadyOpen extends DomainException
{
    public static function make(string $code): self
    {
        return new self("الفترة «{$code}» ما زالت مفتوحة — تُقفَل قبل أن تُفتح غيرها");
    }
}
