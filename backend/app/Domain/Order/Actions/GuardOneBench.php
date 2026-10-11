<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Order\Exceptions\OutsourcedLineCannotShareAnOrder;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;

/**
 * Refuses an order whose lines are not all made in the same kind of place.
 *
 * **Unanimity about the group, not a limit on lines.** Several وسيط lines in one order are
 * fine: the road is unanimous and the vendor is named once, at acceptance. What cannot
 * happen is a وسيط line beside one that is not.
 *
 * A line whose product has no heading — the column is nullable — answers `in_house`, the
 * same assumption {@see ResolveOrderFlow} makes. The unknown case takes the road that asks
 * more of the shop, never the one that asks less.
 *
 * **Lifted out of {@see CreateOrder} when edits could add lines.** Asked only on the way in, an
 * order taken with in-house lines could have a وسيط one added the next minute — the exact order
 * the rule exists to refuse.
 */
final class GuardOneBench
{
    /**
     * @throws OutsourcedLineCannotShareAnOrder
     */
    public function __invoke(Order $order): void
    {
        $order->loadMissing('items.product.productCategory.parent');

        $groups = $order->items
            ->map(fn (OrderItem $item): string => (
                $item->product?->productCategory?->productionMode() ?? ProductionMode::InHouse
            )->orderGroup())
            ->unique();

        if ($groups->count() > 1) {
            throw OutsourcedLineCannotShareAnOrder::make();
        }
    }
}
