<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A delivery city typed onto an order waiting at the counter by somebody who may not move orders
 * to «إعادة إرسال».
 *
 * The edit moves the order there itself (see UpdateOrder::moveToResend()), so it costs the
 * permission that move costs on top of the edit's own. Pinned to the city field, because that is
 * the change the form has to take back.
 */
final class PickupBecomesDeliveryThroughResend extends DomainException
{
    public static function make(): self
    {
        return new self('تحويل طلبية «استلام مكتب» إلى توصيل ينقلها إلى «إعادة إرسال»، وليست لديك صلاحية هذه الحالة');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['city_id' => [$this->getMessage()]];
    }
}
