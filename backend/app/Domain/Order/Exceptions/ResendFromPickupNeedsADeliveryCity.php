<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Support\TransitionFields;
use App\Support\Exceptions\DomainException;

/**
 * «استلام مكتب» → «إعادة إرسال» with no delivery city, or with a branch.
 *
 * The request already insists on one; this is the same rule for callers that skip the request.
 * Without it the order would leave the counter still a pickup, and its next «out» would land it
 * straight back at the counter.
 */
final class ResendFromPickupNeedsADeliveryCity extends DomainException
{
    public static function make(): self
    {
        return new self('اختر مدينة توصيل لتحويل الطلبية من «استلام مكتب» إلى «إعادة إرسال»');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['fields.'.TransitionFields::DESTINATION => [$this->getMessage()]];
    }
}
