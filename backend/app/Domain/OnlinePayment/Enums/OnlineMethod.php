<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Enums;

/**
 * A payment method EzonePay offers — its own numeric id, as `/LookUp/paymentMethods` lists it.
 *
 * **The ids come from Primula's merchant account** and are not contiguous. A merchant account may
 * differ: `ezone:smoke-test` prints what EzonePay lists for ours beside these, and a mismatch is a
 * change here and nothing else. Docs/payments/CUSTOMER-WALLET.md §٥.
 */
enum OnlineMethod: int
{
    case Moamalat = 101;
    case MobiCash = 102;
    case OnePay = 103;
    case MasrifiPay = 104;
    case YussorPay = 105;
    case EdfaLi = 106;
    case Sadad = 107;
    case SaharaPay = 108;
    case Libyana = 111;
    case OnePayQr = 123;
    case MasrifiPayQr = 124;
    case YussorPayQr = 125;
    case SaharaPayQr = 128;

    public function label(): string
    {
        return match ($this) {
            self::Moamalat => 'بطاقة مصرفية (معاملات)',
            self::MobiCash => 'موبي كاش',
            self::OnePay => 'ون باي',
            self::MasrifiPay => 'مصرفي باي',
            self::YussorPay => 'يسر باي',
            self::EdfaLi => 'ادفع لي',
            self::Sadad => 'سداد',
            self::SaharaPay => 'الصحارى باي',
            self::Libyana => 'رصيد ليبيانا',
            self::OnePayQr => 'ون باي — رمز QR',
            self::MasrifiPayQr => 'مصرفي باي — رمز QR',
            self::YussorPayQr => 'يسر باي — رمز QR',
            self::SaharaPayQr => 'الصحارى باي — رمز QR',
        };
    }

    /** The path segment of `/online-payment/{slug}/initiate` and `/scan`. */
    public function slug(): string
    {
        return match ($this) {
            self::Moamalat => 'moamalat',
            self::MobiCash => 'mobicash',
            self::OnePay => 'onepay',
            self::MasrifiPay => 'masrifipay',
            self::YussorPay => 'yussorpay',
            self::EdfaLi => 'edfali',
            self::Sadad => 'sadad',
            self::SaharaPay => 'saharapay',
            self::Libyana => 'libyana',
            self::OnePayQr => 'onepay-qr',
            self::MasrifiPayQr => 'masrifipay-qr',
            self::YussorPayQr => 'yussorpay-qr',
            self::SaharaPayQr => 'saharapay-qr',
        };
    }

    public function flow(): PaymentFlow
    {
        return match ($this) {
            self::Moamalat => PaymentFlow::Link,
            self::OnePayQr, self::MasrifiPayQr, self::YussorPayQr, self::SaharaPayQr => PaymentFlow::Qr,
            default => PaymentFlow::Otp,
        };
    }

    /** The customer's card or wallet number at the provider. */
    public function requiresCardNumber(): bool
    {
        return in_array($this, [self::MobiCash, self::OnePay, self::MasrifiPay, self::YussorPay, self::SaharaPay], true);
    }

    /** A phone number at the provider — Libyana's is the customer's own, filled in when absent. */
    public function requiresServiceMobileNumber(): bool
    {
        return in_array($this, [self::EdfaLi, self::Sadad, self::Libyana], true);
    }

    public function requiresBirthYear(): bool
    {
        return $this === self::Sadad;
    }
}
