<?php

declare(strict_types=1);

namespace App\Domain\Inventory\DTOs;

use App\Domain\Inventory\Actions\RecordStockMovement;
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
        /**
         * What a brand-new cost layer should open at — only meaningful for `arrival()` and an
         * increasing `adjustment()`, ignored everywhere else. `null` means no cost was supplied;
         * {@see RecordStockMovement} is what turns that into the
         * documented `'0.000'` placeholder, not this DTO.
         */
        public ?string $unitCost = null,
        /**
         * The `OrderFulfillment` movement an `orderReversal()` credits back. Only meaningful for
         * that one movement type.
         */
        public ?int $reversedMovementId = null,
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
            unitCost: self::costOrNull($validated['unit_cost'] ?? null),
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
            // Required by RecordAdjustmentRequest whenever direction is Increase — an adjustment
            // has no natural cost signal of its own, so unlike an arrival it is never allowed to
            // fall back to the "unknown" placeholder silently. Ignored for a Decrease, which only
            // ever consumes existing layers.
            unitCost: self::costOrNull($validated['unit_cost'] ?? null),
        );
    }

    /**
     * Stock credited back after a cancelled order's fulfillment: no source, because it re-enters
     * the business the same way an arrival does — only the cost layers it lands in are already
     * decided, by `$reversedMovementId`, rather than opened fresh.
     *
     * Built directly from typed values rather than a validated array: this is never posted
     * through an HTTP endpoint, only constructed by `ReverseOrderStockDeduction` itself.
     */
    public static function orderReversal(
        int $productVariantId,
        int $warehouseId,
        string $quantity,
        int $reversedMovementId,
        int $referenceId,
        int $employeeId,
    ): self {
        return new self(
            productVariantId: $productVariantId,
            movementType: MovementType::OrderReversal,
            quantity: self::quantity($quantity),
            fromWarehouseId: null,
            toWarehouseId: $warehouseId,
            employeeId: $employeeId,
            referenceId: $referenceId,
            reversedMovementId: $reversedMovementId,
        );
    }

    /**
     * Stock destroyed during production: no destination, because it left the business by being
     * thrown away rather than sold or moved.
     *
     * Built directly from typed values, like `orderReversal()`: this is never posted through a
     * generic stock-movements endpoint, only constructed by `Order\Actions\RecordScrapLoss` — the
     * scrap belongs to a specific order and line, which only that action knows.
     */
    public static function scrapLoss(
        int $productVariantId,
        int $warehouseId,
        string $quantity,
        int $orderId,
        int $employeeId,
        string $notes,
    ): self {
        return new self(
            productVariantId: $productVariantId,
            movementType: MovementType::ScrapLoss,
            quantity: self::quantity($quantity),
            fromWarehouseId: $warehouseId,
            toWarehouseId: null,
            employeeId: $employeeId,
            referenceId: $orderId,
            notes: $notes,
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

    /**
     * Cast through string, never left as a float, and normalised to three places like every
     * other cost in this schema — the same reasoning {@see quantity()} carries.
     */
    private static function costOrNull(mixed $value): ?string
    {
        return $value !== null && $value !== '' ? number_format((float) $value, 3, '.', '') : null;
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
