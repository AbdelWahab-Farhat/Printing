<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * لا أحد يودع في محفظته أو يسحب منها أو يعدّلها، والمدير مستثنى — قرار صاحب العمل ٢٠٢٦-١١-٠٥.
 *
 * **٤٠٣ لا ٤٢٢**: الطلبُ سليم، ومن أرسله هو الذي لا يحقّ له — ولو ملك الصلاحية، لأن الصلاحية تعطيه
 * محافظ زملائه.
 */
final class OwnWalletRefused extends DomainException
{
    public static function make(): self
    {
        return new self('لا تحرّك محفظتك بنفسك — يسجّلها زميلٌ يملك الصلاحية');
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
