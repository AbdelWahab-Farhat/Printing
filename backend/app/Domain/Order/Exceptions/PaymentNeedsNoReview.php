<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An entry nobody was asked to check.
 *
 * Two kinds of row: a reversal, a write-off or a carrier settlement, none of which moved cash of
 * ours, and every payment taken before reviews existed, which the owner exempted. Neither has
 * `requires_review`, and a stamp on one would be a review of nothing — the database's CHECK
 * refuses it too; this is the readable 422 in front of it.
 */
final class PaymentNeedsNoReview extends DomainException
{
    public static function make(): self
    {
        return new self('هذا القيد لا يحتاج مراجعة');
    }
}
