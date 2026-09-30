<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

final class OldPaymentsCannotBeImported extends DomainException
{
    public static function afterOpening(): self
    {
        return new self(
            'سُجِّل رصيد افتتاحي لحساب واحد على الأقل — المدفوعات القديمة داخلةٌ فيه، واستيرادها الآن '
            .'يحسبها مرتين. الاستيراد يسبق الافتتاح، ثم «جرد الحساب» لكل حساب.',
        );
    }
}
