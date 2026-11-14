<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A compensation order owes nothing, so a discount on it means nothing and an additional cost
 * would contradict it. Refused rather than ignored, so the screen never shows a number that the
 * total quietly dropped.
 */
final class CompensationTakesNoCharges extends DomainException
{
    private string $field = 'discount';

    public static function discount(): self
    {
        $exception = new self('طلبية التعويض لا تأخذ خصماً — الزبون لا يدفع شيئاً أصلاً');
        $exception->field = 'discount';

        return $exception;
    }

    public static function additionalCost(): self
    {
        $exception = new self('طلبية التعويض لا تأخذ تكلفة إضافية — الزبون لا يدفع شيئاً');
        $exception->field = 'additional_cost';

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
