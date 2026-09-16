<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Nothing can be recorded as arriving until somebody says how much is owed.
 *
 * **Because pieces cannot be turned into kilograms, and this is where that bites.** A shortage on
 * a size the warehouse weighs is declared in the unit the customer was billed in — «ناقص ٣٠
 * قطعة» — because the bags are missing and there is nothing to put on a scale. The purchase that
 * covers it is made in the shelf's unit, because that is what the supplier sells and what the
 * warehouse receives. Subtracting the second from the first is not arithmetic anybody can do:
 * bags weighed together have no per-bag weight, which is why `DeductOrderStock` refuses to
 * multiply a factor out and why `order_items.warehouse_quantity` is read off a scale.
 *
 * **So the requirement is settled first, and only then may anything be recorded against it.**
 * Allowing the purchase anyway would leave «المتبقي ٣٠ ناقص ١٢٫٥» on the screen — a number in no
 * unit at all — and the order's invoice would be credited from it.
 *
 * The weight is stated from this screen — «حدِّد الكمية من المخزن» — or from the order, whichever
 * the person is looking at. Whoever is holding the goods knows it; whoever declared the shortage
 * could not have. See `SetShortageWarehouseQuantity`.
 */
final class ShortageWeightIsUnknown extends DomainException
{
    public static function make(string $stockUnitLabel, string $billingUnitLabel): self
    {
        return new self(
            "هذا النقص مُسجَّل بـ«{$billingUnitLabel}» ويُشترى بـ«{$stockUnitLabel}» — "
            .'حدِّد الكمية الناقصة من المخزن أولاً'
        );
    }

    /**
     * Named on the quantity, which is the box the employee is standing in front of.
     *
     * The fix is not in this form — it is on the order screen — so the message says where to go
     * rather than leaving a required field nobody can fill from here.
     *
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['quantity' => [$this->getMessage()]];
    }
}
