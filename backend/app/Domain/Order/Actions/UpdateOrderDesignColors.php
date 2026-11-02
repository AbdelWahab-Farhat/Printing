<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Exceptions\OrderDesignColorsAreLocked;
use App\Domain\Order\Exceptions\OrderIsClosed;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;

/**
 * Corrects the print colors on one version of one order's artwork.
 *
 * The version holds a copy of its design's colors ({@see AddOrderDesign}); this is how that copy
 * is changed for this order alone — «هالمرة بالأزرق» — without touching the customer's library.
 * A copy changed here is also one a later edit to the library leaves alone
 * ({@see RefreshOrderDesignColors}).
 *
 * **Under the same lock as the artwork itself.** Once the order is at the press the inks are a
 * record of what was printed, not a plan, and that is the moment the reminder on the move into
 * «قيد الطباعة» warns about.
 */
final class UpdateOrderDesignColors
{
    /**
     * @param  array<int, mixed>|null  $colors  already validated
     *
     * @throws OrderIsClosed
     * @throws OrderDesignColorsAreLocked
     */
    public function __invoke(Order $order, OrderDesign $design, ?array $colors): OrderDesign
    {
        if ($order->status->isClosed()) {
            throw OrderIsClosed::make($order->status);
        }

        if (! $order->designsAreEditable()) {
            throw OrderDesignColorsAreLocked::make($order->status);
        }

        $design->print_colors = $colors;
        $design->save();

        return $design->refresh();
    }
}
