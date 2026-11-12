<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Customer\Support\PrintColors;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;

/**
 * A print order cannot be taken or reach «قيد الطباعة» without a design carrying its colours
 * (PRINT-COLORS.md §9). Tests about something else entirely (stock, costs, the timeline) use
 * this to satisfy that rule without saying anything about it.
 */
trait GivesPrintableArtwork
{
    /**
     * A library design for [$customerId] whose colours are complete, as its id.
     */
    protected function printableDesignId(int $customerId): int
    {
        return (int) CustomerDesign::factory()->printable()->create([
            'customer_id' => $customerId,
        ])->getKey();
    }

    /**
     * Makes sure the next move into «قيد الطباعة» is not refused for want of colours: the version
     * the press would print gets complete colours if it has none, and an order with no version
     * gets one. Colours a test already set are left alone.
     */
    protected function givePrintableArtwork(Order $order): void
    {
        $existing = $order->unsetRelation('designs')->designForPress();

        if ($existing !== null) {
            if (! PrintColors::isComplete($existing->print_colors)) {
                $existing->forceFill(['print_colors' => [
                    ['name' => 'أسود', 'code' => null, 'hex' => '#000000'],
                ]])->save();
            }

            $order->unsetRelation('designs');

            return;
        }

        $design = CustomerDesign::factory()->printable()->create([
            'customer_id' => $order->customer_id,
        ]);

        OrderDesign::factory()->create([
            'order_id' => $order->getKey(),
            'customer_design_id' => $design->getKey(),
            'version' => (int) $order->designs()->withTrashed()->max('version') + 1,
            'status' => OrderDesignStatus::Proposed,
            'print_colors' => $design->print_colors,
        ]);

        $order->unsetRelation('designs');
    }
}
