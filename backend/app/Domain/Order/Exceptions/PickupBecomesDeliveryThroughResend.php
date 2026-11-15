<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A delivery city typed onto an order waiting at the counter.
 *
 * The edit would leave the order saying «استلام مكتب» about a parcel that is to be delivered,
 * and that status leads nowhere a delivery can go. The move into «إعادة إرسال» asks for the city
 * and writes both together, so the refusal names it.
 */
final class PickupBecomesDeliveryThroughResend extends DomainException
{
    public static function make(): self
    {
        return new self('لتحويل طلبية «استلام مكتب» إلى توصيل انقلها إلى «إعادة إرسال» واختر مدينة التوصيل هناك');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['city_id' => [$this->getMessage()]];
    }
}
