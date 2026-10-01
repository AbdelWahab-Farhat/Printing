<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * More came back than was missing, and the extra has not been accepted.
 *
 * **A surplus is allowed — on purpose, and only on purpose.** Buying a thirty-kilo sack against a
 * twenty-kilo shortage is ordinary, and the whole sack goes onto the shelf with the extra ten as
 * company stock — see `RecordShortageSupply`. What this refuses is the same number arriving
 * *without* the employee having said so, because the ordinary cause of a thirty against a
 * remainder of three is still a slipped keystroke while somebody is standing at the counter, and
 * the moment to catch it is then — the reason `PaymentExceedsRemaining` gives.
 *
 * And two cases where no confirmation helps: a shortage with no shelf behind it, where the extra
 * would have nowhere to go, and one with nothing left to supply at all.
 */
final class SupplyExceedsRemaining extends DomainException
{
    /** The extra was not confirmed. The message names it, so the screen can offer to send it. */
    public static function make(string $quantity, string $remaining): self
    {
        $surplus = bcsub($quantity, $remaining, 3);

        return new self(
            "الكمية ({$quantity}) أكبر من المتبقي من النقص ({$remaining}) — "
            ."أكّد إدخال الزائد ({$surplus}) للمخزن",
        );
    }

    /**
     * The extra has nowhere to go.
     *
     * A shortage written down for something the warehouse does not hold posts no stock, so the
     * part beyond the remainder would be money for goods recorded nowhere. See
     * `Shortage::isStockable()`.
     */
    public static function nothingToHoldTheSurplus(string $quantity, string $remaining): self
    {
        return new self(
            "الكمية ({$quantity}) أكبر من المتبقي من النقص ({$remaining}) — "
            .'وهذا النقص ليس صنفاً في المخزون ليُدخَل الزائد إليه',
        );
    }

    /**
     * Nothing is missing any more, so none of it would count.
     *
     * Reachable only on a shortage the totals have met but a person has not closed — «مكتمل» is
     * refused earlier, by `ShortageIsClosed`. An arrival here would be all surplus, and a whole
     * purchase for the shelf belongs on a purchase order.
     */
    public static function nothingRemains(): self
    {
        return new self('لم يتبقَّ شيء من هذا النقص — سجّل الشراء على أمر شراء');
    }

    /**
     * The requirement being cut below what has already come back.
     *
     * The same rule read from the other end, and it needs its own sentence: «الكمية أكبر من
     * المتبقي» said about a *requirement* names the wrong number as the mistake and points at the
     * wrong field. Correcting a shortage of thirty down to ten after twenty have been bought is
     * refused because the twenty happened — the way down is to reverse the purchase.
     */
    public static function belowWhatIsSupplied(string $required, string $supplied): self
    {
        return new self(
            "الكمية المطلوبة ({$required}) أقل مما تم توفيره فعلاً ({$supplied}) — "
            .'اعكس عملية التوفير أولاً',
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['quantity' => [$this->getMessage()]];
    }
}
