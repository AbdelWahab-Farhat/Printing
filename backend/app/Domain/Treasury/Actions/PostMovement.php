<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Models\TreasuryAccount;
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

        $this->guardCurrency($data);

        $movement = new TreasuryMovement;

        $movement->forceFill([
            'account_id' => $data->accountId,
            'direction' => $data->direction,
            'kind' => $data->kind,
            'amount' => $amount,
            'dinar_amount' => $data->dinarAmount === null ? null : Money::round($data->dinarAmount),
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

    /**
     * **Dinars never land in a dollar account by accident** — USD-ACCOUNTS §٣. Not a judgement
     * about balances, which this class refuses to make, but about units: a customer's 500 dinars
     * written onto a dollar account would read as $500. Every path that may reach a dollar account
     * refuses it in its own words first, so arriving here with one is a caller that forgot — a
     * programming error, like a zero amount.
     */
    private function guardCurrency(MovementData $data): void
    {
        // `value()` applies the model's cast, so this is the enum, not the stored text.
        if (TreasuryAccount::query()->whereKey($data->accountId)->value('currency') !== Currency::Usd) {
            return;
        }

        if (! in_array($data->kind, Currency::dollarMovementKinds(), true)) {
            throw new InvalidArgumentException(
                "A {$data->kind->value} movement cannot land in dollar account {$data->accountId}.",
            );
        }
    }
}
