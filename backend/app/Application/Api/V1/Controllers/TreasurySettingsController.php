<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Treasury\UpdateTreasurySettingsRequest;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Delivery\DeliveryService;
use App\Domain\Delivery\Models\City;
use App\Domain\Treasury\Actions\UpdateTreasurySettings;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * «إعدادات المالية» — TREASURY-DESIGN §١٦.
 */
class TreasurySettingsController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly TreasuryService $treasury) {}

    public function show(DeliveryService $delivery): JsonResponse
    {
        return $this->success($this->shape($this->treasury->settings(), $delivery));
    }

    public function update(
        UpdateTreasurySettingsRequest $request,
        UpdateTreasurySettings $update,
        DeliveryService $delivery,
    ): JsonResponse {
        /** @var array<string, mixed> $values */
        $values = $request->validated();

        $settings = $update($values, $request->user()?->getKey() === null ? null : (int) $request->user()->getKey());

        return $this->success($this->shape($settings, $delivery), 'تم حفظ إعدادات المالية');
    }

    public function logs(ActivityLogFilterRequest $request, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $this->treasury->settings(), $audit);
    }

    /**
     * @return array<string, mixed>
     */
    private function shape(TreasurySetting $settings, DeliveryService $delivery): array
    {
        $boxes = TreasuryAccount::query()->whereNotNull('pickup_city_id')->get()->keyBy('pickup_city_id');

        return [
            'own_account_first' => (bool) $settings->own_account_first,
            'block_overdraft' => (bool) $settings->block_overdraft,
            'withdrawal_needs_reason' => (bool) $settings->withdrawal_needs_reason,
            'ask_carrier_fee' => (bool) $settings->ask_carrier_fee,
            'locked_until' => $settings->locked_until?->toDateString(),
            // «التجميع عند التسوية» — per kind: on or off, and the account named (null: the
            // kind's default).
            'collect_cash' => (bool) $settings->collect_cash,
            'collect_cash_into_id' => $settings->collect_cash_into_id,
            'collect_bank' => (bool) $settings->collect_bank,
            'collect_bank_into_id' => $settings->collect_bank_into_id,
            'collect_wallet' => (bool) $settings->collect_wallet,
            'collect_wallet_into_id' => $settings->collect_wallet_into_id,
            // «كاش كل مكتب استلام» — each branch customers collect from, and the cash box its
            // cash lands in (null: the usual rules). Linked on the account (§١٩).
            'pickup_offices' => $delivery->pickupOffices()->map(fn (City $city) => [
                'city_id' => $city->id,
                'name' => $city->name,
                'account_id' => $boxes->get($city->id)?->id,
                'account_name' => $boxes->get($city->id)?->name,
            ])->values()->all(),
        ];
    }
}
