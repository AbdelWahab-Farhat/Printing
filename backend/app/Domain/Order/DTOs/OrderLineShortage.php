<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\OrderService;

/**
 * One line of an order, as much of it as another context needs to mirror what is missing from it.
 *
 * **The door Shortages comes through**, handed out by {@see OrderService::shortageLinesFor()}.
 * Orders knows nothing about that context and must not: this is a flat description of a line,
 * and what anybody does with it is their business.
 *
 * Everything a shortage snapshots is here, because the snapshot is the point — a product gets
 * renamed and a closed shortage is a record of what was chased, not of what that row is called
 * today. The same reason `order_items` copies `product_name` beside its foreign key.
 *
 * `shortageQuantity` is what is *still* missing right now, straight off the line. It is null on
 * every line that is not short, and those lines are handed over anyway: "nothing missing from
 * this one" is an answer the reconciliation needs, and leaving them out would make a shortage
 * that has just been filled indistinguishable from a line nobody mentioned.
 */
final readonly class OrderLineShortage
{
    public function __construct(
        public int $lineId,
        public int $orderId,
        public ?int $customerId,
        public int $productId,
        public int $productVariantId,

        /** «كيس شحن ٢٥*٣٥» — the line's own snapshot, product and size already joined. */
        public string $name,

        /**
         * `PricingUnit`'s value — **the unit the shelf counts in, not the one the line priced
         * in.**
         *
         * The two are the same on most sizes and this used to read `pricing_unit`. It is the
         * shelf's now because that is what the section receiving this does: whoever chases a
         * shortage buys what the warehouse is counted in, the arrival lands on a pile counted
         * that way, and the cost layer it opens is priced per that unit. Naming the invoice's
         * unit here put «٣٠ قطعة» in front of a person whose supplier sells kilograms.
         *
         * The invoice's own unit has not moved and is not this context's business — see
         * `OrderItem::billableQuantity()`, which still works in `pricing_unit`.
         */
        public string $unit,

        /**
         * What is still missing **in that unit**, or null for a line that is not short.
         *
         * `OrderItem::shortageStockQuantity()`, so it is `shortage_warehouse_quantity` where the
         * line carries one and `shortage_quantity` where the two units agree.
         */
        public ?string $shortageQuantity,
    ) {}
}
