<?php

declare(strict_types=1);

namespace App\Domain\Inventory\DTOs;

use App\Domain\Inventory\Enums\AdjustmentDirection;
use App\Domain\Inventory\Enums\MovementType;

/**
 * One movement, in the shape the ledger stores it.
 *
 * Four named constructors rather than one `fromArray`, because the four endpoints genuinely
 * take four different payloads — an arrival has no source, a fulfillment has no destination, an
 * adjustment has a direction instead of either. Translating each into the ledger's
 * from/to/quantity shape is exactly the mapping this class exists to do, and doing it here means
 * the four controllers stay identical to every other controller in the codebase: validate,
 * build a DTO, call the service.
 *
 * `employeeId` is passed in rather than read from a payload. It comes from the authenticated
 * user at the boundary, so there is no arrangement of request fields that can attribute a
 * movement to a colleague.
 */
final readonly class StockMovementData
{
    private function __construct(
        public int $productVariantId,
        public MovementType $movementType,
        /** Always positive, normalised to three decimal places. Direction lives in from/to. */
        public string $quantity,
        public ?int $fromWarehouseId,
        public ?int $toWarehouseId,
        public int $employeeId,
        /** The order this belongs to, once Orders lands. Unconstrained until then. */
        public ?int $referenceId = null,
        public ?string $notes = null,
    ) {}

    /**
     * Stock entering the business from a supplier: no source, because it was not ours before.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function arrival(array $validated, int $employeeId): self
    {
        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            movementType: MovementType::PurchaseArrival,
            quantity: self::quantity($validated['quantity']),
            fromWarehouseId: null,
            toWarehouseId: (int) $validated['to_warehouse_id'],
            employeeId: $employeeId,
            referenceId: self::intOrNull($validated['reference_id'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
        );
    }

    /**
     * Stock moving between two of our own sites: both ends ours, so both are filled.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function transfer(array $validated, int $employeeId): self
    {
        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            movementType: MovementType::InternalTransfer,
            quantity: self::quantity($validated['quantity']),
            fromWarehouseId: (int) $validated['from_warehouse_id'],
            toWarehouseId: (int) $validated['to_warehouse_id'],
            employeeId: $employeeId,
            referenceId: self::intOrNull($validated['reference_id'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
        );
    }

    /**
     * Stock leaving for a customer: no destination, because it stops being ours.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fulfillment(array $validated, int $employeeId): self
    {
        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            movementType: MovementType::OrderFulfillment,
            quantity: self::quantity($validated['quantity']),
            fromWarehouseId: (int) $validated['from_warehouse_id'],
            toWarehouseId: null,
            employeeId: $employeeId,
            referenceId: self::intOrNull($validated['reference_id'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
        );
    }

    /**
     * A stocktake correction. One warehouse and a direction; which end of the ledger row that
     * fills is this method's business and nobody else's.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function adjustment(array $validated, int $employeeId): self
    {
        $warehouseId = (int) $validated['warehouse_id'];
        $direction = AdjustmentDirection::from((string) $validated['direction']);

        return new self(
            productVariantId: (int) $validated['product_variant_id'],
            movementType: MovementType::Adjustment,
            quantity: self::quantity($validated['quantity']),
            fromWarehouseId: $direction === AdjustmentDirection::Decrease ? $warehouseId : null,
            toWarehouseId: $direction === AdjustmentDirection::Increase ? $warehouseId : null,
            employeeId: $employeeId,
            referenceId: null,
            notes: self::textOrNull($validated['notes'] ?? null),
        );
    }

    /**
     * Cast through string, never left as a float: this number is compared against a balance and
     * added to it, and a shelf count that picks up binary drift on the way in is a discrepancy
     * nobody will ever be able to explain.
     */
    private static function quantity(mixed $value): string
    {
        return number_format((float) $value, 3, '.', '');
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
