<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Enums\ManufacturingCostType;

final readonly class ManufacturingCostRateData
{
    public function __construct(
        public ?int $productId,
        public ManufacturingCostType $costType,
        public string $ratePerUnit,
        public bool $isActive = true,
        public ?string $notes = null,
    ) {}

    /**
     * Built from already-validated request data — the one place an array is allowed to cross
     * into the domain.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $notes = trim((string) ($validated['notes'] ?? ''));

        return new self(
            productId: isset($validated['product_id']) && $validated['product_id'] !== ''
                ? (int) $validated['product_id'] : null,
            costType: ManufacturingCostType::from((string) $validated['cost_type']),
            ratePerUnit: number_format((float) $validated['rate_per_unit'], 3, '.', ''),
            isActive: (bool) ($validated['is_active'] ?? true),
            notes: $notes !== '' ? $notes : null,
        );
    }
}
