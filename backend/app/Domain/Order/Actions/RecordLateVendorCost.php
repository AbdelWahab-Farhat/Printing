<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Order\Exceptions\VendorCostCannotBeRecorded;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Support\Facades\DB;

/**
 * Costs a وسيط line that went past «جاهزة» without a vendor cost — OUTSOURCED-PRODUCTS.md §6.2.
 *
 * **A gap being filled, not a figure being corrected.** «جاهزة» is where a وسيط line is costed,
 * and since §6.1 the move is refused without the figure. Orders taken before that passed it
 * with nothing and were costed at nothing: `cogs` null, the order's profit unknown, and the P&L
 * summing the gap as zero. This does exactly what that «جاهزة» would have done, once, and only
 * for such a line. A line with a cost is refused — owner decision 2026-10-20, no correction
 * after «جاهزة».
 *
 * **Costed on what «جاهزة» would have used**: the quantity less what never arrived. Not
 * `billableQuantity()`, which by now may also have lost what the customer left on the counter
 * — the vendor made those, and the shop paid for them. The `delivery_loss` entry such a line
 * would have been given at «تم الاستلام» is not written back; the profit is right without it,
 * the P&L just does not name that slice as a loss.
 *
 * **Nothing to re-post.** Investors are paid from the shelves an order drew, and a وسيط order
 * draws none — so filling this on a delivered order moves the order's own figures and the P&L,
 * and nothing in anybody's wallet.
 */
final class RecordLateVendorCost
{
    public function __construct(
        private readonly ApplyOutsourcingCosts $applyOutsourcingCosts,
        private readonly RecalculateOrderCogs $recalculateCogs,
    ) {}

    /**
     * @throws VendorCostCannotBeRecorded
     */
    public function __invoke(Order $order, OrderItem $item, string $unitCost): Order
    {
        return DB::transaction(function () use ($order, $item, $unitCost): Order {
            // Locked and read fresh, so two taps on the button cannot both find the line empty.
            /** @var OrderItem $line */
            $line = OrderItem::query()
                ->with('product.productCategory.parent')
                ->lockForUpdate()
                ->findOrFail($item->getKey());

            if ($line->productionMode() !== ProductionMode::Outsourced) {
                throw VendorCostCannotBeRecorded::notOutsourced();
            }

            if ($order->ready_at === null) {
                throw VendorCostCannotBeRecorded::notYetReady();
            }

            if ($line->outsourcing_cost !== null) {
                throw VendorCostCannotBeRecorded::alreadyCosted();
            }

            $line->forceFill(['unit_cost' => $unitCost])->save();

            $this->applyOutsourcingCosts->costLine($line, $this->quantityAtReady($line));

            ($this->recalculateCogs)($order->load('items'));

            return $order->refresh();
        });
    }

    /** `quantity − shortage`, floored at zero — what «جاهزة» multiplied out before any delivery. */
    private function quantityAtReady(OrderItem $line): string
    {
        $made = bcsub((string) $line->quantity, (string) ($line->shortage_quantity ?? '0'), 3);

        return bccomp($made, '0', 3) < 0 ? '0.000' : $made;
    }
}
