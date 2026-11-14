<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Exceptions\CompensatedOrderIsInvalid;
use App\Domain\Order\Exceptions\CompensationRequiresPermission;
use App\Domain\Order\Exceptions\CompensationTakesNoCharges;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;

/**
 * The rules a compensation order is held to, whichever door it came through — the new-order form
 * ({@see CreateOrder}) or the switch on an existing order ({@see ChangeOrderCompensation}).
 *
 * See Docs/orders/ORDER-COMPENSATION.md §4.
 */
final class GuardCompensation
{
    /**
     * Turning an order into a compensation order, or back, gives goods away or asks for money,
     * so both directions need the grant.
     *
     * @throws CompensationRequiresPermission
     */
    public function permission(?User $actor): void
    {
        if (! $actor?->can(PermissionName::CompensationOrders->value)) {
            throw CompensationRequiresPermission::make();
        }
    }

    /**
     * A compensation order owes nothing, so neither a discount nor an additional cost has
     * anything to act on.
     *
     * @throws CompensationTakesNoCharges
     */
    public function noCharges(string $discount, string $additionalCost): void
    {
        if (bccomp($discount, '0', Money::SCALE) > 0) {
            throw CompensationTakesNoCharges::discount();
        }

        if (bccomp($additionalCost, '0', Money::SCALE) > 0) {
            throw CompensationTakesNoCharges::additionalCost();
        }
    }

    /**
     * The original, when one is named: the same customer's, and an ordinary order.
     *
     * @throws CompensatedOrderIsInvalid
     */
    public function original(?int $originalId, int $customerId, ?int $selfId = null): void
    {
        if ($originalId === null) {
            return;
        }

        if ($selfId !== null && $originalId === $selfId) {
            throw CompensatedOrderIsInvalid::itself();
        }

        $original = Order::withTrashed()->findOrFail($originalId);

        if ((int) $original->customer_id !== $customerId) {
            throw CompensatedOrderIsInvalid::otherCustomer();
        }

        if ($original->is_compensation) {
            throw CompensatedOrderIsInvalid::isCompensation();
        }
    }
}
