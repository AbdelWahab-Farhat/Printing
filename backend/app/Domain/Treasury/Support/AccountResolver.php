<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Exceptions\NoDefaultAccount;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasurySetting;
use Illuminate\Support\Collection;

/**
 * Which account a payment lands in — the three rules of TREASURY-DESIGN §٥, written once.
 *
 * 1. The account the person chose, if it fits the method.
 * 2. For cash on an order waiting at a branch, that branch's box (§١٩).
 * 3. Otherwise the one account *they* hold that fits — Ali lands in «مصرف علي».
 * 4. Otherwise the default of the method's kind.
 *
 * **Rule 3 always answers**, which is what keeps every existing screen working: today's app
 * sends no account, and the migration seeded a default for every kind.
 */
final class AccountResolver
{
    /**
     * @param  bool  $incoming  money arriving (a payment) may land in custody; money leaving may not
     *
     * @throws AccountDoesNotFitMethod
     * @throws NoDefaultAccount
     */
    public function forMethod(
        string $method,
        ?int $actorId,
        ?int $chosenId,
        bool $incoming,
        string $field = 'treasury_account_id',
        ?int $pickupCityId = null,
    ): TreasuryAccount {
        $kinds = $this->kindsFor($method, $incoming);

        if ($chosenId !== null) {
            return $this->chosen($chosenId, $kinds, $incoming, $field);
        }

        return $this->officeBox($pickupCityId, $kinds)
            ?? $this->heldBy($actorId, $kinds)
            ?? $this->defaultOf($kinds[0]);
    }

    /**
     * The cash box of the branch the order waits at — §١٩. Before the person's own account,
     * because the box is where the cash physically is. Cash only: a card at the branch still
     * lands in the bank.
     *
     * @param  non-empty-list<AccountKind>  $kinds
     */
    private function officeBox(?int $pickupCityId, array $kinds): ?TreasuryAccount
    {
        if ($pickupCityId === null || ! in_array(AccountKind::Cash, $kinds, true)) {
            return null;
        }

        return TreasuryAccount::query()
            ->active()
            ->where('kind', AccountKind::Cash->value)
            ->where('pickup_city_id', $pickupCityId)
            ->first();
    }

    /**
     * What a picker offers for a method, and which one it should open on.
     *
     * @return array{accounts: Collection<int, TreasuryAccount>, suggested: TreasuryAccount}
     */
    public function options(string $method, ?int $actorId, bool $incoming, ?int $pickupCityId = null): array
    {
        $kinds = $this->kindsFor($method, $incoming);

        $accounts = TreasuryAccount::query()
            ->active()
            ->whereIn('kind', array_map(fn (AccountKind $kind) => $kind->value, $kinds))
            // Custody is where Nawris or a driver holds money; nobody *picks* Nawris by hand —
            // the webhook does. A driver's own custody is offered to that driver alone.
            ->where(fn ($q) => $q->whereNull('system_code'))
            ->where(fn ($q) => $q->where('kind', '<>', AccountKind::Custody->value)
                ->orWhere('holder_user_id', $actorId))
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get();

        return [
            'accounts' => $accounts,
            'suggested' => $this->officeBox($pickupCityId, $kinds)
                ?? $this->heldBy($actorId, $kinds)
                ?? $this->defaultOf($kinds[0]),
        ];
    }

    /**
     * An account code depends on — the Nawris custody.
     *
     * @throws NoDefaultAccount
     */
    public function system(string $code): TreasuryAccount
    {
        return TreasuryAccount::query()->where('system_code', $code)->first()
            ?? throw NoDefaultAccount::system($code);
    }

    /**
     * @throws NoDefaultAccount
     */
    public function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->first()
            ?? throw NoDefaultAccount::forKind($kind->label());
    }

    /**
     * @return non-empty-list<AccountKind>
     */
    private function kindsFor(string $method, bool $incoming): array
    {
        $kinds = AccountKind::forMethod($method);

        if (! $incoming) {
            $kinds = array_values(array_filter($kinds, fn (AccountKind $kind) => $kind->spendable()));
        }

        if ($kinds === []) {
            throw AccountDoesNotFitMethod::unknownMethod($method);
        }

        return $kinds;
    }

    /**
     * @param  list<AccountKind>  $kinds
     */
    private function chosen(int $id, array $kinds, bool $incoming, string $field): TreasuryAccount
    {
        $account = TreasuryAccount::query()->findOrFail($id);

        if (! $account->is_active) {
            throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
        }

        if (! $incoming && ! $account->kind->spendable()) {
            throw AccountDoesNotFitMethod::custody((string) $account->name, $field);
        }

        if (! in_array($account->kind, $kinds, true)) {
            throw AccountDoesNotFitMethod::kind((string) $account->name, $account->kind->label(), $field);
        }

        return $account;
    }

    /**
     * The one account this person holds that fits — and only if exactly one does. Two would be a
     * guess, and a guess about where money is does more harm than the plain default.
     *
     * @param  list<AccountKind>  $kinds
     */
    private function heldBy(?int $actorId, array $kinds): ?TreasuryAccount
    {
        // «الحساب الشخصي أولاً» switched off in «إعدادات المالية»: everything falls to the
        // method's default unless somebody picks.
        if ($actorId === null || ! TreasurySetting::current()->own_account_first) {
            return null;
        }

        $held = TreasuryAccount::query()
            ->active()
            ->where('holder_user_id', $actorId)
            ->whereIn('kind', array_map(fn (AccountKind $kind) => $kind->value, $kinds))
            ->limit(2)
            ->get();

        return $held->count() === 1 ? $held->first() : null;
    }
}
