<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Support\Facades\DB;

/**
 * Undoes a hand operation by writing the one that says so, and mirroring every movement it made.
 *
 * The reversing operation copies its original — type, accounts, amount — and points back at it,
 * so the screen shows «سحب 300 — معكوس» with both halves side by side. **Never refused for
 * balance**: undoing a deposit whose money was already spent leaves the account below zero, and
 * that is the truth the red figure is there to tell.
 */
final class ReverseOperation
{
    public function __construct(private readonly ReverseMovement $reverseMovement) {}

    /**
     * @param  bool  $byHand  false when the system undoes what it wrote itself — a settlement
     *                        unwound because a payment it carried was reversed
     */
    public function __invoke(
        TreasuryOperation $operation,
        string $reason,
        ?int $actorId,
        bool $byHand = true,
    ): TreasuryOperation {
        if ($byHand && ! $operation->type->isReversibleByHand()) {
            throw OperationRefused::notReversible($operation->type->label());
        }

        if ($operation->isReversal()) {
            throw OperationRefused::isAReversal();
        }

        return DB::transaction(function () use ($operation, $reason, $actorId): TreasuryOperation {
            $locked = TreasuryOperation::query()->whereKey($operation->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->isReversed()) {
                throw OperationRefused::alreadyReversed();
            }

            $reversal = new TreasuryOperation;

            $reversal->forceFill([
                'type' => $locked->type,
                'amount' => (string) $locked->amount,
                'from_account_id' => $locked->from_account_id,
                'to_account_id' => $locked->to_account_id,
                'category_id' => $locked->category_id,
                'employee_id' => $locked->employee_id,
                'order_id' => $locked->order_id,
                'order_payment_id' => $locked->order_payment_id,
                'system_balance' => $locked->system_balance,
                'counted_balance' => $locked->counted_balance,
                'occurred_at' => now(),
                'notes' => $reason,
                'reverses_operation_id' => $locked->getKey(),
                'recorded_by' => $actorId,
            ])->save();

            foreach ($locked->movements()->whereNull('reverses_movement_id')->get() as $movement) {
                ($this->reverseMovement)($movement, $reason, $actorId, (int) $reversal->getKey());
            }

            return $reversal;
        });
    }
}
