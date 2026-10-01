<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\AccountChangeRefused;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Support\Money;
use App\Domain\Treasury\Support\SettlesIntoRule;
use Illuminate\Support\Facades\DB;

/**
 * Renames an account, changes whose it is, switches it off, or makes it the default.
 *
 * **Its kind never changes** — the kind decides which payments may land in it, and changing it
 * would re-file its past. **And no change may leave a method with nowhere to land:** a default
 * cannot be switched off or stripped of the title, only replaced by another; and the Nawris
 * account cannot be switched off at all, because the webhook writes to it whatever anyone thinks.
 */
final class UpdateTreasuryAccount
{
    public function __construct(
        private readonly MakeSoleDefault $makeSoleDefault,
        private readonly AccountBalances $balances,
    ) {}

    public function __invoke(TreasuryAccount $account, AccountData $data): TreasuryAccount
    {
        return DB::transaction(function () use ($account, $data): TreasuryAccount {
            $locked = TreasuryAccount::query()->whereKey($account->getKey())->lockForUpdate()->firstOrFail();

            if ($data->isDefault === false && $locked->is_default) {
                throw AccountChangeRefused::defaultCannotBeUnset((string) $locked->name);
            }

            if ($data->isDefault === true && ! $locked->kind->spendable()) {
                throw $locked->kind === AccountKind::Payable
                    ? AccountChangeRefused::payableCannotBeDefault()
                    : AccountChangeRefused::custodyCannotBeDefault();
            }

            // A vendor's account carries the vendor's name and stays open while the vendor does;
            // only its notes are anybody's to change here.
            if ($locked->isVendorPayable()
                && (($data->name !== null && $data->name !== $locked->name) || $data->hasHolder || $data->isActive === false)) {
                throw AccountChangeRefused::vendorPayableIsManagedByTheVendor((string) $locked->name);
            }

            // `MakeSoleDefault` يفعّل ما يجعله افتراضياً، فطلبٌ يقول الأمرين كان يُعطَّل ثم يُعاد
            // تفعيلُه صامتاً — أو يصطدم بقيد الشكل على الافتراضيّ القائم فيخرج 500.
            if ($data->isDefault === true && $data->isActive === false) {
                throw AccountChangeRefused::defaultAndOffAtOnce((string) $locked->name);
            }

            if ($data->isActive === false && $locked->is_default && $data->isDefault !== true) {
                throw AccountChangeRefused::defaultCannotBeSwitchedOff((string) $locked->name);
            }

            if ($data->isActive === false && $locked->isSystem()) {
                throw AccountChangeRefused::systemCannotBeSwitchedOff((string) $locked->name);
            }

            // حين يُطفأ مفعّلٌ وحده: المعطَّلُ أصلاً يُعدَّل اسمُه وملاحظتُه ولو بقي فيه مال.
            if ($data->isActive === false && $locked->is_active && $this->holdsMoney($locked)) {
                throw AccountChangeRefused::stillHoldsMoney((string) $locked->name);
            }

            $changes = [];

            if ($data->name !== null) {
                $changes['name'] = $data->name;
            }

            if ($data->hasHolder) {
                $changes['holder_user_id'] = $data->holderUserId;
            }

            if ($data->isActive !== null) {
                $changes['is_active'] = $data->isActive;
            }

            if ($data->isCollected !== null) {
                $changes['is_collected'] = $data->isCollected;
            }

            if ($data->hasNotes) {
                $changes['notes'] = $data->notes;
            }

            if ($data->hasSettlesInto) {
                SettlesIntoRule::check($locked->kind, $data->settlesIntoAccountId);

                // Not fillable: where custody money goes is decided here, by the rule above.
                $locked->settles_into_account_id = $data->settlesIntoAccountId;
            }

            if ($data->hasPickupCity && $data->pickupCityId !== $locked->pickup_city_id) {
                if ($data->pickupCityId !== null && $locked->kind !== AccountKind::Cash) {
                    throw AccountChangeRefused::onlyCashServesAnOffice();
                }

                // One box per branch: linking this one unlinks whichever served it before —
                // saved through the model, so the old box's trail says it lost the branch.
                if ($data->pickupCityId !== null) {
                    TreasuryAccount::query()
                        ->where('pickup_city_id', $data->pickupCityId)
                        ->whereKeyNot($locked->getKey())
                        ->get()
                        ->each(fn (TreasuryAccount $old) => $old->forceFill(['pickup_city_id' => null])->save());
                }

                // Not fillable, like «تُسوّى إلى»: which box takes a branch's cash is decided here.
                $locked->pickup_city_id = $data->pickupCityId;
            }

            $locked->fill($changes)->save();

            if ($data->isDefault === true && ! $locked->is_default) {
                ($this->makeSoleDefault)($locked);
            }

            return $locked->refresh();
        });
    }

    private function holdsMoney(TreasuryAccount $account): bool
    {
        return bccomp($this->balances->of((int) $account->getKey()), '0', Money::SCALE) !== 0;
    }
}
