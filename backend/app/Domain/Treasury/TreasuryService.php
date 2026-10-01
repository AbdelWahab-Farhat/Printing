<?php

declare(strict_types=1);

namespace App\Domain\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Actions\CollectOrderMoney;
use App\Domain\Treasury\Actions\CreateTreasuryAccount;
use App\Domain\Treasury\Actions\PostMovement;
use App\Domain\Treasury\Actions\RecordOperation;
use App\Domain\Treasury\Actions\ReverseMovement;
use App\Domain\Treasury\Actions\ReverseOperation;
use App\Domain\Treasury\Actions\SaveExpenseCategory;
use App\Domain\Treasury\Actions\SettleCustody;
use App\Domain\Treasury\Actions\UpdateTreasuryAccount;
use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Exceptions\InsufficientBalance;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Queries\AccountLedger;
use App\Domain\Treasury\Queries\AccountTotals;
use App\Domain\Treasury\Queries\CustodyForOrder;
use App\Domain\Treasury\Support\AccountResolver;
use App\Domain\Treasury\Support\BalanceVisibility;
use DateTimeInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;

/**
 * The door to الحسابات والخزائن.
 *
 * **Two kinds of caller.** The treasury screens, through the controllers; and every context where
 * money moves — Order, Carrier, Shortage, Investor, Vendor — which call {@see accountFor()} to
 * decide where a payment lands, {@see post()} to record it, and {@see reverseSource()} to undo it,
 * all inside their own transaction. None of them is imported back: this context knows sources
 * only as a morph alias and an id.
 */
final class TreasuryService
{
    public function __construct(
        private readonly AccountResolver $resolver,
        private readonly AccountBalances $balances,
        private readonly AccountTotals $totals,
        private readonly AccountLedger $ledger,
        private readonly PostMovement $postMovement,
        private readonly ReverseMovement $reverseMovement,
        private readonly RecordOperation $recordOperation,
        private readonly ReverseOperation $reverseOperation,
        private readonly CreateTreasuryAccount $createAccount,
        private readonly UpdateTreasuryAccount $updateAccount,
        private readonly SaveExpenseCategory $saveCategory,
        private readonly SettleCustody $settleCustody,
        private readonly CollectOrderMoney $collectOrderMoney,
        private readonly CustodyForOrder $custody,
    ) {}

    // ── accounts ────────────────────────────────────────────────────────────────────────

    /**
     * Every account the viewer may read, each carrying its balance as `balance`.
     *
     * Holders of `treasury.view` see all of them; anybody else sees the accounts in their name.
     *
     * @return Collection<int, TreasuryAccount>
     */
    public function accountsFor(User $viewer, bool $activeOnly = false): Collection
    {
        $accounts = TreasuryAccount::query()
            ->when(! $this->canViewAll($viewer), fn ($q) => $q->where('holder_user_id', $viewer->getKey()))
            ->when($activeOnly, fn ($q) => $q->active())
            ->with(['holder', 'settlesInto'])
            ->orderByRaw("CASE kind WHEN 'cash' THEN 1 WHEN 'bank' THEN 2 WHEN 'wallet' THEN 3 ELSE 4 END")
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get();

        return $this->withBalances($accounts);
    }

    public function canViewAll(User $viewer): bool
    {
        return $viewer->can(PermissionName::ViewTreasury->value);
    }

    public function canRead(User $viewer, TreasuryAccount $account): bool
    {
        return $this->canViewAll($viewer) || $account->isHeldBy($viewer);
    }

    /**
     * @param  Collection<int, TreasuryAccount>  $accounts
     * @return Collection<int, TreasuryAccount>
     */
    public function withBalances(Collection $accounts): Collection
    {
        $balances = $this->balances->forAccounts(
            $accounts->map(fn (TreasuryAccount $account) => (int) $account->getKey())->all(),
        );

        return $accounts->each(fn (TreasuryAccount $account) => $account->setAttribute(
            'balance',
            $balances[(int) $account->getKey()] ?? '0.00',
        ));
    }

