<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Settings\UpdateCompanySettingsRequest;
use App\Application\Controller;
use App\Domain\Settings\DTOs\CompanySettingsData;
use App\Domain\Settings\Models\CompanySetting;
use App\Domain\Settings\SettingsService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * Company settings
 *
 * The handful of defaults the business edits from a screen rather than from a deploy.
 *
 * **None of them reaches back.** `investor_profit_share_percent` seeds a pool and is applied at a
 * close; the two durations are read when a period is *opened* and when a settlement falls due; the
 * grace window is read when capital is offered. Not one of them is ever read backwards, so a
 * change today decides what happens next and moves nothing that has already been agreed or paid —
 * which is precisely why it is safe to let the business edit them at all.
 */
class CompanySettingController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly SettingsService $settings) {}

    /**
     * Read the company settings
     */
    public function show(): JsonResponse
    {
        return $this->success($this->payload($this->settings->current()));
    }

    /**
     * Update the company settings
     */
    public function update(UpdateCompanySettingsRequest $request): JsonResponse
    {
        $settings = $this->settings->update(
            CompanySettingsData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->success(
            $this->payload($settings),
            'تم تحديث الإعدادات — تسري على الفترات القادمة وحدها',
        );
    }

    /**
     * One shape for both endpoints, so a field cannot be added to the read and forgotten on the
     * write — the drift that makes a client believe it saved something it did not.
     *
     * @return array<string, mixed>
     */
    private function payload(CompanySetting $settings): array
    {
        return [
            'investor_profit_share_percent' => (string) $settings->investor_profit_share_percent,
            'profit_period_months' => (int) $settings->profit_period_months,
            'settlement_period_months' => (int) $settings->settlement_period_months,
            'entry_grace_days' => (int) $settings->entry_grace_days,
            'minimum_term_months' => (int) $settings->minimum_term_months,
            'updated_at' => $settings->updated_at?->toIso8601String(),
        ];
    }
}
