<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\AccountChangeRefused;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use Carbon\CarbonImmutable;

/**
 * «إعدادات المالية» — the owner's switches over the treasury's rules.
 *
 * Only what was sent changes; a sent null `locked_until` unlocks everything. Every change is in
 * the audit trail with the person who made it, because «من فتح الشهر المقفل؟» is a question the
 * trail exists to answer.
 */
final class UpdateTreasurySettings
{
    /**
     * @param  array<string, mixed>  $values  the validated request
     */
    public function __invoke(array $values, ?int $actorId): TreasurySetting
    {
        // A kind is collected into an active account of that kind — collecting the bank into a
        // cash box would say the transfer money is sitting in a drawer. Never into a system
        // account: «Ezone» is a wallet, and only EzonePay fills it (CUSTOMER-WALLET §٥).
        foreach ([AccountKind::Cash, AccountKind::Bank, AccountKind::Wallet] as $kind) {
            $field = "collect_{$kind->value}_into_id";

            if (($values[$field] ?? null) === null) {
                continue;
            }

            $target = TreasuryAccount::query()->findOrFail((int) $values[$field]);

            // Never into dollars either: what is collected is orders' money, which is dinars.
            if (! $target->is_active || $target->kind !== $kind || $target->isSystem() || $target->isDollar()) {
                throw AccountChangeRefused::cannotCollectInto((string) $target->name, $kind->label(), $field);
            }
        }

        $settings = TreasurySetting::current();

        // «إضافة الرواتب تلقائياً»: the date is the server's, never the request's. Turning the
        // switch on never pays the month already running, so the run's first 1st is next
        // month's. Turning it off forgets the date; on again starts counting afresh.
        if (array_key_exists('auto_salaries', $values)) {
            $on = (bool) $values['auto_salaries'];

            if ($on && ! $settings->auto_salaries) {
                $values['auto_salaries_from'] = CarbonImmutable::now((string) config('app.business_timezone', 'Africa/Tripoli'))
                    ->startOfMonth()
                    ->addMonthNoOverflow()
                    ->toDateString();
            } elseif (! $on) {
                $values['auto_salaries_from'] = null;
            }
        }

        $settings->fill($values);
        $settings->updated_by = $actorId;
        $settings->save();

        return $settings->refresh();
    }
}
