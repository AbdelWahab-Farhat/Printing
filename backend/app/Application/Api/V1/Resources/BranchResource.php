<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A branch as the settings screen edits it — INSTANT-ORDERS-PLAN.md §8. Each linked thing is
 * named, so the screen shows what is chosen without a second request.
 *
 * Expects `defaultWarehouse` and `employees` loaded, and the `cashAccount`, `bankTransferAccount`
 * and `bankCardAccount` relations set by the controller (the accounts belong to the treasury).
 *
 * @mixin City
 */
class BranchResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (int) $this->id,
            'name' => (string) $this->name,
            'is_branch_active' => (bool) $this->is_branch_active,
            'default_warehouse' => $this->defaultWarehouse === null ? null : [
                'id' => (int) $this->defaultWarehouse->id,
                'name' => (string) $this->defaultWarehouse->name,
            ],
            'cash_account' => $this->linked('cashAccount'),
            'bank_transfer_account' => $this->linked('bankTransferAccount'),
            'bank_card_account' => $this->linked('bankCardAccount'),
            'employees' => $this->employees
                ->map(fn (User $user): array => ['id' => (int) $user->id, 'name' => (string) $user->name])
                ->values()
                ->all(),
        ];
    }

    /**
     * @return array{id: int, name: string}|null
     */
    private function linked(string $relation): ?array
    {
        $account = $this->resource->relationLoaded($relation) ? $this->resource->getRelation($relation) : null;

        return $account instanceof TreasuryAccount
            ? ['id' => (int) $account->id, 'name' => (string) $account->name]
            : null;
    }
}
