<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
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
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Support\BalanceVisibility;
use App\Domain\Treasury\Support\CheckpointFloor;
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
        private readonly BalanceVisibility $visibility,
        private readonly CheckpointFloor $floor,
    ) {}

    public function __invoke(OperationData $data, ?int $actorId): TreasuryOperation
    {
        if ($data->type === OperationType::Settlement) {
            throw new InvalidArgumentException('A settlement is written by «تم التسوية», not by hand.');
        }

        // الضغطةُ الثانية تُجاب قبل أيّ حارس: هي العمليةُ الأولى نفسها، ولو أُقفل الشهرُ بينهما.
        if (($sent = $this->alreadySent($data->clientToken)) !== null) {
            return $sent;
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

            // تحت قفل الحسابات: ضغطتان متزامنتان على الحساب نفسه تمرّان هنا واحدةً بعد واحدة،
            // فتجد الثانيةُ ما كتبته الأولى. والفهرسُ الفريد حارسٌ أخير لا طريقٌ عادي.
            if (($sent = $this->alreadySent($data->clientToken)) !== null) {
                return $sent;
            }

            $from = $data->fromAccountId === null ? null : $accounts->get($data->fromAccountId);
            $to = $data->toAccountId === null ? null : $accounts->get($data->toAccountId);

            // A payable's opening is a debt: it arrives as the account opened, and leaves it.
            if ($data->type === OperationType::Opening && $to?->kind === AccountKind::Payable) {
                [$from, $to] = [$to, null];
            }

            $this->guardAccounts($data->type, $from, $to);
            $this->guardCheckpoints($data, $from, $to);

            $category = $this->category($data);

            [$amount, $from, $to, $systemBalance, $counted] = $data->type === OperationType::Adjustment
                ? $this->adjustment($data, $to ?? $from)
                : [(string) $data->amount, $from, $to, null, null];

            // «منع الرصيد السالب في العمليات اليدوية» — on unless the owner switched it off. A
            // payable has no money to run out of: borrowing and buying on credit deepen its debt.
            if ($from !== null && $from->kind->holdsMoney() && $data->type !== OperationType::Adjustment && $settings->block_overdraft) {
                $this->guardBalance($from, $amount, $actorId);
            }

            // Repaying more than is owed would leave the creditor holding the company's money.
            if ($to !== null && $to->kind === AccountKind::Payable && $data->type === OperationType::Transfer) {
                $this->guardDebt($to, $amount);
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
                'counted_balance' => $counted,
                'occurred_at' => $data->occurredAt,
                'notes' => $data->notes,
                'recorded_by' => $actorId,
                'client_token' => $data->clientToken,
            ])->save();

            $this->writeMovements($operation, $from, $to, $actorId);

            return $operation;
        });
    }

    private function alreadySent(?string $clientToken): ?TreasuryOperation
    {
        return $clientToken === null
            ? null
            : TreasuryOperation::query()->where('client_token', $clientToken)->first();
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
     * What each kind takes by hand.
     *
     * - A switched-off account takes nothing.
     * - Custody takes its opening and a count: it fills from customers and empties by settlement,
     *   and anything else would leave the per-order sums claiming money that is not there.
     * - A vendor's payable takes nothing: its purchase orders and payments are the reasons.
     * - Any other payable takes its opening, an expense bought on credit, a transfer (borrowing
     *   from it or repaying into it) and a count — not a deposit or a withdrawal, which say
     *   money arrived or left when none did.
     */
    private function guardAccounts(OperationType $type, ?TreasuryAccount $from, ?TreasuryAccount $to): void
    {
        foreach (array_filter([$from, $to]) as $account) {
            $field = $account === $from && $type !== OperationType::Opening ? 'from_account_id' : 'to_account_id';

            if (! $account->is_active) {
                throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
            }

            if ($account->isVendorPayable()) {
                throw AccountDoesNotFitMethod::vendorPayable((string) $account->name, $field);
            }

            if ($account->isCustomerExcessPayable()) {
                throw AccountDoesNotFitMethod::customerExcessPayable((string) $account->name, $field);
            }

            if ($account->kind === AccountKind::Payable) {
                if ($type === OperationType::Deposit || $type === OperationType::Withdrawal) {
                    throw OperationRefused::notOnPayable($type->label(), (string) $account->name, $field);
                }

                continue;
            }

            $custodyAllowed = $type === OperationType::Opening || $type === OperationType::Adjustment;

            if (! $custodyAllowed && ! $account->kind->spendable()) {
                throw AccountDoesNotFitMethod::custody((string) $account->name, $field);
            }
        }
    }

    /**
     * One opening per account, and nothing by hand dated before the account's latest count —
     * its opening, or its latest «جرد الحساب» ({@see CheckpointFloor}). A payable's opening left
     * it, so either side counts.
     *
     * **والافتتاحُ لحسابٍ لم يتحرّك بعد وحده.** حسابٌ استقبل مالاً — دفعاتٌ استُوردت، إيداعٌ
     * سبق — رصيدُه قائمٌ بحركاته، وافتتاحٌ فوقها يعدّ ذلك المال مرّتين.
     */
    private function guardCheckpoints(
        OperationData $data,
        ?TreasuryAccount $from,
        ?TreasuryAccount $to,
    ): void {
        foreach (array_filter([$from, $to]) as $account) {
            if ($data->type !== OperationType::Opening) {
                $this->floor->guard($account, $data->occurredAt, 'occurred_at');

                continue;
            }

            $opened = TreasuryOperation::query()
                ->where('type', OperationType::Opening->value)
                ->where(fn ($q) => $q->where('to_account_id', $account->getKey())
                    ->orWhere('from_account_id', $account->getKey()))
                ->exists();

            if ($opened) {
                throw OperationRefused::openingExists((string) $account->name);
            }

            if ($account->movements()->exists()) {
                throw OperationRefused::accountHasMovements((string) $account->name);
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
     * **ورصيدُ النظام رصيدُ لحظة الجرد لا رصيدُ اليوم.** جردٌ بتاريخٍ مضى يُقاس بحركاتٍ مؤرَّخةٍ
     * فيه أو قبله وحدها، وذلك الرقمُ هو `system_balance` المحفوظ.
     *
     * **A payable is counted as what is owed**, a figure people say as a positive number; the
     * balance it means is that number below zero, and that is what is kept.
     *
     * @return array{0: string, 1: ?TreasuryAccount, 2: ?TreasuryAccount, 3: string, 4: string}
     */
    private function adjustment(OperationData $data, TreasuryAccount $account): array
    {
        $system = $this->balances->asOf((int) $account->getKey(), $data->occurredAt);
        $counted = Money::round((string) $data->countedBalance);

        if (! $account->kind->holdsMoney()) {
            $counted = Money::round(bcmul($counted, '-1', Money::SCALE));
        }

        $difference = Money::round(bcsub($counted, $system, 8));

        if (bccomp($difference, '0', Money::SCALE) === 0) {
            throw OperationRefused::balanceUnchanged((string) $account->name);
        }

        return bccomp($difference, '0', Money::SCALE) > 0
            ? [$difference, null, $account, $system, $counted]
            : [bcmul($difference, '-1', Money::SCALE), $account, null, $system, $counted];
    }

    private function guardDebt(TreasuryAccount $payable, string $amount): void
    {
        $owed = Money::round(bcmul($this->balances->of((int) $payable->getKey()), '-1', Money::SCALE));

        if (bccomp($amount, $owed, Money::SCALE) > 0) {
            throw OperationRefused::exceedsDebt((string) $payable->name, $owed);
        }
    }

    private function guardBalance(TreasuryAccount $from, string $amount, ?int $actorId): void
    {
        $balance = $this->balances->of((int) $from->getKey());

        if (bccomp($amount, $balance, Money::SCALE) > 0) {
            // الرقمُ لمن يراه وحده — {@see BalanceVisibility}.
            throw InsufficientBalance::make(
                (string) $from->name,
                $this->visibility->allows($from, $actorId) ? $balance : null,
                $amount,
            );
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
