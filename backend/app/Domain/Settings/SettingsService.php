<?php

declare(strict_types=1);

namespace App\Domain\Settings;

use App\Domain\Settings\DTOs\CompanySettingsData;
use App\Domain\Settings\Models\CompanySetting;

/**
 * The door to the company's editable defaults.
 *
 * Other contexts ask this rather than reaching for the model, so the day the single row becomes
 * a key/value table nothing outside here notices.
 *
 * **Nothing caches the answer.** It is one indexed read on a one-row table, taken at the moment
 * a deal is created and never again for that deal; a cache would buy nothing and would need
 * forgetting in three places, which is exactly how `CreateRole`, `UpdateRole` and `DeleteRole`
 * each ended up calling `forgetCachedPermissions()`.
 */
final class SettingsService
{
    public function current(): CompanySetting
    {
        return CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID);
    }

    /**
     * The share of a deal's profit that goes to its investors, as a decimal string.
     *
     * A **default for a new deal only**. Once a deal is created the figure lives on the deal and
     * is never read from here again — so changing this tomorrow cannot move a closed deal's
     * numbers, which is the whole reason it is safe for the business to edit.
     */
    public function investorProfitSharePercent(): string
    {
        return (string) $this->current()->investor_profit_share_percent;
    }

    /**
     * How long a profit period runs, in months.
     *
     * Read when a period is **opened**, to derive its `ends_on`, and never again for that period —
     * so a change tomorrow decides where the next boundary falls and cannot move one that has
     * already closed and paid out. The same split as the profit share above.
     */
    public function profitPeriodMonths(): int
    {
        return (int) $this->current()->profit_period_months;
    }

    /** How often the comprehensive review falls due, in months. */
    public function settlementPeriodMonths(): int
    {
        return (int) $this->current()->settlement_period_months;
    }

    /**
     * How many days after a period opens that capital may still join **that** period.
     *
     * Read at the moment a capital request is made, to decide whether it takes effect now or
     * waits for the next period. Never read backwards.
     */
    public function entryGraceDays(): int
    {
        return (int) $this->current()->entry_grace_days;
    }

    /**
     * How many months capital must stay in a pool before its owner may ask for it back.
     *
     * **Read when the request is made, never when it is paid.** An exit already queued was
     * legitimate the day it was asked for, and lengthening the term tomorrow must not strand it —
     * the same standing every setting here has: it decides what happens next and never rewrites
     * what already did.
     *
     * Zero is no minimum, and is what this system did before the setting existed.
     */
    public function minimumTermMonths(): int
    {
        return (int) $this->current()->minimum_term_months;
    }

    public function update(CompanySettingsData $data, ?int $actorId): CompanySetting
    {
        $settings = $this->current();

        $settings->fill([
            'investor_profit_share_percent' => $data->investorProfitSharePercent,
            'profit_period_months' => $data->profitPeriodMonths,
            'settlement_period_months' => $data->settlementPeriodMonths,
            'entry_grace_days' => $data->entryGraceDays,
            'minimum_term_months' => $data->minimumTermMonths,
        ]);
        $settings->updated_by = $actorId;
        $settings->save();

        return $settings;
    }
}
