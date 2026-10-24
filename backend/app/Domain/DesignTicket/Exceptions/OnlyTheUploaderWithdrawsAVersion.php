<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * سحبُ نسخةٍ رفعها غيرُك. **يسحبها مَن رفعها وحده**: هو مَن يعرف أن الملفّ خطأ، ولا يُمحى عملُ
 * زميلٍ من طابور المراجعة بيد غيره.
 */
final class OnlyTheUploaderWithdrawsAVersion extends DomainException
{
    public static function make(): self
    {
        return new self('يسحب النسخةَ مَن رفعها وحده');
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
