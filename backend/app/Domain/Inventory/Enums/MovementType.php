<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Enums;

use App\Domain\Inventory\Models\StockMovement;

/**
 * Why a quantity moved.
 *
 * The two predicates below are the whole shape rule of the ledger, kept in one place. Four
 * separate FormRequests each declare which warehouse fields they take, and it would be easy for
 * those four declarations to be the only statement of the rule — at which point the fifth
 * caller (a console command, a seeder, an importer) gets it wrong silently. Stating it on the
 * enum means {@see StockMovement} can be checked against its own type wherever it is built.
 */
enum MovementType: string
{
    /** Stock entering the business from a supplier. */
    case PurchaseArrival = 'purchase_arrival';

    /** Stock moving between two of our own warehouses. */
    case InternalTransfer = 'internal_transfer';

    /** Stock leaving for a customer's order. */
    case OrderFulfillment = 'order_fulfillment';

    /** A stocktake correction — the shelf disagreed with the book. */
    case Adjustment = 'adjustment';

    public function label(): string
    {
        return match ($this) {
            self::PurchaseArrival => 'توريد',
            self::InternalTransfer => 'تحويل داخلي',
            self::OrderFulfillment => 'صرف لطلب',
            self::Adjustment => 'تسوية جرد',
        };
    }

    /**
     * Whether this kind of movement takes stock *out* of a warehouse.
     *
     * An adjustment answers neither this nor {@see requiresDestination()} definitively: it takes
     * exactly one side, and which one depends on its {@see AdjustmentDirection}. So both return
     * false for it, and the action asks the direction instead.
     */
    public function requiresSource(): bool
    {
        return match ($this) {
            self::InternalTransfer, self::OrderFulfillment => true,
            self::PurchaseArrival, self::Adjustment => false,
        };
    }

    /**
     * Whether this kind of movement puts stock *into* a warehouse.
     */
    public function requiresDestination(): bool
    {
        return match ($this) {
            self::PurchaseArrival, self::InternalTransfer => true,
            self::OrderFulfillment, self::Adjustment => false,
        };
    }

    /**
     * Whether the side this movement uses is decided by a direction rather than by the type.
     */
    public function isDirectional(): bool
    {
        return $this === self::Adjustment;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
