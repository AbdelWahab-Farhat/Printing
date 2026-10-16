<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Our own reasons for not starting, or not finishing, an online top-up.
 */
final class OnlinePaymentRefused extends DomainException
{
    private string $field = 'method';

    public static function methodUnavailable(string $label): self
    {
        return self::on("«{$label}» غير متاحة الآن", 'method');
    }

    public static function fieldRequired(string $field, string $what): self
    {
        return self::on("{$what} مطلوب لهذه الطريقة", $field);
    }

    /** A limit the shop set on the method, with what is left of it. */
    public static function limitExceeded(string $period, string $limit, string $remaining): self
    {
        return self::on("تجاوز حدّ الشحن {$period} لهذه الطريقة ({$limit}) — المتبقي لك {$remaining}", 'amount');
    }

    public static function aboveProviderCap(string $largest): self
    {
        return self::on("أكبر مبلغٍ يُشحن بهذه الطريقة {$largest}", 'amount');
    }

    /** The least EzonePay lets this method charge — in what the customer pays, fee included. */
    public static function belowProviderMinimum(string $least): self
    {
        return self::on("أقل مبلغٍ يُدفع بهذه الطريقة {$least} د.ل", 'amount');
    }

    public static function notWaitingForOtp(): self
    {
        return self::on('هذه العملية لا تنتظر رمز تحقق', 'otp');
    }

    /** The code was taken and the money moved; EzonePay has not yet said so plainly. */
    public static function beingConfirmed(): self
    {
        return self::on('تم الدفع ونتحقق منه الآن — يصل الرصيد محفظتك خلال دقائق، لا ترسل الرمز مرة أخرى', 'otp');
    }

    public static function otpAttemptsExhausted(): self
    {
        return self::on('انتهت محاولات رمز التحقق — ابدأ الشحن من جديد', 'otp');
    }

    public static function notAnOrderOfYours(): self
    {
        return self::on('الطلبية غير موجودة', 'order_id');
    }

    private static function on(string $message, string $field): self
    {
        $exception = new self($message);
        $exception->field = $field;

        return $exception;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
