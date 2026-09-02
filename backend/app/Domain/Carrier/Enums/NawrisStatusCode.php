<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Enums;

use App\Domain\Order\Enums\OrderStatus;

/**
 * The nine codes Nawris sends that mean something to us, and what each one means.
 *
 * **This enum is the blast radius.** `OrderStatus::permission()` is enforced in a FormRequest, so
 * it guards the HTTP route and not the action — and the webhook job calls `ChangeOrderStatus`
 * directly, with no permission check on that path at all. That is the right architecture (the
 * domain does not know about permissions) but it means the map below is the only thing deciding
 * what an unauthenticated POST can do to an order. **Adding a case here is a security change, not
 * configuration.**
 *
 * **Anything not listed changes no state.** An unmapped code updates the stored raw label and is
 * logged, which is the only safe default: a carrier that invents a code must never have it
 * guessed at. The contract is explicit that unmapped codes exist and their meanings are unknown.
 *
 * Codes 6 and 12 were a bug in the system this was compiled from — they fell through as unmapped,
 * so an order that had reported "delivered" stayed delivered forever while the goods sat back in
 * the warehouse. We have exact statuses for both.
 */
enum NawrisStatusCode: int
{
    /** Out with the courier. Usually a no-op — the order is already there. */
    case OutForDelivery = 3;

    /**
     * Meaningless on its own.
     *
     * **Only ever read together with `return_reason`**, and ignored entirely without one. Straight
     * from the contract, and the one code whose meaning depends on another field.
     */
    case Ambiguous = 4;

    /**
     * Delivery cancelled.
     *
     * **Mapped to «راجع لدى المندوب», not to «إلغاء تام»**, and that is a deliberate reading. Our
     * machine refuses to write an order off while it is physically outside the building — the
     * parcel is with the courier and is coming back, which is what this status says. The carrier's
     * own label is stored verbatim beside it either way.
     */
    case DeliveryCancelled = 5;

    /** The return reached their branch and came back to us. */
    case ReturnReceived = 6;

    /** Delivered, and the money collected. The only code that writes to the ledger. */
    case Delivered = 7;

    /** A return went out again. */
    case ReturnSentAgain = 10;

    /** The return was written off. Terminal. */
    case ReturnWrittenOff = 12;

    /** On its way back, still with the courier. */
    case ComingBack = 15;

    /** Sitting at the carrier's branch. */
    case ReturnAtBranch = 19;

    /**
     * Which of our statuses this code asks for, or null when it asks for nothing.
     *
     * **Asking for a status is not the same as getting it.** `ApplyNawrisStatus` still checks
     * `OrderStatus::canMoveTo()` from wherever the order actually is, and parks the event when the
     * move is not legal — our return chain is walked one link at a time on purpose, and Nawris
     * does not walk it. See NAWRIS-INTEGRATION.md §3.2.
     *
     * `$hasReturnReason` exists solely for code 4.
     */
    public function target(bool $hasReturnReason = false): ?OrderStatus
    {
        return match ($this) {
            self::OutForDelivery => OrderStatus::OutForDelivery,

            // Read as a return only when a reason came with it; otherwise it says nothing.
            self::Ambiguous => $hasReturnReason ? OrderStatus::ReturnedCourier : null,

            self::DeliveryCancelled, self::ComingBack => OrderStatus::ReturnedCourier,
            self::ReturnAtBranch => OrderStatus::ReturnedCarrier,
            self::ReturnReceived => OrderStatus::ReturnedOffice,
            self::Delivered => OrderStatus::Delivered,
            self::ReturnSentAgain => OrderStatus::Resend,
            self::ReturnWrittenOff => OrderStatus::Cancelled,
        };
    }

    /**
     * Whether this code ends the parcel's journey.
     *
     * Stamps `closed_at`, which is what makes "still out there" a query rather than a list of
     * statuses somebody has to keep in step.
     */
    public function closesTheParcel(): bool
    {
        return $this === self::Delivered
            || $this === self::ReturnReceived
            || $this === self::ReturnWrittenOff;
    }

    /** The one code that moves money. */
    public function collectsMoney(): bool
    {
        return $this === self::Delivered;
    }

    public static function tryFromCode(mixed $code): ?self
    {
        return is_numeric($code) ? self::tryFrom((int) $code) : null;
    }
}
