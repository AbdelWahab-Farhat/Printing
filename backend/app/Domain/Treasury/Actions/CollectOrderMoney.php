<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Queries\OrderMoneyByAccount;
use App\Domain\Treasury\Support\AccountResolver;
use App\Domain\Treasury\Support\Money;
use DateTimeInterface;

/**
 * «التجميع عند التسوية» — at «تم التسوية», the order's money in «مصرف علي», «مصرف عمر» or a
 * branch's cash box moves to the one account the owner collects that kind in. TREASURY-DESIGN §١٨.
 *
 * **Only this order's money, and only what is still there.** Each account gives up its net for
 * the order — payments in, less refunds and reversals out — but never more than it holds: if Ali
 * already carried the 300 to the bank by hand, there is nothing left to carry, and nothing is
 * counted twice or driven below zero.
 *
 * **A `settlement` operation, one per account emptied**, so every path that already undoes an
 * order's settlement — a payment reversed, the order deleted, the order un-settled — undoes this
 * with it, and the money is back where it landed before the reversal takes it out.
 *
 * Never refused: the settlement is a fact, and a switched-off or removed target falls back to the
 * kind's default.
 */
final class CollectOrderMoney
{
    private const KINDS = [AccountKind::Cash, AccountKind::Bank, AccountKind::Wallet];

    public function __construct(
        private readonly OrderMoneyByAccount $money,
        private readonly AccountBalances $balances,
        private readonly AccountResolver $resolver,
        private readonly PostMovement $post,
    ) {}

    /**
     * @param  ?int  $keepAccountId  the account picked by hand on the settle screen — a person
     *                               said the money belongs there, and that choice wins
     * @return list<TreasuryOperation> one per account that had something to carry
     */
    public function __invoke(
        int $orderId,
        ?int $actorId,
        DateTimeInterface $occurredAt,
        ?string $orderCode = null,
        ?int $keepAccountId = null,
    ): array {
        $plans = [];

        foreach (self::KINDS as $kind) {
            $target = $this->targetFor($kind);

            if ($target !== null) {
                $plans[] = [$kind, $target, array_values(array_filter([(int) $target->getKey(), $keepAccountId]))];
            }
        }

        // **كلُّ حسابات المصدر تُقفل دفعةً واحدة، بترتيب المعرّف، قبل أي نوع.** القفلُ نوعاً
        // نوعاً (نقد ثم مصرف) يعاكس ترتيبَ المعرّف الذي يقفل به التحويلُ اليدوي حسابَيه، فتنتظر
        // كلُّ معاملةٍ الأخرى ويُسقط PostgreSQL إحداهما بخطأ. وكلُّ نوعٍ يعيد القراءة بعد هذا.
        $sources = [];

        foreach ($plans as [$kind, , $except]) {
            array_push($sources, ...array_keys($this->money->of($orderId, $kind, $except)));
        }

        if ($sources !== []) {
            $sources = array_values(array_unique($sources));
            sort($sources);

            TreasuryAccount::query()->whereIn('id', $sources)->orderBy('id')->lockForUpdate()->get();
        }

        $operations = [];

        foreach ($plans as [$kind, $target, $except]) {
            array_push($operations, ...$this->collect($orderId, $kind, $target, $except, $actorId, $occurredAt, $orderCode));
        }

        return $operations;
    }

    /**
     * Where this kind is collected, or null when its switch is off. The account named in the
     * settings if it is still an active account of the kind; the kind's default otherwise.
     */
    public function targetFor(AccountKind $kind): ?TreasuryAccount
    {
        $setting = TreasurySetting::current()->collectionFor($kind);

        if (! $setting['on']) {
            return null;
        }

        $named = $setting['into'] === null ? null : TreasuryAccount::query()->find($setting['into']);

        if ($named !== null && $named->is_active && $named->kind === $kind) {
            return $named;
        }

        return $this->resolver->defaultOf($kind);
    }

    /**
     * Where money arriving in `$account` at settlement should go instead — the collecting account
     * of its kind, unless that is off or the account keeps its own money. The account itself
     * otherwise.
     */
    public function redirect(TreasuryAccount $account): TreasuryAccount
    {
        if (! $account->is_collected) {
            return $account;
        }

        return $this->targetFor($account->kind) ?? $account;
    }

    /**
     * @param  list<int>  $except
     * @return list<TreasuryOperation>
     */
    private function collect(
        int $orderId,
        AccountKind $kind,
        TreasuryAccount $target,
        array $except,
        ?int $actorId,
        DateTimeInterface $occurredAt,
        ?string $orderCode,
    ): array {
        $held = $this->money->of($orderId, $kind, $except);

        if ($held === []) {
            return [];
        }

        // Lock, then read again — two settlements racing would otherwise both carry the money.
        TreasuryAccount::query()->whereIn('id', array_keys($held))->orderBy('id')->lockForUpdate()->get();
        $held = $this->money->of($orderId, $kind, $except);
        $balances = $this->balances->forAccounts(array_keys($held));

        $operations = [];

        foreach ($held as $accountId => $amount) {
            $there = $balances[$accountId];
            $amount = bccomp($amount, $there, Money::SCALE) > 0 ? $there : $amount;

            if (Money::isPositive($amount)) {
                $operations[] = $this->carry($orderId, $accountId, $target, $amount, $actorId, $occurredAt, $orderCode);
            }
        }

        return $operations;
    }

    /**
     * One account's share, under an operation of its own — so reversing Ali's payment unwinds
     * Ali's collection and leaves Omar's where it went.
     */
    private function carry(
        int $orderId,
        int $fromId,
        TreasuryAccount $target,
        string $amount,
        ?int $actorId,
        DateTimeInterface $occurredAt,
        ?string $orderCode,
    ): TreasuryOperation {
        $operation = new TreasuryOperation;

        $operation->forceFill([
            'type' => OperationType::Settlement,
            'amount' => $amount,
            'from_account_id' => $fromId,
            'to_account_id' => $target->getKey(),
            'order_id' => $orderId,
            'occurred_at' => $occurredAt,
            'notes' => $orderCode === null ? 'تجميع عند التسوية' : "تجميع الطلبية {$orderCode}",
            'recorded_by' => $actorId,
        ])->save();

        $move = fn (int $accountId, MovementDirection $direction, int $other) => ($this->post)(new MovementData(
            accountId: $accountId,
            direction: $direction,
            kind: MovementKind::Settlement,
            amount: $amount,
            occurredAt: $occurredAt,
            sourceType: AuditSubject::TreasuryOperation->value,
            sourceId: (int) $operation->getKey(),
            orderId: $orderId,
            notes: $operation->notes,
            recordedBy: $actorId,
            operationId: (int) $operation->getKey(),
            counterpartAccountId: $other,
        ));

        $move($fromId, MovementDirection::Out, (int) $target->getKey());
        $move((int) $target->getKey(), MovementDirection::In, $fromId);

        return $operation;
    }
}
