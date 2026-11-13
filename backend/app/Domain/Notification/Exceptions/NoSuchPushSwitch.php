<?php

declare(strict_types=1);

namespace App\Domain\Notification\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A push switch that does not exist: a type addressed to one person, which always pushes, or a
 * status that never rings.
 *
 * Refused rather than stored, because a stored row for a switch nobody can see is a setting
 * nobody can ever turn back.
 */
final class NoSuchPushSwitch extends DomainException
{
    public static function make(): self
    {
        return new self('لا يمكن إيقاف هذا الإشعار على الهاتف');
    }

    public function httpStatus(): int
    {
        return 422;
    }
}
