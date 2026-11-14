<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * The original order a compensation names must be this customer's, and must not itself be a
 * compensation order — a replacement of a replacement points at the wrong mistake.
 */
final class CompensatedOrderIsInvalid extends DomainException
{
    public static function otherCustomer(): self
    {
        return new self('الطلبية الأصلية ليست لنفس الزبون');
    }

    public static function isCompensation(): self
    {
        return new self('الطلبية الأصلية نفسها طلبية تعويض — اختر الطلبية التي وقع فيها الخطأ');
    }

    public static function hasCompensations(): self
    {
        $exception = new self('هذه الطلبية عُوِّضت بطلبيةٍ أخرى — لا تصير هي طلبية تعويض');
        $exception->field = 'is_compensation';

        return $exception;
    }

    public static function itself(): self
    {
        return new self('لا يمكن أن تعوّض الطلبية نفسها');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }

    private string $field = 'compensates_order_id';
}
