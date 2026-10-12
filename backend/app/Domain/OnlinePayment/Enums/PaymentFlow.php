<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Enums;

/**
 * How a method is paid. Docs/payments/CUSTOMER-WALLET.md §٥.
 *
 * - `otp`: the server starts the payment, the provider texts the customer a code, the app sends it.
 * - `qr`: the customer scans the provider's code; one request starts and finishes it.
 * - `link`: a hosted page (bank cards); the app opens it and polls, the webhook confirms.
 */
enum PaymentFlow: string
{
    case Otp = 'otp';
    case Qr = 'qr';
    case Link = 'link';

    public function label(): string
    {
        return match ($this) {
            self::Otp => 'رمز تحقق',
            self::Qr => 'رمز QR',
            self::Link => 'رابط دفع',
        };
    }
}
