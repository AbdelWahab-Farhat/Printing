<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Delivery\UpdateBranchRequest;
use App\Application\Api\V1\Resources\BranchResource;
use App\Application\Controller;
use App\Domain\Delivery\Actions\UpdateBranchSettings;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Settings\SettingsService;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Support\ResponseTrait;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Branches
 *
 * «إعدادات الفروع» — INSTANT-ORDERS-PLAN.md §8. A branch is an office-pickup city; these
 * endpoints edit what an instant sale needs from it. Behind `branches.manage`.
 */
class BranchController extends Controller
{
    use ResponseTrait;

    /**
     * List branches
     *
     * Every office-pickup city with its settings. `meta.instant_order_late_hours` is the
     * company-wide «متأخرة» threshold, edited on the same screen.
     */
    public function index(SettingsService $settings): JsonResponse
    {
        $branches = City::query()
            ->where('fulfilment_type', FulfilmentType::OfficePickup->value)
            ->with(['defaultWarehouse', 'employees'])
            ->orderBy('name')
            ->get();

        return $this->successWithMeta(
            BranchResource::collection($this->withAccounts($branches)),
            ['instant_order_late_hours' => $settings->instantOrderLateHours()],
        );
    }

    /**
     * Save a branch's settings
     *
     * Sent whole: active switch, default warehouse, the account for cash, transfer and card, and
     * the employees who work there. Past orders are untouched.
     */
    public function update(UpdateBranchRequest $request, City $branch, UpdateBranchSettings $update): JsonResponse
    {
        $int = fn (string $key): ?int => $request->validated($key) === null ? null : (int) $request->validated($key);

        $saved = $update(
            $branch,
            (bool) $request->validated('is_branch_active'),
            $int('default_warehouse_id'),
            $int('cash_account_id'),
            $int('bank_transfer_account_id'),
            $int('bank_card_account_id'),
            array_map(intval(...), (array) $request->validated('employee_ids', [])),
        );

        $saved->load(['defaultWarehouse', 'employees']);

        return $this->success(
            new BranchResource($this->withAccounts(new Collection([$saved]))->first()),
            'تم حفظ إعدادات الفرع',
        );
    }

    /**
     * Change the «متأخرة» threshold
     *
     * How many hours an instant order may wait in «جديدة» before it is flagged. Never cancels
     * anything.
     */
    public function lateHours(Request $request, SettingsService $settings): JsonResponse
    {
        $validated = $request->validate([
            'instant_order_late_hours' => ['required', 'integer', 'min:1', 'max:720'],
        ]);

        $settings->setInstantOrderLateHours((int) $validated['instant_order_late_hours'], $request->user()?->getKey());

        return $this->success(['instant_order_late_hours' => $settings->instantOrderLateHours()], 'تم الحفظ');
    }

    /**
     * Names each branch's three accounts, in two queries for the whole list.
     *
     * @param  Collection<int, City>  $branches
     * @return Collection<int, City>
     */
    private function withAccounts(Collection $branches): Collection
    {
        $ids = $branches->flatMap(fn (City $branch) => [$branch->bank_transfer_account_id, $branch->bank_card_account_id])
            ->filter()
            ->unique()
            ->values()
            ->all();

        $banks = TreasuryAccount::query()->whereKey($ids)->get()->keyBy('id');
        $boxes = TreasuryAccount::query()->whereIn('pickup_city_id', $branches->modelKeys())->get()->keyBy('pickup_city_id');

        return $branches->each(function (City $branch) use ($banks, $boxes): void {
            $branch->setRelation('cashAccount', $boxes->get($branch->getKey()));
            $branch->setRelation('bankTransferAccount', $banks->get($branch->bank_transfer_account_id));
            $branch->setRelation('bankCardAccount', $banks->get($branch->bank_card_account_id));
        });
    }
}
