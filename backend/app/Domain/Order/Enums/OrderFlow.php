<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * Which road an order walks — the second thing {@see OrderStatus::allowedNext()} reads.
 *
 * **A كيس سادة is not printed, and until now it had to pretend it was.** The map was one `match`
 * on the status alone, so every order in the shop went جديدة → قيد التصميم → قيد الطباعة →
 * جاهزة; a plain bag pulled off a shelf and counted had to be walked through two statuses naming
 * work nobody did. That is the same complaint `Order::designsAreEditable()` already answered for
 * artwork — staff pushing an order into the designer's queue and straight back out to record a
 * file — and it is answered the same way here: the road that does not apply is not offered.
 *
 * **Not a flag on the order, and not a second enum of statuses.** A boolean would have to be read
 * as «هل يتخطى؟» at four call sites and would say nothing about *what* is skipped; a parallel set
 * of statuses would fork the labels, the permissions and the timestamps for a road that differs
 * in two steps. This is the smallest thing that carries the whole answer: a name for the road,
 * passed to the map that already exists.
 *
 * **Where it comes from.** `ResolveOrderFlow` reads it off the lines' product categories at intake
 * and stamps it on the order — see that action for why the answer is snapshotted rather than
 * derived on every read.
 *
 * `label()` is not decoration: `AuditValueLabels` auto-translates any enum-cast column whose enum
 * can name itself, so the history screen prints «بلا تصميم وطباعة» without a second dictionary.
 */
enum OrderFlow: string
{
    /**
     * The road the whole shop walked before this enum existed, and still the common one:
     * the artwork is agreed, the press runs, and the bags exist afterwards.
     */
    case Standard = 'standard';

    /**
     * Goods that are already made. Nothing is designed and nothing is printed — the order is
     * picked off a shelf, counted, and it is «جاهزة».
     *
     * **It still deducts stock, and still asks where from.** Skipping production is not skipping
     * fulfilment: entering «جاهزة» takes the same warehouse, the same per-line weight and the
     * same costing it takes on the printed road — see `TransitionFields`.
     */
    case NoProduction = 'no_production';

    public function label(): string
    {
        return match ($this) {
            self::Standard => 'المسار المعتاد',
            self::NoProduction => 'بلا تصميم وطباعة',
        };
    }

    /** Whether the press and the designer's queue are on this road at all. */
    public function hasProduction(): bool
    {
        return $this === self::Standard;
    }
}
