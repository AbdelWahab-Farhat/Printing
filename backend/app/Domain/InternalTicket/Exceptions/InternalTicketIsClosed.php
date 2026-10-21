<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * كتابةٌ في تذكرةٍ داخلية أُغلقت — أو تحويلها.
 *
 * **والإغلاق نهائيّ، كبريمولا**: لا إعادة فتح هنا كالتي في الدعم. مَن عنده ما يضيفه يفتح تذكرةً
 * جديدة، فتبقى المغلقة سجلّاً لما اتُّفق عليه.
 */
final class InternalTicketIsClosed extends DomainException
{
    public static function make(): self
    {
        return new self('التذكرة مغلقة. افتح تذكرة جديدة لتكمل');
    }
}