    public function balanceOf(TreasuryAccount $account): string
    {
        return $this->balances->of((int) $account->getKey());
    }

    /**
     * @return array<string, mixed>
     */
    public function totalsOf(TreasuryAccount $account): array
    {
        return $this->totals->of((int) $account->getKey());
    }

    /**
     * @param  array{from?: ?string, to?: ?string, kind?: ?string, order_id?: ?int}  $filters
     * @return LengthAwarePaginator<int, TreasuryMovement>
     */
    public function ledger(TreasuryAccount $account, array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->ledger->page((int) $account->getKey(), $filters, $perPage);
    }

    public function createAccount(AccountData $data, ?User $actor): TreasuryAccount
    {
        return ($this->createAccount)($data, $actor?->getKey() === null ? null : (int) $actor->getKey());
    }

    public function updateAccount(TreasuryAccount $account, AccountData $data): TreasuryAccount
    {
        return ($this->updateAccount)($account, $data);
    }

    /**
     * What a picker offers for a method and which it opens on.
     *
     * @return array{accounts: \Illuminate\Support\Collection<int, TreasuryAccount>, suggested: TreasuryAccount}
     */
    public function accountOptions(string $method, ?User $actor, bool $incoming, ?int $pickupCityId = null): array
    {
        return $this->resolver->options(
            $method,
            $actor?->getKey() === null ? null : (int) $actor->getKey(),
            $incoming,
            $pickupCityId,
        );
    }

    // ── for the contexts where money moves ──────────────────────────────────────────────

    /**
     * Where money paid by this method lands — TREASURY-DESIGN §٥.
     *
     * `$chosenId` is what the person picked, or null to let the rules decide. Money leaving
     * (`$incoming = false`) is never taken from custody. `$pickupCityId` is the branch an order
     * waits at, whose cash box takes its cash (§١٩).
     */
    public function accountFor(
        string $method,
        ?int $actorId,
        ?int $chosenId = null,
        bool $incoming = true,
        string $field = 'treasury_account_id',
        ?int $pickupCityId = null,
    ): TreasuryAccount {
        return $this->resolver->forMethod($method, $actorId, $chosenId, $incoming, $field, $pickupCityId);
    }

    /**
     * An account money may be paid out of by hand, whatever method — for the forms that ask
     * which drawer paid rather than how. Refuses a switched-off account and custody.
     */
    public function spendableAccount(int $id, string $field = 'treasury_account_id'): TreasuryAccount
    {
        $account = TreasuryAccount::query()->findOrFail($id);

        if (! $account->is_active) {
            throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
        }

        if (! $account->kind->spendable()) {
            throw AccountDoesNotFitMethod::custody((string) $account->name, $field);
        }

        return $account;
    }

    /**
     * Refuses money out by hand that the account does not hold — a vendor payment, like the
     * treasury's own withdrawals. Locks the account row first, so two payments cannot both spend
     * the last dinar. Call inside the transaction that will post the movement.
     */
    /** «إعدادات المالية» — the owner's switches. */
    public function settings(): TreasurySetting
    {
        return TreasurySetting::current();
    }

    /**
     * Refuses money out by hand dated inside the locked period — a vendor payment, like the
     * treasury's own operations. Nothing is locked until the owner sets a date.
     */
    public function guardNotLocked(DateTimeInterface $day, string $field = 'paid_at'): void
    {
        $settings = TreasurySetting::current();

        if ($settings->locks(Carbon::instance($day))) {
            throw OperationRefused::locked($settings->locked_until->toDateString(), $field);
        }
    }

    /**
     * @param  ?int  $actorId  من يسجّل — رسالةُ الرفض تذكر الرصيد لمن يراه وحده
     *                         ({@see BalanceVisibility})، ولا تذكره حين لا يُعرف من يسأل
     */
    public function guardCanSpend(
        TreasuryAccount $account,
        string $amount,
        string $field = 'amount',
        ?int $actorId = null,
    ): void {
        if (! TreasurySetting::current()->block_overdraft) {
            return;
        }

        TreasuryAccount::query()->whereKey($account->getKey())->lockForUpdate()->first();

        $balance = $this->balances->of((int) $account->getKey());

        if (bccomp($amount, $balance, 2) > 0) {
            throw InsufficientBalance::make(
                (string) $account->name,
                (new BalanceVisibility)->allows($account, $actorId) ? $balance : null,
                $amount,
                $field,
            );
        }
    }

