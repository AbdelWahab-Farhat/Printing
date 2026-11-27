<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Support;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Which branches an employee may *act* for — INSTANT-ORDERS-PLAN.md §8–§9.
 *
 * **Acting, never reading.** The owner's last approved change: the branch link decides the
 * warehouse, the treasury account and the operational moves (sell, hand over, cancel) — it never
 * limits what an employee may search or open. Nothing in a query reads this class.
 *
 * Whoever holds `branches.manage` — and so every administrator, through `Gate::before` — may act
 * for any branch without being assigned (owner's decision, 2026-11-26). Everybody else acts only
 * for the branches on their `branch_user` rows.
 */
final class BranchAccess
{
    /** Holds every branch by role rather than by assignment. */
    public function coversEveryBranch(?User $user): bool
    {
        return $user?->can(PermissionName::ManageBranches->value) === true;
    }

    public function mayActFor(?User $user, ?int $cityId): bool
    {
        if ($user === null || $cityId === null) {
            return false;
        }

        if ($this->coversEveryBranch($user)) {
            return true;
        }

        return DB::table('branch_user')
            ->where('user_id', $user->getKey())
            ->where('city_id', $cityId)
            ->exists();
    }

    /**
     * The branches this employee may sell from right now: office-pickup cities that are active,
     * and either assigned to them or — for whoever covers every branch — all of them.
     *
     * @return Collection<int, City>
     */
    public function sellingBranchesFor(?User $user): Collection
    {
        if ($user === null) {
            return new Collection;
        }

        $query = City::query()
            ->where('fulfilment_type', FulfilmentType::OfficePickup->value)
            ->where('is_branch_active', true)
            ->orderBy('name');

        if (! $this->coversEveryBranch($user)) {
            $query->whereIn('id', $this->assignedIds($user));
        }

        return $query->get();
    }

    /**
     * The branches this employee is assigned to, whatever their state — what the home screen
     * counts «استلام مكتب» orders for.
     *
     * @return list<int>
     */
    public function assignedIds(User $user): array
    {
        return DB::table('branch_user')
            ->where('user_id', $user->getKey())
            ->pluck('city_id')
            ->map(fn ($id): int => (int) $id)
            ->all();
    }
}
