<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Order\Support\Money;

/**
 * Nawris's fee on one parcel and who pays it — the two facts that turn their door figure into ours.
 *
 * **This is the only place that knows what `shipment_on_sender` means.** Read from their webhooks,
 * not from their documentation, which nobody here has: we always send `0` at dispatch and every
 * parcel's history starts at `1`, and each flip to `2` moves the door amount by exactly that
 * parcel's fee. Nawris has been asked to confirm; a different answer is a change here and nowhere
 * else.
 *
 *     1  the customer pays the fee   door = ours + fee   ours = door − fee
 *     2  we pay the fee              door = ours         ours = door, and the fee is our cost
 *
 * With `2` Nawris keeps its fee out of what it transfers, so that fee is entered at «تم التسوية»
 * under «ما احتفظ به الناقل» — the webhook only says so.
 *
 * **Their API counts one lower**: we send `0` for the customer and `1` for us, and their webhooks
 * report those as `1` and `2`. {@see apiValueFor()} is the one place that crosses over.
 *
 * Anything that cannot be worked out answers null, and null means a person decides.
 */
final readonly class NawrisParcelTerms
{
    public const CUSTOMER_PAYS = 1;

    public const SENDER_PAYS = 2;

    /**
     * @param  bool  $cityChanged  An edit on their side moved the parcel to another city, so the
     *                             fee read before it no longer holds — and none is read after it.
     * @param  string|null  $feeBeforeMove  The fee from before that move — not used for money, only
     *                                      quoted to the person who enters the payment by hand.
     */
    public function __construct(
        public ?string $fee,
        public int $shipmentOnSender,
        public bool $cityChanged = false,
        public ?string $feeBeforeMove = null,
    ) {}

    /** The webhook value as their API takes it on an edit: `1` when we pay their fee, else `0`. */
    public static function apiValueFor(?int $webhookValue): int
    {
        return $webhookValue === self::SENDER_PAYS ? 1 : 0;
    }

    public function senderPays(): bool
    {
        return $this->shipmentOnSender === self::SENDER_PAYS;
    }

    /**
     * How much of what the courier took at the door is ours, never below zero — or null when
     * that cannot be told.
     */
    public function oursOf(string $door): ?string
    {
        $ours = match ($this->shipmentOnSender) {
            self::CUSTOMER_PAYS => $this->fee === null ? null : bcsub($door, $this->fee, Money::SCALE),
            self::SENDER_PAYS => $door,
            default => null,
        };

        if ($ours === null) {
            return null;
        }

        return bccomp($ours, '0', Money::SCALE) > 0 ? Money::round($ours) : '0.00';
    }
}
