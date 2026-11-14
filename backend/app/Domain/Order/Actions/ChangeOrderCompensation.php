<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\CompensationReason;
use App\Domain\Order\Exceptions\CompensatedOrderIsInvalid;
use App\Domain\Order\Exceptions\CompensationCannotChange;
use App\Domain\Order\Exceptions\CompensationRequiresPermission;
use App\Domain\Order\Exceptions\CompensationTakesNoCharges;
use App\Domain\Order\Models\Order;
use Illuminate\Support\Facades\DB;

/**
 * Turns an existing order into a compensation order, or back into an ordinary one.
 *
 * **A route of its own rather than a field on the edit form**, as the delivery payer has: every
 * edit re-sends the whole order, and a flag that zeroes the total must not move because a clerk
 * corrected an address. Open while the lines are ({@see Order::compensationIsEditable()}).
 *
 * The total is worked out again, and with it the payments' reading: a deposit already taken on an
 * order that becomes a compensation reads as «زائد», to be returned or kept as credit like any
 * other overpayment. That recalculation is also what re-runs the fund's cash from this order.
 */
final class ChangeOrderCompensation
{
    public function __construct(
        private readonly GuardCompensation $guard,
        private readonly RecalculateOrderTotals $recalculateTotals,
        private readonly RecalculateOrderPayments $recalculatePayments,
    ) {}

    /**
     * @throws CompensationRequiresPermission
     * @throws CompensationCannotChange
     * @throws CompensationTakesNoCharges
     * @throws CompensatedOrderIsInvalid
     */
    public function __invoke(
        Order $order,
        bool $isCompensation,
        ?CompensationReason $reason,
        ?string $note,
        ?int $originalId,
        ?User $actor,
    ): Order {
        $this->guard->permission($actor);

        return DB::transaction(function () use ($order, $isCompensation, $reason, $note, $originalId): Order {
            // The lock every money move on an order takes first.
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->compensationIsEditable()) {
                throw CompensationCannotChange::make($locked->status);
            }

            if ($isCompensation) {
                // An order other compensations name as their original stays an ordinary order —
                // otherwise those would point at a replacement rather than at the mistake.
                if ($locked->compensations()->exists()) {
                    throw CompensatedOrderIsInvalid::hasCompensations();
                }

                $this->guard->noCharges((string) $locked->discount, (string) $locked->additional_cost);
                $this->guard->original($originalId, (int) $locked->customer_id, (int) $locked->getKey());
            }

            $locked->forceFill([
                'is_compensation' => $isCompensation,
                'compensation_reason' => $isCompensation ? $reason : null,
                'compensation_note' => $isCompensation ? $note : null,
                'compensates_order_id' => $isCompensation ? $originalId : null,
            ])->save();

            ($this->recalculateTotals)($locked->load('items'));
            ($this->recalculatePayments)($locked->refresh());

            return $locked->refresh();
        });
    }
}
