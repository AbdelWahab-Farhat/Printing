<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/** أجرٌ يكتبه مَن لا يملكه. انظر `DesignTicket::mayWritePay()`. */
final class DesignTicketPayIsNotYours extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكنك تعديل أجر هذه التذكرة');
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
