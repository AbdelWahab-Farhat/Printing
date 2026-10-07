<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * «اعتبار الزائد إيراداً» on an order that holds no excess — nothing was paid beyond it, or what
 * was has already been refunded or kept.
 */
final class NoExcessToKeep extends DomainException
{
    public static function make(): self
    {
        return new self('لا زائد على هذه الطلبية ليُعتبر إيراداً');
    }
}
