<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Queries\AccountBalances;
use App\Domain\Treasury\Queries\OrderMoneyByAccount;
use App\Domain\Treasury\Support\Money;

/**
 * «تسوية دفعة» — one payment's money carried from the account it landed in to the account it
 * really reached, **before the order gets to «تم التسوية»**. TREASURY-DESIGN §٢٣.
 *
 * **A `settlement` operation that names its payment** (`order_payment_id`), so it reads in every
 * ledger like the order's own settlement, and the order's settlement later finds that much less
 * to carry: both work from what the order still holds in each account, and this took it out.
 *
 * **The whole payment, or nothing.** Its money must still be where it landed — a settlement or a
 * hand that already moved it leaves nothing to move twice — and the account must hold it.
 *
 * **What the carrier kept** comes out of custody as «رسوم شركة التوصيل», as on the order's
 * settlement screen; only custody can have kept anything.
 *
 * Callers lock the order first; this locks the account.
 */
final class SettlePayment
{
    public function __construct(
        private readonly OrderMoneyByAccount $money,
        private readonly AccountBalances $balances,
        private readonly SettleCustody $custody,
        private readonly CollectOrderMoney $collect,
        private readonly PostMovement $post,
    ) {}

    public function __invoke(
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
        $source = TreasuryAccount::query()->whereKey($sourceAccountId)->lockForUpdate()->firstOrFail();
        $amount = Money::round($amount);

        if ($this->standingFor($paymentId) !== null) {
            throw new OperationRefused('هذه الدفعة سُوّيت من قبل', $paymentField);
        }

        if (bccomp($this->money->inAccount($orderId, $sourceAccountId), $amount, Money::SCALE) < 0) {
            throw new OperationRefused("مال هذه الدفعة لم يعد في «{$source->name}» — نُقل من قبل", $paymentField);
        }

        $balance = $this->balances->forAccounts([$sourceAccountId])[$sourceAccountId] ?? '0.00';

        if (bccomp($balance, $amount, Money::SCALE) < 0) {
            throw new OperationRefused("في «{$source->name}» {$balance} فقط — أقل من الدفعة ({$amount})", $paymentField);
        }

        $fee = $this->fee($fee, $amount, $source, $feeField);
        $destination = $this->destination($destinationId, $source, $actorId, $accountField);
        $received = Money::round(bcsub($amount, $fee, 8));

        $operation = new TreasuryOperation;

        $operation->forceFill([
            'type' => OperationType::Settlement,
            'amount' => $amount,
            'from_account_id' => $source->getKey(),
            'to_account_id' => $destination->getKey(),
            'category_id' => Money::isPositive($fee)
                ? ExpenseCategory::query()->where('code', ExpenseCategory::CARRIER_FEE)->value('id')
                : null,
            'order_id' => $orderId,
            'order_payment_id' => $paymentId,
            'occurred_at' => now(),
            'notes' => $orderCode === null ? 'تسوية دفعة' : "تسوية دفعة الطلبية {$orderCode}",
            'recorded_by' => $actorId,
        ])->save();

        $move = fn (int $accountId, MovementDirection $direction, MovementKind $kind, string $value, ?int $other) => ($this->post)(new MovementData(
            accountId: $accountId,
            direction: $direction,
            kind: $kind,
            amount: $value,
            occurredAt: $operation->occurred_at,
            sourceType: AuditSubject::TreasuryOperation->value,
            sourceId: (int) $operation->getKey(),
            orderId: $orderId,
            notes: $operation->notes,
            recordedBy: $actorId,
            operationId: (int) $operation->getKey(),
            counterpartAccountId: $other,
        ));

        if (Money::isPositive($received)) {
            $move((int) $source->getKey(), MovementDirection::Out, MovementKind::Settlement, $received, (int) $destination->getKey());
            $move((int) $destination->getKey(), MovementDirection::In, MovementKind::Settlement, $received, (int) $source->getKey());
        }

        if (Money::isPositive($fee)) {
            $move((int) $source->getKey(), MovementDirection::Out, MovementKind::Expense, $fee, null);
        }

        return $operation;
    }

    /**
     * Where this account's money goes when nobody picks: custody lands where the order's
     * settlement would put it (§٦), and then — like any account — on to the settler's own account
     * of its kind (§٢٢) or the kind's collecting account (§١٨).
     *
     * Null when it would stay where it is: the payment is already in its place.
     */
    public function defaultDestination(TreasuryAccount $source, ?int $actorId): ?TreasuryAccount
    {
        $landing = $source->kind === AccountKind::Custody
            ? $this->custody->landingForCustody($source, $actorId)
            : $source;

        $target = $this->collect->redirect($landing, $actorId);

        return $target->is($source) ? null : $target;
    }

    /** The payment's settlement still standing — not a reversal, and not reversed since. */
    public function standingFor(int $paymentId): ?TreasuryOperation
    {
        return TreasuryOperation::query()
            ->where('type', OperationType::Settlement->value)
            ->where('order_payment_id', $paymentId)
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy')
            ->first();
    }

    private function fee(?string $fee, string $amount, TreasuryAccount $source, string $field): string
    {
        $fee = $fee === null ? '0.00' : Money::round($fee);

        if (bccomp($fee, '0', Money::SCALE) < 0) {
            throw new OperationRefused('ما احتفظ به الناقل لا يكون سالباً', $field);
        }

        if (! Money::isPositive($fee)) {
            return '0.00';
        }

        if ($source->kind !== AccountKind::Custody) {
            throw new OperationRefused("«{$source->name}» ليس ناقلاً — لا شيء احتفظ به", $field);
        }

        if (bccomp($fee, $amount, Money::SCALE) > 0) {
            throw new OperationRefused("ما احتفظ به الناقل ({$fee}) أكبر من الدفعة ({$amount})", $field);
        }

        return $fee;
    }

    private function destination(?int $chosenId, TreasuryAccount $source, ?int $actorId, string $field): TreasuryAccount
    {
        if ($chosenId === null) {
            return $this->defaultDestination($source, $actorId)
                ?? throw new OperationRefused("لا وجهة تلقائية لمال «{$source->name}» — اختر الحساب", $field);
        }

        $account = TreasuryAccount::query()->find($chosenId)
            ?? throw new OperationRefused('الحساب غير موجود', $field);

        if (! $account->is_active) {
            throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
        }

        if ($account->kind === AccountKind::Payable) {
            throw AccountDoesNotFitMethod::payable((string) $account->name, $field);
        }

        if (! $account->kind->spendable()) {
            throw AccountDoesNotFitMethod::custody((string) $account->name, $field);
        }

        if ($account->is($source)) {
            throw new OperationRefused("الدفعة في «{$account->name}» أصلاً — اختر حساباً غيره", $field);
        }

        return $account;
    }
}
