<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * مَن يرى التذكرة وليس طرفاً فيها — المدير — حاول أن يكتب فيها أو يغلقها أو يحوّلها بما لا يملك.
 *
 * **٤٠٣ لا ٤٠٤**: هذا يراها، فإخفاؤها عنه بعد أن قرأها كذب. وزميلٌ ثالث لا يراها أصلاً لا يصل
 * إلى هنا — الرؤية تُسأل قبل هذا وجوابها ٤٠٤.
 */
final class NotPartyToInternalTicket extends DomainException
{
    public static function make(string $message = 'لست طرفاً في هذه التذكرة'): self
    {
        return new self($message);
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
