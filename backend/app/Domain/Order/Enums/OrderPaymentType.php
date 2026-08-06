<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Order\Models\OrderPayment;

/**
 * What a row in the payment ledger *is*.
 *
 * **Three, not two, and the third is the point of the design.** Money coming in is one thing;
 * money going back out is two different things wearing the same sign. A clerk who typed 500
 * instead of 50 did not refund 450 — nothing left the drawer, and the entry describes an event
 * that never happened. Recording both as one type would make «كم رددنا للعملاء هذا الشهر؟»
 * unanswerable, because the answer would be inflated by every typo anyone ever corrected.
 *
 * {@see amount} is always positive on every one of the three. The direction lives here, exactly
 * as `MovementType` holds it for the stock ledger rather than letting a quantity go negative:
 * a signed column invites a sum that is right by accident and a filter that is wrong on purpose.
 *
 * @see OrderPayment
 */
enum OrderPaymentType: string
{
    /** The customer paid. The only type that increases what has been paid. */
    case Payment = 'payment';

    /** The entry was a mistake and describes nothing that happened. Points at the row it undoes. */
    case Reversal = 'reversal';

    /** Money genuinely went back to the customer. A cash event, unlike a reversal. */
    case Refund = 'refund';

    public function label(): string
    {
        return match ($this) {
            self::Payment => 'دفعة',
            self::Reversal => 'إلغاء دفعة',
            self::Refund => 'ردّ مبلغ',
        };
    }

    /** Whether this entry adds to what the order has been paid. */
    public function isIncoming(): bool
    {
        return $this === self::Payment;
    }

    /**
     * Whether this entry moved real money.
     *
     * A reversal did not — which is why a cash-drawer report reads this rather than counting
     * every row that is not a payment.
     */
    public function movedCash(): bool
    {
        return $this !== self::Reversal;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
