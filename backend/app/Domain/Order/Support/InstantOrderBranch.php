<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Support\BranchAccess;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Exceptions\InstantOrderRefused;

/**
 * The branch an instant sale is made at, checked before anything is written
 * (INSTANT-ORDERS-PLAN.md §3, §8):
 *
 * - an office-pickup city,
 * - active for new sales,
 * - one this employee may act for (or any, for whoever holds `branches.manage`),
 * - with a default warehouse that still exists — never another warehouse instead.
 */
final class InstantOrderBranch
{
    public function __construct(private readonly BranchAccess $access) {}

    /**
     * @return array{0: City, 1: int} the branch and its warehouse id
     *
     * @throws InstantOrderRefused
     */
    public function forSale(int $branchId, User $actor): array
    {
        $branch = City::query()->find($branchId);

        if ($branch === null || ! $branch->isOfficePickup()) {
            throw InstantOrderRefused::notABranch();
        }

        $name = (string) $branch->name;

        if (! $branch->is_branch_active) {
            throw InstantOrderRefused::branchInactive($name);
        }

        if (! $this->access->mayActFor($actor, (int) $branch->getKey())) {
            throw InstantOrderRefused::notYourBranch($name);
        }

        $warehouseId = $branch->default_warehouse_id;

        if ($warehouseId === null || ! $branch->defaultWarehouse()->exists()) {
            throw InstantOrderRefused::branchHasNoWarehouse($name);
        }

        return [$branch, (int) $warehouseId];
    }
}
