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
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\Queries\CustodyForOrder;
use App\Domain\Treasury\Support\AccountResolver;
use App\Domain\Treasury\Support\Money;
use DateTimeInterface;
use Illuminate\Support\Collection;

/**
 * «تم التسوية» for the money: what Nawris or a driver holds for this order moves to the account
 * it actually reached — TREASURY-DESIGN §٦.
 *
 * **Not a second payment.** The customer paid once, when the money was collected, and that is
 * when it counted. This only moves it: custody out, the receiving account in, under one
 * `settlement` operation that names the order.
 *
 * **What the carrier kept** comes out of custody as an expense under «رسوم شركة التوصيل» and
 * never reaches the receiving account; the rest does.
 *
 * Nothing in custody — the customer paid straight into the bank, or at the counter — means
 * nothing to move, and null comes back. Never refused for balance: custody holds exactly what
 * it is asked to hand over, by construction.
 */
final class SettleCustody
{
    public function __construct(
        private readonly CustodyForOrder $custody,
        private readonly AccountResolver $resolver,
        private readonly PostMovement $post,
        private readonly CollectOrderMoney $collect,
    ) {}

    /**
     * @param  array<string, int>  $choices  kind => the settler's account picked for it (§٢٢)
     */
    public function __invoke(
        int $orderId,
        ?int $destinationId,
        ?string $fee,
        ?int $actorId,
        DateTimeInterface $occurredAt,
        ?string $orderCode = null,
        string $accountField = 'settlement_account_id',
        string $feeField = 'settlement_fee',
        bool $applySettings = true,
        array $choices = [],
    ): ?TreasuryOperation {
        // قبل أي قراءة: قاعدةُ الطلب (min:0) تحمي الشاشة، لا نداءً من داخل الخادم. رسومٌ سالبة
        // كانت ستُخرج من العهدة أكثر مما فيها وتُدخل الحسابَ مالاً لم يوجد.
        if ($fee !== null && bccomp(Money::round($fee), '0', Money::SCALE) < 0) {
            throw new OperationRefused('ما احتفظ به الناقل لا يكون سالباً', $feeField);
        }

        $held = $this->custody->of($orderId);

        if ($held === []) {
            return null;
        }

        // Lock the custody accounts, then read again: two settlements of one order racing each
        // other would otherwise both carry the same money on. The second now finds nothing.
        TreasuryAccount::query()->whereIn('id', array_keys($held))->orderBy('id')->lockForUpdate()->get();
        $held = $this->custody->of($orderId);

        if ($held === []) {
            return null;
        }

        $total = Money::sum('0', ...array_values($held));
        $fee = $fee === null ? '0.00' : Money::round($fee);

        if (bccomp($fee, $total, Money::SCALE) > 0) {
            throw new OperationRefused("ما احتفظ به الناقل ({$fee}) أكبر من المال في العهدة ({$total})", $feeField);
        }

        $custodyAccounts = TreasuryAccount::query()->whereIn('id', array_keys($held))->get()->keyBy('id');
        $destination = $this->destination($destinationId, $actorId, $custodyAccounts, $accountField, $applySettings, $choices);
        $feeCategory = Money::isPositive($fee)
            ? ExpenseCategory::query()->where('code', ExpenseCategory::CARRIER_FEE)->first()
            : null;

        $operation = new TreasuryOperation;

        $operation->forceFill([
            'type' => OperationType::Settlement,
            'amount' => $total,
            'to_account_id' => $destination->getKey(),
            'category_id' => $feeCategory?->getKey(),
            'order_id' => $orderId,
            'occurred_at' => $occurredAt,
            'notes' => $orderCode === null ? null : "تسوية الطلبية {$orderCode}",
            'recorded_by' => $actorId,
        ])->save();

        $move = fn (int $accountId, MovementDirection $direction, MovementKind $kind, string $amount, ?int $other) => ($this->post)(new MovementData(
            accountId: $accountId,
            direction: $direction,
            kind: $kind,
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

        // The carrier's cut leaves the first custody account holding enough — in practice there
        // is one, Nawris's.
        $feeLeft = $fee;

        foreach ($held as $accountId => $amount) {
            $cut = bccomp($feeLeft, $amount, Money::SCALE) > 0 ? $amount : $feeLeft;
            $carried = Money::round(bcsub($amount, $cut, 8));
            $feeLeft = Money::round(bcsub($feeLeft, $cut, 8));

            if (Money::isPositive($carried)) {
                $move($accountId, MovementDirection::Out, MovementKind::Settlement, $carried, (int) $destination->getKey());
            }

            if (Money::isPositive($cut)) {
                $move($accountId, MovementDirection::Out, MovementKind::Expense, $cut, null);
            }
        }

        $received = Money::round(bcsub($total, $fee, 8));

        if (Money::isPositive($received)) {
            $move((int) $destination->getKey(), MovementDirection::In, MovementKind::Settlement, $received, (int) array_key_first($held));
        }

        return $operation;
    }

    /**
     * Where the money arrived, in this order:
     *
     * 1. the account picked on the settle screen;
     * 2. the one the settler holds — when «الحساب الشخصي أولاً» is on;
     * 3. the custody account's own «تُسوّى إلى», set in «إعدادات المالية»;
     * 4. the bank for Nawris's money (it pays by transfer), the cash box for a driver's.
     *
     * Anything but a hand-picked account then goes on to the settler's own account of its kind
     * when «التسوية إلى حساب المسوّي» is on (§٢٢), or else to its kind's collecting account when
     * «التجميع عند التسوية» is on for it (§١٨) — straight there, rather than landing in Ali's bank
     * only to be collected out of it a moment later.
     *
     * @param  Collection<int, TreasuryAccount>  $custodyAccounts
     * @param  bool  $applySettings  false لاستيراد الطلبيات القديمة: «تُسوّى إلى» والتجميعُ
     *                               مفاتيحُ اليوم، والمالُ القديم سُجِّل في الافتراضيات (§١٧)
     * @param  array<string, int>  $choices  the settler's account picked per kind (§٢٢)
     */
    private function destination(
        ?int $chosenId,
        ?int $actorId,
        Collection $custodyAccounts,
        string $field,
        bool $applySettings,
        array $choices = [],
    ): TreasuryAccount {
        if ($chosenId !== null) {
            $account = TreasuryAccount::query()->findOrFail($chosenId);

            if (! $account->is_active) {
                throw AccountDoesNotFitMethod::inactive((string) $account->name, $field);
            }

            if (! $account->kind->spendable()) {
                throw AccountDoesNotFitMethod::custody((string) $account->name, $field);
            }

            return $account;
        }

        $landing = $this->automatic($actorId, $custodyAccounts, $applySettings);

        return $applySettings ? $this->collect->redirect($landing, $actorId, $choices) : $landing;
    }

    /**
     * Where this order's custody money would land if nobody picked an account, before the
     * settler's account or collection takes it on — what the settle screen groups it under (§٢٢).
     * Null when nothing is in custody.
     */
    public function landingFor(int $orderId, ?int $actorId): ?TreasuryAccount
    {
        $held = $this->custody->of($orderId);

        if ($held === []) {
            return null;
        }

        return $this->automatic($actorId, TreasuryAccount::query()->whereIn('id', array_keys($held))->get(), true);
    }

    /**
     * Where money held in this one custody account lands when nobody picks — «تسوية دفعة» (§٢٣)
     * settling one of Nawris's payments asks what the whole order's settlement would have.
     */
    public function landingForCustody(TreasuryAccount $custody, ?int $actorId): TreasuryAccount
    {
        return $this->automatic($actorId, collect([$custody]), true);
    }

    /**
     * Rules 2–4 of {@see destination()}.
     *
     * @param  Collection<int, TreasuryAccount>  $custodyAccounts
     */
    private function automatic(?int $actorId, Collection $custodyAccounts, bool $applySettings): TreasuryAccount
    {
        $fromNawris = $custodyAccounts->contains(fn (TreasuryAccount $a) => $a->system_code === TreasuryAccount::NAWRIS);

        if ($actorId !== null && TreasurySetting::current()->own_account_first) {
            $held = TreasuryAccount::query()
                ->active()
                ->where('holder_user_id', $actorId)
                ->where('kind', '<>', AccountKind::Custody->value)
                ->limit(2)
                ->get();

            if ($held->count() === 1) {
                return $held->first();
            }
        }

        // A switched-off or since-removed target is skipped rather than refused: the settlement
        // is a fact, and the built-in rule below always has an answer.
        foreach ($applySettings ? $custodyAccounts : [] as $custody) {
            $target = $custody->settles_into_account_id === null
                ? null
                : TreasuryAccount::query()->find($custody->settles_into_account_id);

            if ($target !== null && $target->is_active && $target->kind->spendable()) {
                return $target;
            }
        }

        return $this->resolver->defaultOf($fromNawris ? AccountKind::Bank : AccountKind::Cash);
    }
}
