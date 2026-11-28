<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Delivery\Support\BranchAccess;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;

/**
 * Whether this person may move this order into this status — the one answer the status request
 * and the order's buttons both read, so the screen and the server cannot disagree.
 *
 * **A normal order** asks what it always asked: the target status's own permission — with one
 * addition. «استلام مكتب» → «تم الاستلام» is also open to `pickup_orders.deliver`, but only at a
 * branch the employee may act for (INSTANT-ORDERS-PLAN.md §10). `orders.status.delivered` stays
 * global and unchanged.
 *
 * **An instant order** is moved by its own grants (§9): handing over and cancelling need the
 * instant permission *and* the branch; settling is the manager's or accountant's
 * `orders.status.settled`, as for every order.
 */
final class OrderMovePermission
{
    public function __construct(private readonly BranchAccess $branches) {}

    public function allows(?User $user, Order $order, OrderStatus $target): bool
    {
        if ($user === null) {
            return false;
        }

        if ($order->isInstant()) {
            return match ($target) {
                OrderStatus::Delivered => $this->atBranch($user, $order, PermissionName::DeliverInstantOrders),
                OrderStatus::Cancelled => $this->atBranch($user, $order, PermissionName::CancelInstantOrders),
                OrderStatus::Settled => $user->can(PermissionName::SettleOrders->value),
                default => false,
            };
        }

        if ($user->can($target->permission()->value)) {
            return true;
        }

        return $target === OrderStatus::Delivered
            && $order->status === OrderStatus::OfficePickup
            && $this->atBranch($user, $order, PermissionName::DeliverBranchPickupOrders);
    }

    private function atBranch(User $user, Order $order, PermissionName $permission): bool
    {
        return $user->can($permission->value)
            && $this->branches->mayActFor($user, $order->city_id === null ? null : (int) $order->city_id);
    }
}
