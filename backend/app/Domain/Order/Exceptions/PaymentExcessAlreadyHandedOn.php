<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A payment cannot be undone once the excess it carried has gone somewhere.
 *
 * The excess was handed back as a refund, or kept as the shop's. Reversing the payment would take
 * that excess off the order a second time, leaving the customer owed less than nothing and the
 * treasury's «علينا» below zero. A kept excess is undone first, by reversing the «اعتبار الزائد
 * إيراداً» entry; a refund is cash that genuinely left, and stays.
 */
final class PaymentExcessAlreadyHandedOn extends DomainException
{
    public static function make(): self
    {
        return new self('زائد هذه الدفعة رُدّ للزبون أو اعتُبر إيراداً — ألغِ «اعتبار الزائد إيراداً» أولاً، أو سجّل التصحيح بدفعة');
    }
}
