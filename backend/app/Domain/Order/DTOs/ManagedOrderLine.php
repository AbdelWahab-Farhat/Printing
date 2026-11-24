<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

/**
 * One line as «إدارة الطلبية» sends it: the line, its new quantity and its new price.
 *
 * **The price is the one the line is billed at, whatever the catalogue says.** That is the point
 * of the screen: the ordinary edit takes the catalogue's rate for every product with listed
 * prices, and this one is for the person allowed to override it.
 */
final readonly class ManagedOrderLine
{
    public function __construct(
        public int $id,
        public string $quantity,
        public string $unitPrice,
        /** What leaves the shelf, for a line stocked in another unit whose quantity moved. */
        public ?string $warehouseQuantity = null,
    ) {}
}