    /** An account code depends on — `TreasuryAccount::NAWRIS`. */
    public function systemAccount(string $code): TreasuryAccount
    {
        return $this->resolver->system($code);
    }

    /** Records one movement. Call it inside the transaction that wrote its source. */
    public function post(MovementData $data): TreasuryMovement
    {
        return ($this->postMovement)($data);
    }

    /**
     * Undoes everything a source posted that is still standing, and says what it wrote.
     *
     * Safe to call for a source that posted nothing — a payment from before the treasury, a
     * write-off — which returns an empty list rather than failing.
     *
     * @return list<TreasuryMovement>
     */
    public function reverseSource(string $sourceType, int $sourceId, ?string $notes, ?int $actorId): array
    {
        $reversed = [];

        foreach ($this->liveMovementsOf($sourceType, $sourceId) as $movement) {
            $mirror = ($this->reverseMovement)($movement, $notes, $actorId);

            if ($mirror !== null) {
                $reversed[] = $mirror;
            }
        }

        return $reversed;
    }

    /**
     * The movements a source posted that nothing has undone yet.
     *
     * @return Collection<int, TreasuryMovement>
     */
    public function liveMovementsOf(string $sourceType, int $sourceId): Collection
    {
        return TreasuryMovement::query()
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->whereNull('reverses_movement_id')
            ->whereDoesntHave('reversedBy')
            ->orderBy('id')
            ->get();
    }

    // ── settlement ──────────────────────────────────────────────────────────────────────

    /**
     * What Nawris or a driver still holds for this order, by account name — for the settle
     * screen's hint. Empty when the money is already where it belongs.
     *
     * @return list<array{account_id: int, name: string, amount: string}>
     */
    public function custodyOf(int $orderId): array
    {
        $held = $this->custody->of($orderId);

        if ($held === []) {
            return [];
        }

        $names = TreasuryAccount::query()->whereIn('id', array_keys($held))->pluck('name', 'id');

        $list = [];

        foreach ($held as $accountId => $amount) {
            $list[] = ['account_id' => $accountId, 'name' => (string) $names[$accountId], 'amount' => $amount];
        }

        return $list;
    }

    /**
     * Carries an order's custody to the account it reached — «تم التسوية», TREASURY-DESIGN §٦ —
     * then collects what landed in «مصرف علي» or a branch's box into its kind's collecting
     * account, where the owner switched that on (§١٨). Call inside the status change's
     * transaction. Null when no custody was held.
     *
     * @param  bool  $collect  false for the import of old orders: their money was filed in the
     *                         defaults already, and a switch turned on today says nothing of then
     */
    public function settleCustody(
        int $orderId,
        ?int $destinationId,
        ?string $fee,
        ?int $actorId,
        ?string $orderCode = null,
        ?DateTimeInterface $occurredAt = null,
        bool $collect = true,
    ): ?TreasuryOperation {
        // A past date only for the import of old orders, which were settled on their own day.
        $occurredAt ??= now();

        $settlement = ($this->settleCustody)($orderId, $destinationId, $fee, $actorId, $occurredAt, $orderCode);

        if ($collect) {
            ($this->collectOrderMoney)($orderId, $actorId, $occurredAt, $orderCode, $destinationId);
        }

        return $settlement;
    }

    /** Whether any account has its opening count yet — the import of old payments refuses after. */
    public function hasAnyOpening(): bool
    {
        return TreasuryOperation::query()->where('type', OperationType::Opening->value)->exists();
    }

