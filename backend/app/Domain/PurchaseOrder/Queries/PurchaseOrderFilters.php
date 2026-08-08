<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Queries;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;

final readonly class PurchaseOrderFilters
{
    public function __construct(
        public ?int $vendorId = null,
        public ?int $warehouseId = null,
        public ?PurchaseOrderStatus $status = null,
    ) {}

    /**
     * @param  array<string, mixed>  $query  Validated query-string values.
     */
    public static function fromArray(array $query): self
    {
        return new self(
            vendorId: self::intOrNull($query['vendor_id'] ?? null),
            warehouseId: self::intOrNull($query['warehouse_id'] ?? null),
            status: isset($query['status']) && $query['status'] !== ''
                ? PurchaseOrderStatus::from((string) $query['status'])
                : null,
        );
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }
}
