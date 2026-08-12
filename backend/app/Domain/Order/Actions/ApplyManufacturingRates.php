<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\ManufacturingCostType;
use App\Domain\Order\Models\ManufacturingCostRate;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\ProductionCostEntry;
use App\Domain\Order\Support\Money;

/**
 * Costs an order's labour, machine runtime and overhead the moment it enters printing —
 * standard-costed from {@see ManufacturingCostRate}, never typed per job.
 *
 * Called by {@see ChangeOrderStatus} inside its own transaction, alongside
 * {@see DeductOrderStock}, guarded by the same first-entry-into-printing condition — a reprint
 * does not re-cost, exactly as it does not re-deduct material. See the plan's "known limitation"
 * note: extra labour or press time from a reprint is not captured automatically.
 *
 * **A cost type with no applicable rate is skipped, never assumed to be zero.** A rate that was
 * simply never set up is a gap in the setup, not a business fact that this line cost nothing to
 * produce — inventing a zero would make that gap invisible in every report built on `cogs`.
 */
final class ApplyManufacturingRates
{
    public function __construct(
        private readonly RecalculateOrderItemManufacturingCost $recalculateManufacturingCost,
        private readonly RecalculateOrderItemCost $recalculateItemCost,
    ) {}

    public function __invoke(Order $order, int $actorId): void
    {
        foreach ($order->items as $item) {
            foreach (ManufacturingCostType::cases() as $type) {
                if ($type->isRateDriven()) {
                    $this->applyRate($order, $item, $type, $actorId);
                }
            }

            ($this->recalculateManufacturingCost)($item);
            ($this->recalculateItemCost)($item);
        }
    }

    private function applyRate(Order $order, OrderItem $item, ManufacturingCostType $type, int $actorId): void
    {
        $rate = $this->findRate($item->product_id, $type);

        if ($rate === null) {
            return;
        }

        // The same physical quantity DeductOrderStock costs material against — never
        // `order_items.quantity` directly, or a line's labour and material would be computed
        // against different amounts. See OrderItem::producedQuantity().
        $quantity = $item->producedQuantity();
        $amount = Money::round(bcmul($quantity, (string) $rate->rate_per_unit, 8));

        $entry = new ProductionCostEntry;
        $entry->order_id = $order->getKey();
        $entry->order_item_id = $item->getKey();
        $entry->cost_type = $type;
        $entry->quantity = $quantity;
        $entry->rate = $rate->rate_per_unit;
        $entry->amount = $amount;
        $entry->recorded_by = $actorId;
        $entry->incurred_at = now();
        $entry->save();
    }

    /**
     * The product-specific rate if one exists; the default (no `product_id`) otherwise. Never a
     * third answer — see the class docblock.
     */
    private function findRate(int $productId, ManufacturingCostType $type): ?ManufacturingCostRate
    {
        return ManufacturingCostRate::query()
            ->where('cost_type', $type)
            ->where('is_active', true)
            ->where(fn ($query) => $query->where('product_id', $productId)->orWhereNull('product_id'))
            ->orderByRaw('product_id IS NULL')
            ->first();
    }
}
