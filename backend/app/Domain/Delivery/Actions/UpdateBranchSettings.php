<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\Models\City;
use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * Saves one branch's settings — INSTANT-ORDERS-PLAN.md §8.
 *
 * A full replace, as the settings screen sends every field: the active switch, the default
 * warehouse, the account for each payment method, and the employees who work there.
 *
 * **The cash account is the branch's existing box** (`treasury_accounts.pickup_city_id`, TREASURY
 * §١٩), linked through the treasury's own update so its rule holds — one box per branch, cash
 * only — and its audit trail says which box gained or lost the branch. The bank accounts are
 * columns on the branch itself.
 *
 * Nothing here touches a past order: an instant order copied its warehouse when it was taken, and
 * each payment stored the account it actually landed in.
 */
final class UpdateBranchSettings
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  list<int>  $employeeIds
     */
    public function __invoke(
        City $branch,
        bool $isActive,
        ?int $warehouseId,
        ?int $cashAccountId,
        ?int $bankTransferAccountId,
        ?int $bankCardAccountId,
        array $employeeIds,
    ): City {
        return DB::transaction(function () use ($branch, $isActive, $warehouseId, $cashAccountId, $bankTransferAccountId, $bankCardAccountId, $employeeIds): City {
            $branch->forceFill([
                'is_branch_active' => $isActive,
                'default_warehouse_id' => $warehouseId,
                'bank_transfer_account_id' => $bankTransferAccountId,
                'bank_card_account_id' => $bankCardAccountId,
            ])->save();

            $this->linkCashBox((int) $branch->getKey(), $cashAccountId);

            $branch->employees()->sync(array_values(array_unique($employeeIds)));

            return $branch->refresh();
        });
    }

    private function linkCashBox(int $branchId, ?int $cashAccountId): void
    {
        $current = TreasuryAccount::query()->where('pickup_city_id', $branchId)->first();

        if ($current !== null && (int) $current->getKey() === $cashAccountId) {
            return;
        }

        if ($cashAccountId === null) {
            if ($current !== null) {
                $this->treasury->updateAccount($current, AccountData::fromArray(['pickup_city_id' => null]));
            }

            return;
        }

        // Linking the new box unlinks the old one, inside the treasury's own rule.
        $this->treasury->updateAccount(
            TreasuryAccount::query()->findOrFail($cashAccountId),
            AccountData::fromArray(['pickup_city_id' => $branchId]),
        );
    }
}
