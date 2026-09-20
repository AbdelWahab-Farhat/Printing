<?php

declare(strict_types=1);

namespace App\Domain\Settings;

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
     * المدد الأربع التي يحكم بها الصندوقُ نفسَه، لمن يفتح فترةً جديدة.
     *
     * **تُقرأ مرّةً وتُنسَخ على صفّ الفترة**، ولا تُقرأ من هنا بعدها — فمن أقفل سبتمبر على شهرٍ
     * واحد يبقى شهراً واحداً ولو صارت المدةُ شهرين في أكتوبر. وهو الانضباطُ نفسه الذي تمشي عليه
     * {@see investorProfitSharePercent()} بجانبها.
     *
     * تُسلَّم أربعتُها معاً لا واحدةً واحدة: فتحُ الفترة يحتاجها كلَّها في اللحظة نفسها، وأربعُ
     * قراءاتٍ لصفٍّ واحد تفتح أربعَ نوافذَ يتغيّر فيها الإعداد بين واحدةٍ وأختها.
     *
     * @return array{period_months: int, subscription_window_days: int, settlement_months: int, capital_lock_months: int}
     */
    public function investmentDurations(): array
    {
        $settings = $this->current();

        return [
            'period_months' => (int) $settings->investment_period_months,
            'subscription_window_days' => (int) $settings->investment_subscription_window_days,
            'settlement_months' => (int) $settings->investment_settlement_months,
            'capital_lock_months' => (int) $settings->investment_capital_lock_months,
        ];
    }

    /**
     * @param  array<string, int>  $durations  ما وصل من المدد، بأسماء أعمدتها. الفارغُ يعني
     *                                         «لم تُذكر» فتبقى كما هي — لا «صفّرها».
     */
    public function update(string $investorProfitSharePercent, ?int $actorId, array $durations = []): CompanySetting
    {
        $settings = $this->current();

        $settings->fill([
            'investor_profit_share_percent' => $investorProfitSharePercent,
            ...$durations,
        ]);
        $settings->updated_by = $actorId;
        $settings->save();

        return $settings;
    }
}
