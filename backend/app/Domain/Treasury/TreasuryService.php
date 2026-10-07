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
use App\Domain\Treasury\Actions\SettlePayment;
use App\Domain\Treasury\Actions\SyncDebt;
use App\Domain\Treasury\Actions\UpdateTreasuryAccount;
use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
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
use App\Domain\Treasury\Queries\ExpenseLedger;
use App\Domain\Treasury\Queries\OrderMoneyByAccount;
use App\Domain\Treasury\Support\AccountResolver;
use App\Domain\Treasury\Support\BalanceVisibility;
use App\Domain\Treasury\Support\CheckpointFloor;
use App\Domain\Treasury\Support\Money;
use App\Support\RequestMemo;
use DateTimeInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;

/**
 * The door to الحسابات والكاش.
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
        private readonly ExpenseLedger $expenses,
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
        private readonly OrderMoneyByAccount $orderMoney,
        private readonly SyncDebt $syncDebt,
        private readonly SettlePayment $settlePayment,
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
            ->orderByRaw("CASE kind WHEN 'cash' THEN 1 WHEN 'bank' THEN 2 WHEN 'wallet' THEN 3 WHEN 'custody' THEN 4 ELSE 5 END")
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

    /**
     * «المصاريف» — every account's expenses on one page, and what they add up to (§٢١).
     *
     * @param  array{from?: ?string, to?: ?string, category_id?: ?int, account_id?: ?int}  $filters
     * @return array{page: LengthAwarePaginator<int, TreasuryMovement>, total: string}
     */
    public function expenses(array $filters, int $perPage): array
    {
        return [
            'page' => $this->expenses->page($filters, $perPage),
            'total' => $this->expenses->total($filters),
        ];
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
    public function accountOptions(
        string $method,
        ?User $actor,
        bool $incoming,
        ?int $pickupCityId = null,
        bool $carrierHolds = false,
    ): array {
        return $this->resolver->options(
            $method,
            $actor?->getKey() === null ? null : (int) $actor->getKey(),
            $incoming,
            $pickupCityId,
            $carrierHolds,
        );
    }

    // ── for the contexts where money moves ──────────────────────────────────────────────

    /**
     * Where money paid by this method lands — TREASURY-DESIGN §٥.
     *
     * `$chosenId` is what the person picked, or null to let the rules decide. Money leaving
     * (`$incoming = false`) is never taken from custody. `$pickupCityId` is the branch an order
     * waits at, whose cash box takes its cash (§١٩). `$carrierHolds`: the order's Nawris parcel
     * is still on the road, so cash typed for it is in the courier's hand — Nawris's custody.
     */
    public function accountFor(
        string $method,
        ?int $actorId,
        ?int $chosenId = null,
        bool $incoming = true,
        string $field = 'treasury_account_id',
        ?int $pickupCityId = null,
        bool $carrierHolds = false,
    ): TreasuryAccount {
        return $this->resolver->forMethod($method, $actorId, $chosenId, $incoming, $field, $pickupCityId, $carrierHolds);
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
            throw $account->kind === AccountKind::Payable
                ? AccountDoesNotFitMethod::payable((string) $account->name, $field)
                : AccountDoesNotFitMethod::custody((string) $account->name, $field);
        }

        return $account;
    }

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
     * Refuses money out by hand that the account does not hold — a vendor payment, like the
     * treasury's own withdrawals. Locks the account row first, so two payments cannot both spend
     * the last dinar. Call inside the transaction that will post the movement.
     *
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
     * يعكس ما سجّله المصدر، **أو** — لمصدرٍ من قبل الخزينة لم يُسجَّل له شيء — يكتب الحركةَ
     * المعاكسة التي يصفها `$fallback`.
     *
     * **قاعدةٌ واحدة في موضعٍ واحد** (كانت ثلاثَ نسخٍ متباعدة في الدفعة والمحفظة والنواقص): مصدرٌ
     * مختومٌ بحساب سجّل حركتَه، فعكسُها يكفي ولا بديل؛ ومصدرٌ بلا حساب حسبه يومُ الافتتاح في رصيد
     * حسابِ طريقته (§١١)، فخروجُه — وقد تبيّن أنه لم يكن — يصيب ذلك الحساب.
     *
     * @param  bool  $stamped  هل خُتم على المصدر حسابُه — إذن سُجّلت له حركةٌ يومَ كُتب
     * @param  \Closure(): MovementData  $fallback  كسولةٌ: لا يُسأل عن الحساب البديل إلا عند الحاجة
     */
    public function reverseSourceOrFallback(
        string $sourceType,
        int $sourceId,
        bool $stamped,
        ?string $notes,
        ?int $actorId,
        \Closure $fallback,
    ): void {
        $mirrored = $this->reverseSource($sourceType, $sourceId, $notes, $actorId);

        if ($mirrored !== [] || $stamped) {
            return;
        }

        $this->post($fallback());
    }

    /**
     * Undoes one movement — for a correction that must leave the source's other movements
     * standing. Null when it is already undone.
     */
    public function reverseMovement(TreasuryMovement $movement, ?string $notes, ?int $actorId): ?TreasuryMovement
    {
        return ($this->reverseMovement)($movement, $notes, $actorId);
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

    // ── «علينا» — what is owed (§٢٠) ─────────────────────────────────────────────────────

    /**
     * The vendor's payable, opened the first time anything is owed to them or paid to them.
     *
     * `createOrFirst`, not `firstOrCreate`: two purchase orders raised for a new vendor at once
     * would both miss the lookup, and the second insert meets `treasury_accounts_one_per_vendor`
     * inside a savepoint and reads the first one's row instead of failing.
     */
    public function payableForVendor(int $vendorId, string $vendorName): TreasuryAccount
    {
        $existing = TreasuryAccount::query()->where('vendor_id', $vendorId)->first();

        if ($existing !== null) {
            return $existing;
        }

        return TreasuryAccount::unguarded(fn () => TreasuryAccount::query()->createOrFirst(
            ['vendor_id' => $vendorId],
            [
                'name' => mb_substr($vendorName, 0, 100),
                'kind' => AccountKind::Payable,
                'is_default' => false,
                'is_active' => true,
                'currency' => 'LYD',
            ],
        ));
    }

    /**
     * «مبالغ زائدة للزبائن» — opened the first time a customer pays beyond their order.
     *
     * `createOrFirst` on the system code, for the reason {@see payableForVendor()} gives: two
     * overpayments at once would both miss the lookup, and the second insert meets
     * `treasury_accounts_system_code_unique` and reads the first one's row instead of failing.
     */
    public function customerExcessPayable(): TreasuryAccount
    {
        $existing = TreasuryAccount::query()->where('system_code', TreasuryAccount::CUSTOMER_EXCESS)->first();

        if ($existing !== null) {
            return $existing;
        }

        return TreasuryAccount::unguarded(fn () => TreasuryAccount::query()->createOrFirst(
            ['system_code' => TreasuryAccount::CUSTOMER_EXCESS],
            [
                'name' => 'مبالغ زائدة للزبائن',
                'kind' => AccountKind::Payable,
                'is_default' => false,
                'is_active' => true,
                'currency' => 'LYD',
            ],
        ));
    }

    /** The vendor's payable, if anything was ever owed to them. */
    public function payableIdOfVendor(int $vendorId): ?int
    {
        $id = TreasuryAccount::query()->where('vendor_id', $vendorId)->value('id');

        return $id === null ? null : (int) $id;
    }

    /** A renamed vendor's account follows — it is found by the name on the dashboard. */
    public function renameVendorPayable(int $vendorId, string $vendorName): void
    {
        TreasuryAccount::query()->where('vendor_id', $vendorId)->get()
            ->each(fn (TreasuryAccount $account) => $account->forceFill(['name' => mb_substr($vendorName, 0, 100)])->save());
    }

    /**
     * Makes the debt a source stands for equal `$amount` on `$accountId` — a purchase order's
     * total on its vendor's payable. Null account or zero: nothing owed any more. Call inside the
     * transaction that changed the source. See {@see SyncDebt}.
     */
    public function syncDebt(
        string $sourceType,
        int $sourceId,
        ?int $accountId,
        string $amount,
        DateTimeInterface $firstPostedAt,
        string $notes,
        string $reason,
        ?int $actorId,
    ): void {
        ($this->syncDebt)(
            $sourceType,
            $sourceId,
            MovementKind::Purchase,
            $accountId,
            $amount,
            $firstPostedAt,
            $notes,
            $reason,
            $actorId,
        );
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
     *                         — neither the collection nor where a custody «تُسوّى إلى»
     * @param  string  $accountField  where a refused destination is filed — `fields.…` on the
     *                                status screen
     * @param  array<string, int>  $settlerChoices  kind => the settler's account picked for it,
     *                                              where they hold several (§٢٢)
     */
    public function settleCustody(
        int $orderId,
        ?int $destinationId,
        ?string $fee,
        ?int $actorId,
        ?string $orderCode = null,
        ?DateTimeInterface $occurredAt = null,
        bool $collect = true,
        string $accountField = 'settlement_account_id',
        string $feeField = 'settlement_fee',
        array $settlerChoices = [],
    ): ?TreasuryOperation {
        // A past date only for the import of old orders, which were settled on their own day.
        $occurredAt ??= now();

        $settlement = ($this->settleCustody)(
            $orderId,
            $destinationId,
            $fee,
            $actorId,
            $occurredAt,
            $orderCode,
            accountField: $accountField,
            feeField: $feeField,
            applySettings: $collect,
            choices: $settlerChoices,
        );

        if ($collect) {
            ($this->collectOrderMoney)($orderId, $actorId, $occurredAt, $orderCode, $destinationId, $settlerChoices);
        }

        return $settlement;
    }

    /**
     * What «تم التسوية» will do with this order's money under «التسوية إلى حساب المسوّي» (§٢٢),
     * kind by kind — for the settle screen to say before it happens, and to ask which account
     * where the settler holds several. Null when the switch is off or nobody is settling.
     *
     * Each kind lists what of it the order holds and where — the order's money in every account
     * of the kind, «لا يُجمع» ones included, and the custody under the kind it would land in —
     * the settler's accounts of the kind, and for a kind they hold none of, the collecting account
     * it falls to (null: it stays where it is).
     *
     * Plain arrays, for the status screen in Order to print without knowing a treasury model.
     *
     * @return ?list<array{kind: string, kind_label: string, amount: string, sources: list<array{name: string, amount: string}>, accounts: list<array{value: string, label: string, kind: string, methods: list<string>, is_default: bool}>, fallback: ?string}>
     */
    public function settlerPlan(int $orderId, ?int $actorId): ?array
    {
        if ($actorId === null || ! TreasurySetting::current()->settle_into_settler) {
            return null;
        }

        $sourcesByKind = [];

        foreach ([AccountKind::Cash, AccountKind::Bank, AccountKind::Wallet] as $kind) {
            $held = $this->orderMoney->of($orderId, $kind, [], true);
            $names = TreasuryAccount::query()->whereIn('id', array_keys($held))->pluck('name', 'id');

            foreach ($held as $accountId => $amount) {
                $sourcesByKind[$kind->value][] = ['id' => $accountId, 'name' => (string) $names[$accountId], 'amount' => $amount];
            }
        }

        $landing = $this->settleCustody->landingFor($orderId, $actorId);

        if ($landing !== null) {
            foreach ($this->custodyOf($orderId) as $row) {
                $sourcesByKind[$landing->kind->value][] = ['id' => $row['account_id'], 'name' => $row['name'], 'amount' => $row['amount']];
            }
        }

        $plan = [];

        foreach ([AccountKind::Cash, AccountKind::Bank, AccountKind::Wallet] as $kind) {
            $accounts = $this->resolver->settlersAccounts($actorId, $kind)->values()->all();
            $own = count($accounts) === 1 ? (int) $accounts[0]->getKey() : null;

            // What already sits in the settler's one account of the kind goes nowhere.
            $sources = array_values(array_filter(
                $sourcesByKind[$kind->value] ?? [],
                fn (array $row) => $row['id'] !== $own,
            ));

            if ($sources === []) {
                continue;
            }

            $plan[] = [
                'kind' => $kind->value,
                'kind_label' => $kind->label(),
                'amount' => Money::sum('0', ...array_column($sources, 'amount')),
                'sources' => array_map(fn (array $row) => ['name' => $row['name'], 'amount' => $row['amount']], $sources),
                'accounts' => array_map(self::pickerRow(...), $accounts),
                // A kind with no account of theirs is collected, if that is on — or stays.
                'fallback' => $accounts === [] ? $this->collectOrderMoney->targetFor($kind)?->name : null,
            ];
        }

        return $plan;
    }

    /**
     * One row of a picker on the status screen.
     *
     * @return array{value: string, label: string, kind: string, methods: list<string>, is_default: bool}
     */
    public static function pickerRow(TreasuryAccount $account): array
    {
        return [
            'value' => (string) $account->getKey(),
            'label' => (string) $account->name,
            'kind' => $account->kind->value,
            'methods' => array_values(array_filter(
                ['cash', 'bank_transfer', 'bank_card', 'libyana'],
                fn (string $method) => in_array($account->kind, AccountKind::forMethod($method), true),
            )),
            'is_default' => (bool) $account->is_default,
        ];
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
    public function unwindSettlementOf(
        int $orderId,
        string $reason,
        ?int $actorId,
        ?int $accountId = null,
        ?int $paymentId = null,
    ): void {
        foreach ($this->standingSettlements($orderId, $accountId, $paymentId)->get() as $settlement) {
            ($this->reverseOperation)($settlement, $reason, $actorId, byHand: false);
        }
    }

    /**
     * هل نقلت التسويةُ مالاً لهذه الطلبية — من هذا الحساب إن سُمّي — ولم يُعكس بعد؟
     *
     * يسأله من يعكس دفعةً والطلبيةُ «تم التسوية»: فكُّ التسوية يفكّها كلَّها، والطلبيةُ لا تُسوّى
     * ثانيةً وهي في آخر الطريق — فيبقى المالُ في العهدة إلى الأبد. فالجواب «نعم» يعني: تراجع
     * عن التسوية أولاً.
     */
    public function hasStandingSettlementOf(int $orderId, ?int $accountId = null, ?int $paymentId = null): bool
    {
        return $this->standingSettlements($orderId, $accountId, $paymentId)->exists();
    }

    /**
     * The order's own settlements — and, when a payment is named, that payment's settlement too
     * (§٢٣). **Another payment's settlement is never in it:** reversing Nawris's first payment
     * leaves the second where it was settled, and un-settling the order leaves both.
     *
     * @return Builder<TreasuryOperation>
     */
    private function standingSettlements(int $orderId, ?int $accountId, ?int $paymentId = null): Builder
    {
        return TreasuryOperation::query()
            ->where('type', OperationType::Settlement->value)
            ->where('order_id', $orderId)
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy')
            ->where(fn ($q) => $q
                ->where(fn ($orders) => $orders
                    ->whereNull('order_payment_id')
                    ->when($accountId !== null, fn ($m) => $m->whereHas('movements', fn ($m) => $m
                        ->where('account_id', $accountId)
                        ->where('direction', MovementDirection::Out->value))))
                ->when($paymentId !== null, fn ($q) => $q->orWhere('order_payment_id', $paymentId)));
    }

    // ── «تسوية دفعة» (§٢٣) ──────────────────────────────────────────────────────────────

    /**
     * Carries one payment's money to the account it reached, before its order is settled. Call
     * inside the caller's transaction, with the order locked. See {@see SettlePayment}.
     */
    public function settlePayment(
        int $orderId,
        int $paymentId,
        int $sourceAccountId,
        string $amount,
        ?int $destinationId,
        ?string $fee,
        ?int $actorId,
        ?string $orderCode = null,
        string $paymentField = 'payment_id',
        string $accountField = 'account_id',
        string $feeField = 'fee',
    ): TreasuryOperation {
        return ($this->settlePayment)(
            $orderId,
            $paymentId,
            $sourceAccountId,
            $amount,
            $destinationId,
            $fee,
            $actorId,
            $orderCode,
            $paymentField,
            $accountField,
            $feeField,
        );
    }

    /**
     * Takes a payment's settlement back: its money returns to the account it landed in. Never
     * refused for balance — money already spent from the destination leaves it red, as every
     * reversal does. Call inside the caller's transaction, with the order locked.
     */
    public function unsettlePayment(int $paymentId, string $reason, ?int $actorId): TreasuryOperation
    {
        $settlement = $this->settlePayment->standingFor($paymentId)
            ?? throw new OperationRefused('هذه الدفعة غير مسوّاة');

        return ($this->reverseOperation)($settlement, $reason, $actorId, byHand: false);
    }

    /**
     * Locks these accounts in id order — before several payments are settled at once, so two
     * batches over the same accounts wait for each other instead of deadlocking.
     *
     * @param  list<int>  $accountIds
     */
    public function lockAccounts(array $accountIds): void
    {
        if ($accountIds === []) {
            return;
        }

        TreasuryAccount::query()->whereIn('id', array_values(array_unique($accountIds)))->orderBy('id')->lockForUpdate()->get();
    }

    /**
     * Where a payment in this account goes when settled and nobody picks — null when it is
     * already in its place. Asked once per account in a request: a list of fifty payments sits
     * in three or four accounts.
     *
     * @return ?array{id: int, name: string}
     */
    public function paymentSettlementTarget(int $accountId, ?int $actorId): ?array
    {
        return RequestMemo::remember(
            "treasury.payment-target:{$accountId}:".($actorId ?? 'none'),
            function () use ($accountId, $actorId): ?array {
                $source = TreasuryAccount::query()->find($accountId);
                $target = $source === null ? null : $this->settlePayment->defaultDestination($source, $actorId);

                return $target === null ? null : ['id' => (int) $target->getKey(), 'name' => (string) $target->name];
            },
        );
    }

    /**
     * The settlement page's accounts: where payments wait (its filter chips — Nawris included,
     * which no payment form offers), and where they may be settled to — every active cash box,
     * bank and wallet, whoever is asking. Names, not balances.
     *
     * @return array{sources: list<array{id: int, name: string, kind: string}>, destinations: list<array{id: int, name: string, kind: string, kind_label: string}>}
     */
    public function settlementAccounts(?int $actorId): array
    {
        $waiting = $this->accountsAwaitingSettlement($actorId);

        return [
            'sources' => TreasuryAccount::query()
                ->whereIn('id', $waiting)
                ->orderByRaw("CASE WHEN kind = 'custody' THEN 0 ELSE 1 END")
                ->orderBy('name')
                ->get()
                ->map(fn (TreasuryAccount $a) => ['id' => (int) $a->id, 'name' => (string) $a->name, 'kind' => $a->kind->value])
                ->values()
                ->all(),
            'destinations' => TreasuryAccount::query()
                ->active()
                ->whereIn('kind', [AccountKind::Cash->value, AccountKind::Bank->value, AccountKind::Wallet->value])
                ->orderByDesc('is_default')
                ->orderBy('name')
                ->get()
                ->map(fn (TreasuryAccount $a) => [
                    'id' => (int) $a->id,
                    'name' => (string) $a->name,
                    'kind' => $a->kind->value,
                    'kind_label' => $a->kind->label(),
                ])
                ->values()
                ->all(),
        ];
    }

    /**
     * Every account whose money would move at settlement — custody always, and an employee's or a
     * branch's account where the settler's account or collection would take it. Payments in these
     * accounts are «بانتظار التسوية»; a payment anywhere else is already in its place.
     *
     * @return list<int>
     */
    public function accountsAwaitingSettlement(?int $actorId): array
    {
        return RequestMemo::remember(
            'treasury.awaiting-settlement:'.($actorId ?? 'none'),
            fn (): array => TreasuryAccount::query()
                ->whereIn('kind', [AccountKind::Custody->value, AccountKind::Cash->value, AccountKind::Bank->value, AccountKind::Wallet->value])
                ->orderBy('id')
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->filter(fn (int $id) => $this->paymentSettlementTarget($id, $actorId) !== null)
                ->values()
                ->all(),
        );
    }

    /**
     * Every account a person may pick for money, with the methods each one takes — the list a
     * form filters as the method changes. Nawris is left out: only its webhook writes to it. So
     * is every payable: no payment lands in a debt. **ولا عهدةَ إلا عهدةُ من يختار** — القاعدةُ
     * التي يرفض بها الخادمُ اختيارَ غيرها.
     *
     * **مرّةً واحدة لكل طلب**: قائمةُ الطلبيات تبني حقولَ كل حركةٍ لكل طلبية، وكانت تسأل
     * القاعدةَ السؤالَ نفسَه مرّتين لكل صف. انظر {@see RequestMemo}.
     *
     * @return list<array{value: string, label: string, kind: string, methods: list<string>, is_default: bool}>
     */
    public function pickableAccounts(?int $actorId = null): array
    {
        return RequestMemo::remember(
            'treasury.pickable:'.($actorId ?? 'none'),
            fn (): array => $this->queryPickableAccounts($actorId),
        );
    }

    /**
     * @return list<array{value: string, label: string, kind: string, methods: list<string>, is_default: bool}>
     */
    private function queryPickableAccounts(?int $actorId): array
    {
        return TreasuryAccount::query()
            ->active()
            ->whereNull('system_code')
            ->where('kind', '<>', AccountKind::Payable->value)
            ->where(fn ($q) => $q->where('kind', '<>', AccountKind::Custody->value)
                ->when($actorId !== null, fn ($q) => $q->orWhere('holder_user_id', $actorId)))
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get()
            ->map(fn (TreasuryAccount $account) => self::pickerRow($account))
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

    // ── تاريخُ المال اليدوي ─────────────────────────────────────────────────────────────

    /**
     * يرفض مالاً يدوياً بتاريخٍ لا يجوز له — من شاشات الشراء والمصروف والمحفظة، كما ترفضه العمليات
     * اليدوية نفسُها: داخل «مقفل حتى تاريخ»، أو قبل آخر نقطة عدٍّ للحساب ({@see CheckpointFloor}).
     *
     * @param  bool  $wholeDay  التاريخ يومٌ بلا ساعة (`occurred_on`, `incurred_on`) — يُقاس باليوم
     */
    public function guardManualEntry(
        TreasuryAccount $account,
        DateTimeInterface $at,
        string $field,
        bool $wholeDay = false,
    ): void {
        $this->guardNotLocked($at, $field);
        $this->guardAfterCheckpoint($account, $at, $field, $wholeDay);
    }

    /** الأرضيةُ وحدها، لمن يفحص القفلَ قبل أن يعرف الحساب — دفعة المورد. */
    public function guardAfterCheckpoint(
        TreasuryAccount $account,
        DateTimeInterface $at,
        string $field,
        bool $wholeDay = false,
    ): void {
        (new CheckpointFloor)->guard($account, $at, $field, $wholeDay);
    }
}
