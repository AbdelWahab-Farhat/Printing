<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Support\Money;
use InvalidArgumentException;

/**
 * The only writer of `treasury_movements`.
 *
 * **Deliberately without judgement.** It refuses nothing a balance could refuse — the guard
 * against spending what is not there lives in the hand operations that need it — because every
 * other caller is a fact that already happened: a customer paid, a payment was undone. Refusing
 * to record a fact does not make it untrue; it only makes the balance wrong.
 *
 * Always called inside the transaction that wrote the row it describes, so the two stand or fall
 * together. A second post of the same event meets `treasury_movements_posted_once`.
 */
final class PostMovement
{
    public function __invoke(MovementData $data): TreasuryMovement
    {
        $amount = Money::round($data->amount);

        // A programming error rather than a user's: every caller has already refused a zero or
        // negative amount in its own words. Reaching here with one means a caller forgot.
        if (! Money::isPositive($amount)) {
            throw new InvalidArgumentException("A treasury movement needs a positive amount, got {$amount}.");
        }

        $movement = new TreasuryMovement;

        $movement->forceFill([
            'account_id' => $data->accountId,
            'direction' => $data->direction,
            'kind' => $data->kind,
            'amount' => $amount,
            'occurred_at' => $data->occurredAt,
            'source_type' => $data->sourceType,
            'source_id' => $data->sourceId,
            'revision' => $data->revision,
            'operation_id' => $data->operationId,
            'order_id' => $data->orderId,
            'counterpart_account_id' => $data->counterpartAccountId,
            'reverses_movement_id' => $data->reversesMovementId,
            'notes' => $data->notes,
            'recorded_by' => $data->recordedBy,
        ])->save();

        return $movement;
    }
}
