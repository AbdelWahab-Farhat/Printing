<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A payment that was cancelled as a mistake has nothing left to check.
 *
 * The reversal already said the row describes nothing that happened, and the queue drops it the
 * moment it is reversed. Marking it reviewed afterwards would read as «checked, and right» on an
 * entry the ledger itself says was wrong.
 *
 * Only marking is refused. A review made *before* the reversal stays as it was — it was true when
 * it was given — and taking it back is still allowed.
 */
final class ReversedPaymentNeedsNoReview extends DomainException
{
    public static function make(): self
    {
        return new self('الدفعة ملغاة — لا شيء فيها يُراجع');
    }
}
