<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Exceptions\InsufficientBalance;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * What a person does to the treasury by hand: an opening count, a deposit, a withdrawal, an
 * expense, a transfer, or «جرد الحساب».
 *
 * **The accounts are locked first, in id order.** The balance guard reads a sum and then writes
 * against it; two withdrawals racing for the last dinar would both pass without the lock, and two
 * transfers crossing between the same pair would deadlock without the order.
 *
 * **Only hand operations are refused for balance** — TREASURY-DESIGN §١٢. A payment, a refund or
 * a reversal is a fact posted through {@see PostMovement}, which refuses nothing.
 */
final class RecordOperation
{
    public function __construct(
        private readonly PostMovement $post,
        private readonly AccountBalances $balances,
    ) {}

    public function __invoke(OperationData $data, ?int $actorId): TreasuryOperation
    {
        if ($data->type === OperationType::Settlement) {
            throw new InvalidArgumentException('A settlement is written by «تم التسوية», not by hand.');
        }

        $settings = TreasurySetting::current();

        if ($settings->locks($data->occurredAt)) {
            throw OperationRefused::locked($settings->locked_until->toDateString());
        }

        if ($data->type === OperationType::Withdrawal && $settings->withdrawal_needs_reason && $data->notes === null) {
            throw OperationRefused::reasonRequired();
        }

        // بعد الصبّ إلى عدد لا قبله: `different:` في الطلب يقارن 5 بـ"5" فيراهما مختلفين، ثم
        // يُقفل الحسابُ نفسُه مرّتين ويصطدم الصفُّ بقيد الشكل.
        $toItself = $data->fromAccountId === $data->toAccountId;

        if ($data->type === OperationType::Transfer && $toItself) {
            throw OperationRefused::sameAccount();
        }

        return DB::transaction(function () use ($data, $actorId, $settings): TreasuryOperation {
            $accounts = $this->lock($data);

            $from = $data->fromAccountId === null ? null : $accounts->get($data->fromAccountId);
            $to = $data->toAccountId === null ? null : $accounts->get($data->toAccountId);

            $this->guardAccounts($data->type, $from, $to);
            $this->guardOpening($data, $from, $to);

            $category = $this->category($data);

            [$amount, $from, $to, $systemBalance] = $data->type === OperationType::Adjustment
                ? $this->adjustment($data, $to ?? $from)
                : [(string) $data->amount, $from, $to, null];

            // «منع الرصيد السالب في العمليات اليدوية» — on unless the owner switched it off.
            if ($from !== null && $data->type !== OperationType::Adjustment && $settings->block_overdraft) {
                $this->guardBalance($from, $amount);
            }

            $operation = new TreasuryOperation;

            $operation->forceFill([
                'type' => $data->type,
                'amount' => $amount,
                'from_account_id' => $from?->getKey(),
                'to_account_id' => $to?->getKey(),
                'category_id' => $category?->getKey(),
                'employee_id' => $data->employeeId,
                'system_balance' => $systemBalance,
                'counted_balance' => $data->type === OperationType::Adjustment ? $data->countedBalance : null,
                'occurred_at' => $data->occurredAt,
                'notes' => $data->notes,
                'recorded_by' => $actorId,
            ])->save();

            $this->writeMovements($operation, $from, $to, $actorId);

            return $operation;
        });
    }

    /**
     * @return Collection<int, TreasuryAccount>
     */
    private function lock(OperationData $data): Collection
    {
        $ids = array_values(array_unique(array_filter([$data->fromAccountId, $data->toAccountId])));
        sort($ids);

        return TreasuryAccount::query()
            ->whereIn('id', $ids)
            ->orderBy('id')
            ->lockForUpdate()
            ->get()
            ->keyBy(fn (TreasuryAccount $account) => (int) $account->getKey());
    }

