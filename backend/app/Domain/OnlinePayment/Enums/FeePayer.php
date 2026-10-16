<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Enums;

/**
 * «العمولة على» — who carries EzonePay's fee. The customer by default (the owner, 2026-10-11).
 * Either way the fee is recorded, as an expense out of «Ezone».
 */
enum FeePayer: string
{
    /** The customer is charged the top-up and its fee; the wallet receives the top-up. */
    case Customer = 'customer';

    /** The customer is charged the top-up alone; the shop absorbs the fee. */
    case Shop = 'shop';

    public function label(): string
    {
        return match ($this) {
            self::Customer => 'على الزبون',
            self::Shop => 'على المحلّ',
        };
    }
}
