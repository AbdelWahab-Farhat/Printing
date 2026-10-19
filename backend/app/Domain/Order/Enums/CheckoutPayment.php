<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * How a customer says, in the basket, they will pay the عربون — see `PlaceOrderWithDeposit`.
 *
 * **Two answers, and online money is not a third.** Online money always passes through the wallet
 * (owner, 2026-10-11 — CUSTOMER-WALLET §٢), and the owner asked (2026-10-19) that an online
 * payment succeed *before* the order exists: the app tops the wallet up with the deposit first,
 * and only then places the order — as a wallet payment. So the server never holds an order
 * waiting on a top-up that may not come.
 */
enum CheckoutPayment: string
{
    /** Paid at the counter. The order waits in «انتظار العربون» until staff take it. */
    case Office = 'office';

    /** Paid from the wallet now, in the same transaction that writes the order. */
    case Wallet = 'wallet';

    /** What the order records as the way its عربون is expected — `deposit_expected_method`. */
    public function expectedMethod(): PaymentMethod
    {
        return $this === self::Office ? PaymentMethod::Cash : PaymentMethod::Wallet;
    }

    public function label(): string
    {
        return match ($this) {
            self::Office => 'في المكتب',
            self::Wallet => 'من المحفظة',
        };
    }
}