    /**
     * Undoes the order's standing settlement, putting the money back in custody.
     *
     * Called before a payment it carried is reversed, and by un-settling an order. Does nothing
     * when there is none — an order paid straight into the bank never had one.
     *
     * @param  ?int  $accountId  only the settlements that moved money out of this account — the
     *                           reversed payment's. Omar's collection stays when Ali's payment is
     *                           reversed. Null: every one, as un-settling the order needs.
     */
    public function unwindSettlementOf(int $orderId, string $reason, ?int $actorId, ?int $accountId = null): void
    {
        $standing = TreasuryOperation::query()
            ->where('type', OperationType::Settlement->value)
            ->where('order_id', $orderId)
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy')
            ->when($accountId !== null, fn ($q) => $q->whereHas('movements', fn ($m) => $m
                ->where('account_id', $accountId)
                ->where('direction', MovementDirection::Out->value)))
            ->get();

        foreach ($standing as $settlement) {
            ($this->reverseOperation)($settlement, $reason, $actorId, byHand: false);
        }
    }

    /**
     * Every account a person may pick for money, with the methods each one takes — the list a
     * form filters as the method changes. Nawris is left out: only its webhook writes to it.
     *
     * @return list<array{value: string, label: string, kind: string, methods: list<string>, is_default: bool}>
     */
    public function pickableAccounts(): array
    {
        return TreasuryAccount::query()
            ->active()
            ->whereNull('system_code')
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get()
            ->map(fn (TreasuryAccount $account) => [
                'value' => (string) $account->getKey(),
                'label' => (string) $account->name,
                'kind' => $account->kind->value,
                'methods' => array_values(array_filter(
                    ['cash', 'bank_transfer', 'bank_card', 'libyana'],
                    fn (string $method) => in_array($account->kind, AccountKind::forMethod($method), true),
                )),
                'is_default' => (bool) $account->is_default,
            ])
            ->values()
            ->all();
    }

    // ── hand operations ─────────────────────────────────────────────────────────────────

    public function recordOperation(OperationData $data, ?User $actor): TreasuryOperation
    {
        return ($this->recordOperation)($data, $actor?->getKey() === null ? null : (int) $actor->getKey());
    }

    public function reverseOperation(TreasuryOperation $operation, string $reason, ?User $actor): TreasuryOperation
    {
        return ($this->reverseOperation)($operation, $reason, $actor?->getKey() === null ? null : (int) $actor->getKey());
    }

    /**
     * @param  array{type?: ?string, account_id?: ?int, category_id?: ?int, from?: ?string, to?: ?string}  $filters
     * @return LengthAwarePaginator<int, TreasuryOperation>
     */
    public function operations(array $filters, int $perPage): LengthAwarePaginator
    {
        return TreasuryOperation::query()
            ->when($filters['type'] ?? null, fn ($q, $type) => $q->where('type', $type))
            ->when($filters['account_id'] ?? null, fn ($q, $id) => $q->where(
                fn ($q) => $q->where('from_account_id', $id)->orWhere('to_account_id', $id),
            ))
            ->when($filters['category_id'] ?? null, fn ($q, $id) => $q->where('category_id', $id))
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->whereDate('occurred_at', '>=', $from))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->whereDate('occurred_at', '<=', $to))
            ->with(self::OPERATION_RELATIONS)
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    public function loadOperation(TreasuryOperation $operation): TreasuryOperation
    {
        return $operation->load(self::OPERATION_RELATIONS);
    }

    public const OPERATION_RELATIONS = [
        'fromAccount', 'toAccount', 'category', 'employee', 'recorder', 'reversedBy', 'reversesOperation',
    ];

    // ── expense categories ──────────────────────────────────────────────────────────────

    /**
     * @return Collection<int, ExpenseCategory>
     */
    public function categories(bool $activeOnly = false): Collection
    {
        return ExpenseCategory::query()
            ->when($activeOnly, fn ($q) => $q->where('is_active', true))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();
    }

    /**
     * @param  array{name?: string, requires_employee?: bool, is_active?: bool, sort_order?: int}  $values
     */
    public function saveCategory(?ExpenseCategory $category, array $values): ExpenseCategory
    {
        return ($this->saveCategory)($category, $values);
    }
}
