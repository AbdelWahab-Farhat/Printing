<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\AccountChangeRefused;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Support\SettlesIntoRule;
use Illuminate\Support\Facades\DB;

/**
 * Opens a new account — «مصرف علي», a second bank, a driver's custody.
 *
 * Starts at nothing, like every account: money arrives by movement, the first of which is
 * usually its opening count.
 */
final class CreateTreasuryAccount
{
    public function __construct(private readonly MakeSoleDefault $makeSoleDefault) {}

    public function __invoke(AccountData $data, ?int $actorId): TreasuryAccount
    {
        $kind = $data->kind ?? AccountKind::Cash;

        if ($data->isDefault === true && ! $kind->spendable()) {
            throw $kind === AccountKind::Payable
                ? AccountChangeRefused::payableCannotBeDefault()
                : AccountChangeRefused::custodyCannotBeDefault();
        }

        SettlesIntoRule::check($kind, $data->settlesIntoAccountId);

        if ($data->pickupCityId !== null && $kind !== AccountKind::Cash) {
            throw AccountChangeRefused::onlyCashServesAnOffice();
        }

        return DB::transaction(function () use ($data, $kind, $actorId): TreasuryAccount {
            $account = new TreasuryAccount([
                'name' => $data->name,
                'holder_user_id' => $data->holderUserId,
                'is_default' => false,
                'is_active' => true,
                'is_collected' => $data->isCollected ?? true,
                'notes' => $data->notes,
            ]);

            $account->kind = $kind;
            $account->settles_into_account_id = $data->settlesIntoAccountId;

            if ($data->pickupCityId !== null) {
                $this->freeOffice($data->pickupCityId);
                $account->pickup_city_id = $data->pickupCityId;
            }
            $account->currency = 'LYD';
            $account->created_by = $actorId;
            $account->save();

            if ($data->isDefault === true) {
                ($this->makeSoleDefault)($account);
            }

            return $account->refresh();
        });
    }

    /** One box per branch: linking a new one unlinks the old, as a new default does. */
    private function freeOffice(int $cityId): void
    {
        TreasuryAccount::query()->where('pickup_city_id', $cityId)->get()
            ->each(fn (TreasuryAccount $old) => $old->forceFill(['pickup_city_id' => null])->save());
    }
}
