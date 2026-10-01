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
 * 1. The account the person chose, if it fits the method — and is theirs to choose: never a
 *    system account (Nawris), never a colleague's custody.
 * 2. For cash on an order whose Nawris parcel is still on the road, Nawris's custody — the money
 *    is in the courier's hand, and «تم التسوية» carries it on.
 * 3. For cash *arriving* on an order waiting at a branch, that branch's box (§١٩).
 * 4. Otherwise the one account *they* hold that fits — Ali lands in «مصرف علي».
 * 5. Otherwise the default of the method's kind.
 *
 * **Rule 5 always answers**, which is what keeps every existing screen working: today's app
 * sends no account, and the migration seeded a default for every kind.
 *
 * **والقاعدةُ نفسُها تجيب الدفعةَ والشاشة**: {@see options()} يقترح ما يختاره {@see forMethod()}
 * فعلاً، فلا يسمّي «تلقائي» حساباً ويُسجَّل المالُ في غيره.
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
        bool $carrierHolds = false,
    ): TreasuryAccount {
        $kinds = $this->kindsFor($method, $incoming);

        if ($chosenId !== null) {
            return $this->chosen($chosenId, $kinds, $incoming, $field, $actorId);
        }

        return $this->automatic($kinds, $actorId, $incoming, $pickupCityId, $carrierHolds);
    }

    /**
     * القواعد ٢–٥ حين لم يختر أحد: ما يُسجَّل فيه المالُ فعلاً، وما يسمّيه «تلقائي».
     *
     * @param  non-empty-list<AccountKind>  $kinds
     */
    private function automatic(
        array $kinds,
        ?int $actorId,
        bool $incoming,
        ?int $pickupCityId,
        bool $carrierHolds,
    ): TreasuryAccount {
        $withCarrier = $carrierHolds && $incoming && in_array(AccountKind::Custody, $kinds, true)
            ? $this->system(TreasuryAccount::NAWRIS)
            : null;

        // خزنةُ المكتب للمال الداخل وحده: الردُّ والمصروف لا يُصرفان من صندوق فرعٍ لم يُفتح لهما.
        return $withCarrier
            ?? ($incoming ? $this->officeBox($pickupCityId, $kinds) : null)
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
    public function options(
        string $method,
        ?int $actorId,
        bool $incoming,
        ?int $pickupCityId = null,
        bool $carrierHolds = false,
    ): array {
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
            'suggested' => $this->automatic($kinds, $actorId, $incoming, $pickupCityId, $carrierHolds),
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
    private function chosen(int $id, array $kinds, bool $incoming, string $field, ?int $actorId): TreasuryAccount
    {
        $account = TreasuryAccount::query()->findOrFail($id);

        if (! $account->is_active) {
            throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
        }

        // **ما تخفيه الشاشة يرفضه الخادم أيضاً**: القائمة لا تعرض النورس ولا عهدةَ غيرك، لكنّ
        // رقمه يصل في طلبٍ يُكتب باليد. حساب النورس يسمّيه الـ webhook من طريقٍ آخر — انظر
        // `OrderPaymentData::intoSystemAccount()` — فلا يمرّ هنا أبداً.
        if ($account->system_code !== null) {
            throw AccountDoesNotFitMethod::system((string) $account->name, $field);
        }

        if ($account->kind === AccountKind::Custody && (int) $account->holder_user_id !== $actorId) {
            throw AccountDoesNotFitMethod::notYours((string) $account->name, $field);
        }

        if ($account->kind === AccountKind::Payable) {
            throw AccountDoesNotFitMethod::payable((string) $account->name, $field);
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
