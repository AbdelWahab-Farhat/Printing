<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\OldPaymentsCannotBeImported;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * Puts the payments recorded before the treasury existed into its accounts, on their own dates —
 * so every account's history says where its old money came from. TREASURY-DESIGN §١٧.
 *
 * **What it writes, oldest first:**
 *
 * - an old payment → into the default account of its method, or «النورس» when Nawris recorded
 *   it; the payment row is stamped with that account, so a later reversal leaves it;
 * - an old refund → out of the default account of its method;
 * - an old reversal of an old payment → the mirror, unless the treasury already wrote one when it
 *   was reversed after go-live;
 * - an order already «تم التسوية» with money left in «النورس» → the Nawris → bank transfer,
 *   dated the day it was settled.
 *
 * Write-offs and «سُدِّدت لدى الناقل» move no money and are left alone.
 *
 * **Once, and before the opening count.** Anything that already has a movement is skipped, so a
 * second run writes nothing; and it refuses outright once any account has an opening balance,
 * because the counted opening already holds this money and importing it would count it twice.
 * After it, each account is brought to its counted figure with «جرد الحساب».
 *
 * **Dry by default.** [$apply] false computes the same plan and writes nothing.
 */
final class ImportOldPaymentsIntoTreasury
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  ?int  $carrierUserId  the Nawris system user — whose payments belong in «النورس»
     * @return array{accounts: array<string, array{rows: int, in: string, out: string}>, settlements: int, settled: string, skipped: int}
     */
    public function __invoke(bool $apply, ?int $carrierUserId): array
    {
        if ($this->treasury->hasAnyOpening()) {
            throw OldPaymentsCannotBeImported::afterOpening();
        }

        $plan = $this->plan($carrierUserId);

        if ($apply) {
            DB::transaction(fn () => $this->write($plan));
        }

        return $this->report($plan);
    }

    /**
     * Every movement the import would write, and every settlement, in date order.
     *
     * @return array{movements: list<array{payment: OrderPayment, account: TreasuryAccount, direction: MovementDirection, stamp: bool}>, settlements: array<int, array{order: Order, amount: string}>, skipped: int}
     */
    private function plan(?int $carrierUserId): array
    {
        $nawris = $this->treasury->systemAccount(TreasuryAccount::NAWRIS);
        $movements = [];
        $nawrisNet = [];
        $skipped = 0;

        // The account each old payment was put in by this plan — its reversal leaves the same one.
        $placed = [];

        $rows = OrderPayment::query()
            ->whereNull('treasury_account_id')
            ->whereIn('type', [OrderPaymentType::Payment->value, OrderPaymentType::Refund->value, OrderPaymentType::Reversal->value])
            ->with('reversedPayment')
            ->orderBy('paid_at')
            ->orderBy('id')
            ->get();

        foreach ($rows as $row) {
            if ($row->type === OrderPaymentType::Reversal) {
                $original = $row->reversedPayment;

                // Only an old payment's reversal: a write-off's moved no money, and a reversal of
                // a payment made after go-live was mirrored when it happened.
                if ($original === null || $original->type !== OrderPaymentType::Payment
                    || $original->treasury_account_id !== null) {
                    continue;
                }

                if ($this->alreadyPosted($original, MovementDirection::Out)) {
                    $skipped++;

                    continue;
                }

                // Where the original went in: placed by this run, else already posted by an earlier
                // one, else where this run would have put it.
                $posted = $this->treasury->liveMovementsOf($original->getMorphClass(), (int) $original->getKey())
                    ->firstWhere('direction', MovementDirection::In);

                $account = $placed[$original->getKey()]
                    ?? ($posted === null ? null : TreasuryAccount::query()->find($posted->account_id))
                    ?? $this->accountOf($original, $carrierUserId, $nawris);
                $movements[] = ['payment' => $original, 'account' => $account, 'direction' => MovementDirection::Out, 'stamp' => false, 'at' => $row->paid_at];
                $this->track($nawrisNet, $original, $account, $nawris, '-');

                continue;
            }

            $direction = $row->type === OrderPaymentType::Payment ? MovementDirection::In : MovementDirection::Out;

            if ($this->alreadyPosted($row, $direction)) {
                $skipped++;

                continue;
            }

            // Reversed after go-live on the fallback account: the payment goes in there too, so
            // the pair cancels on one account instead of leaving two accounts wrong.
            $mirror = $direction === MovementDirection::In
                ? $this->treasury->liveMovementsOf($row->getMorphClass(), (int) $row->getKey())
                    ->firstWhere('direction', MovementDirection::Out)
                : null;

            $account = $mirror !== null
                ? TreasuryAccount::query()->findOrFail($mirror->account_id)
                : $this->accountOf($row, $carrierUserId, $nawris);

            $placed[$row->getKey()] = $account;
            $movements[] = ['payment' => $row, 'account' => $account, 'direction' => $direction, 'stamp' => true, 'at' => $row->paid_at];
            $this->track($nawrisNet, $row, $account, $nawris, $direction === MovementDirection::In ? '+' : '-');
        }

        return [
            'movements' => $movements,
            'settlements' => $this->settlementsFor($nawrisNet),
            'skipped' => $skipped,
        ];
    }

    private function accountOf(OrderPayment $payment, ?int $carrierUserId, TreasuryAccount $nawris): TreasuryAccount
    {
        if ($carrierUserId !== null && (int) $payment->recorded_by === $carrierUserId) {
            return $nawris;
        }

        return $this->treasury->accountFor(
            $payment->method->value,
            null,
            incoming: $payment->type === OrderPaymentType::Payment,
        );
    }

    private function alreadyPosted(OrderPayment $payment, MovementDirection $direction): bool
    {
        return $this->treasury->liveMovementsOf($payment->getMorphClass(), (int) $payment->getKey())
            ->contains(fn ($movement) => $movement->direction === $direction);
    }

    /**
     * @param  array<int, string>  $net
     */
    private function track(array &$net, OrderPayment $payment, TreasuryAccount $account, TreasuryAccount $nawris, string $sign): void
    {
        if (! $account->is($nawris)) {
            return;
        }

        $orderId = (int) $payment->order_id;
        $net[$orderId] = bcadd($net[$orderId] ?? '0', $sign.$payment->amount, 2);
    }

    /**
     * The orders already settled that the import leaves money for in «النورس».
     *
     * @param  array<int, string>  $nawrisNet
     * @return array<int, array{order: Order, amount: string}>
     */
    private function settlementsFor(array $nawrisNet): array
    {
        $settled = [];

        $orders = Order::query()
            ->whereIn('id', array_keys($nawrisNet))
            ->where('status', OrderStatus::Settled->value)
            ->whereNotNull('settled_at')
            ->get();

        foreach ($orders as $order) {
            $amount = $nawrisNet[(int) $order->getKey()];

            if (bccomp($amount, '0', 2) > 0) {
                $settled[(int) $order->getKey()] = ['order' => $order, 'amount' => $amount];
            }
        }

        return $settled;
    }

    /**
     * @param  array{movements: list<array<string, mixed>>, settlements: array<int, array{order: Order, amount: string}>, skipped: int}  $plan
     */
    private function write(array $plan): void
    {
        foreach ($plan['movements'] as $step) {
            /** @var OrderPayment $payment */
            $payment = $step['payment'];
            /** @var TreasuryAccount $account */
            $account = $step['account'];

            if ($step['stamp']) {
                // The account the money went into, stamped so a later reversal leaves it.
                $payment->forceFill(['treasury_account_id' => $account->getKey()])->save();
            }

            $this->treasury->post(new MovementData(
                accountId: (int) $account->getKey(),
                direction: $step['direction'],
                kind: $payment->type === OrderPaymentType::Refund ? MovementKind::Refund : MovementKind::Payment,
                amount: (string) $payment->amount,
                occurredAt: $step['at'],
                sourceType: $payment->getMorphClass(),
                sourceId: (int) $payment->getKey(),
                orderId: (int) $payment->order_id,
                notes: 'استيراد دفعة سابقة لنظام الحسابات',
            ));
        }

        foreach ($plan['settlements'] as $settlement) {
            $order = $settlement['order'];

            $this->treasury->settleCustody(
                (int) $order->getKey(),
                null,
                null,
                null,
                (string) $order->code,
                $order->settled_at,
                // The old money was filed in the defaults; today's collection switches say
                // nothing of the day these were settled.
                collect: false,
            );
        }
    }

    /**
     * @param  array{movements: list<array<string, mixed>>, settlements: array<int, array{order: Order, amount: string}>, skipped: int}  $plan
     * @return array{accounts: array<string, array{rows: int, in: string, out: string}>, settlements: int, settled: string, skipped: int}
     */
    private function report(array $plan): array
    {
        $accounts = [];

        foreach ($plan['movements'] as $step) {
            $name = (string) $step['account']->name;
            $accounts[$name] ??= ['rows' => 0, 'in' => '0.00', 'out' => '0.00'];
            $accounts[$name]['rows']++;

            $side = $step['direction'] === MovementDirection::In ? 'in' : 'out';
            $accounts[$name][$side] = bcadd($accounts[$name][$side], (string) $step['payment']->amount, 2);
        }

        $settled = '0.00';

        foreach ($plan['settlements'] as $settlement) {
            $settled = bcadd($settled, $settlement['amount'], 2);
        }

        return [
            'accounts' => $accounts,
            'settlements' => count($plan['settlements']),
            'settled' => $settled,
            'skipped' => $plan['skipped'],
        ];
    }
}
