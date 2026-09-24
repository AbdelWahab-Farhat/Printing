<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Undoing a delivery that Nawris itself reported.
 *
 * **Refused, because the carrier would put it straight back.** Its system says «تم التسليم» and
 * the money it collected is already recorded against the order; walking the order back here
 * contradicts both, and the next webhook would disagree with the order screen. A delivery the
 * carrier got wrong is corrected with the carrier, and comes back through it.
 */
final class DeliveryWasReportedByTheCarrier extends DomainException
{
    public static function make(string $parcelCode): self
    {
        return new self("سجّلت نورس هذا التسليم (الطرد {$parcelCode}) — يُصحَّح مع نورس لا من هنا");
    }
}