    /**
     * Switched-off accounts take nothing by hand, and custody takes nothing but its opening and
     * a count: it fills from customers and empties by settlement, and anything else would leave
     * the per-order sums claiming money that is not there.
     */
    private function guardAccounts(OperationType $type, ?TreasuryAccount $from, ?TreasuryAccount $to): void
    {
        foreach (array_filter([$from, $to]) as $account) {
            if (! $account->is_active) {
                throw AccountDoesNotFitMethod::inactive(
                    (string) $account->name,
                    $account === $from ? 'from_account_id' : 'to_account_id',
                );
            }

            $custodyAllowed = $type === OperationType::Opening || $type === OperationType::Adjustment;

            if (! $custodyAllowed && ! $account->kind->spendable()) {
                throw AccountDoesNotFitMethod::custody(
                    (string) $account->name,
                    $account === $from ? 'from_account_id' : 'to_account_id',
                );
            }
        }
    }

    /**
     * One opening per account, and nothing by hand dated before it — the opening count is the
     * floor the balance was measured from.
     */
    private function guardOpening(OperationData $data, ?TreasuryAccount $from, ?TreasuryAccount $to): void
    {
        foreach (array_filter([$from, $to]) as $account) {
            $opening = TreasuryOperation::query()
                ->where('type', OperationType::Opening->value)
                ->where('to_account_id', $account->getKey())
                ->first();

            if ($opening === null) {
                continue;
            }

            if ($data->type === OperationType::Opening) {
                throw OperationRefused::openingExists((string) $account->name);
            }

            if ($data->occurredAt->lt($opening->occurred_at)) {
                throw OperationRefused::beforeOpening(
                    (string) $account->name,
                    $opening->occurred_at->toDateString(),
                );
            }
        }
    }

    private function category(OperationData $data): ?ExpenseCategory
    {
        if ($data->type !== OperationType::Expense) {
            return null;
        }

        $category = ExpenseCategory::query()->findOrFail($data->categoryId);

        if (! $category->is_active) {
            throw OperationRefused::categoryInactive((string) $category->name);
        }

        if ($category->requires_employee && $data->employeeId === null) {
            throw OperationRefused::categoryNeedsEmployee((string) $category->name);
        }

        return $category;
    }

    /**
     * «جرد الحساب»: the balance found against the balance recorded, and the difference written.
     *
     * The account arrives as `to_account_id` and leaves on whichever side the difference falls:
     * a surplus goes in, a shortfall comes out. Both figures are kept on the operation.
     *
     * @return array{0: string, 1: ?TreasuryAccount, 2: ?TreasuryAccount, 3: string}
     */
    private function adjustment(OperationData $data, TreasuryAccount $account): array
    {
        $system = $this->balances->of((int) $account->getKey());
        $difference = Money::round(bcsub((string) $data->countedBalance, $system, 8));

        if (bccomp($difference, '0', Money::SCALE) === 0) {
            throw OperationRefused::balanceUnchanged((string) $account->name);
        }

        return bccomp($difference, '0', Money::SCALE) > 0
            ? [$difference, null, $account, $system]
            : [bcmul($difference, '-1', Money::SCALE), $account, null, $system];
    }

    private function guardBalance(TreasuryAccount $from, string $amount): void
    {
        $balance = $this->balances->of((int) $from->getKey());

        if (bccomp($amount, $balance, Money::SCALE) > 0) {
            throw InsufficientBalance::make((string) $from->name, $balance, $amount);
        }
    }

    private function writeMovements(
        TreasuryOperation $operation,
        ?TreasuryAccount $from,
        ?TreasuryAccount $to,
        ?int $actorId,
    ): void {
        $kind = $operation->type->movementKind();

        $movement = fn (TreasuryAccount $account, MovementDirection $direction, ?TreasuryAccount $other) => new MovementData(
            accountId: (int) $account->getKey(),
            direction: $direction,
            kind: $kind,
            amount: (string) $operation->amount,
            occurredAt: $operation->occurred_at,
            sourceType: AuditSubject::TreasuryOperation->value,
            sourceId: (int) $operation->getKey(),
            notes: $operation->notes,
            recordedBy: $actorId,
            operationId: (int) $operation->getKey(),
            counterpartAccountId: $other === null ? null : (int) $other->getKey(),
        );

        if ($from !== null) {
            ($this->post)($movement($from, MovementDirection::Out, $to));
        }

        if ($to !== null) {
            ($this->post)($movement($to, MovementDirection::In, $from));
        }
    }
}
