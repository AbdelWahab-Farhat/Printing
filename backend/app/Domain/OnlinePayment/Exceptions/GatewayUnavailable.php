<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * The provider cannot be reached, or will not let us in — 503: try again later, nothing is wrong
 * with what the customer sent.
 */
final class GatewayUnavailable extends DomainException
{
    public static function make(): self
    {
        return new self('خدمة الدفع الإلكتروني لا تستجيب الآن — حاول بعد قليل');
    }

    public static function notConfigured(): self
    {
        return new self('الدفع الإلكتروني غير متاح حالياً');
    }

    public static function authFailed(): self
    {
        return new self('تعذّر الاتصال بخدمة الدفع الإلكتروني — حاول بعد قليل');
    }

    public function httpStatus(): int
    {
        return 503;
    }
}
