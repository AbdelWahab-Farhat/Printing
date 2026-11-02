<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;

/**
 * A design's print colors changed: carry the change onto every order still waiting to print it.
 *
 * {@see AddOrderDesign} copies the colors onto the version, so an order keeps the inks it was
 * printed in. But a copy taken today goes stale tomorrow — a clerk attaches the file first and
 * fills in the colors after, and the press would then read an empty list off the order while the
 * design itself says «PANTONE 186 C». So the copy follows its source **for as long as the order
 * still accepts artwork** ({@see Order::designEditableStatuses()}), and stops the moment the
 * order goes to the press.
 *
 * **Only a copy that still matches the old value moves.** A version whose colors somebody changed
 * for this one order — «هالمرة بالأزرق» — is a decision about that order, and an edit to the
 * library must not quietly undo it.
 *
 * One save per version, so each change lands in that order's history like any other edit.
 */
final class RefreshOrderDesignColors
{
    /**
     * @param  list<array{name: string, code: string|null, hex: string|null}>|null  $before
     * @return int how many versions moved
     */
    public function __invoke(CustomerDesign $design, ?array $before): int
    {
        $after = $design->print_colors;

        if ($after === $before) {
            return 0;
        }

        $versions = OrderDesign::query()
            ->where('customer_design_id', $design->getKey())
            ->whereHas('order', fn ($orders) => $orders->whereIn(
                'status',
                array_map(fn ($status) => $status->value, Order::designEditableStatuses()),
            ))
            ->get();

        $moved = 0;

        foreach ($versions as $version) {
            if ($version->print_colors !== $before) {
                continue;
            }

            $version->print_colors = $after;
            $version->save();
            $moved++;
        }

        return $moved;
    }
}
