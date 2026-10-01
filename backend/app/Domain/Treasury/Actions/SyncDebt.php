<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Support\Money;
use DateTimeInterface;

/**
 * Makes the debt one source stands for equal what it says now — a purchase order's total, owed
 * to its vendor from the moment it is raised (TREASURY-DESIGN §٢٠).
 *
 * **Idempotent, and append-only.** The same figure on the same account writes nothing. A new
 * figure, a new vendor or a cancelled order reverses whatever stands and, unless the debt is now
 * nothing, posts the new one under the next `revision` — the reversed original still holds its
 * place in `treasury_movements_posted_once`. So the statement reads «أمر شراء 1,000», then
 * «أمر شراء −1,000 · أمر شراء 1,200» on the day it was edited.
 */
final class SyncDebt
{
    public function __construct(
        private readonly PostMovement $post,
        private readonly ReverseMovement $reverse,
    ) {}

    /**
     * @param  ?int  $accountId  the payable owed to; null when nothing is owed any more
     * @param  DateTimeInterface  $firstPostedAt  when the debt arose — used for its first posting
     *                                            only; a later change is dated when it is made
     * @param  string  $reason  the note on a reversal — «تعديل أمر الشراء 12», «إلغاء …»
     */
    public function __invoke(
        string $sourceType,
        int $sourceId,
        MovementKind $kind,
        ?int $accountId,
        string $amount,
        DateTimeInterface $firstPostedAt,
        string $notes,
        string $reason,
        ?int $actorId,
    ): void {
        $amount = Money::round($amount);
        $wanted = $accountId !== null && Money::isPositive($amount);

        $posted = TreasuryMovement::query()
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->where('kind', $kind->value)
            ->whereNull('reverses_movement_id')
            ->get();

        $live = TreasuryMovement::query()
            ->whereIn('id', $posted->modelKeys())
            ->whereDoesntHave('reversedBy')
            ->get();

        if ($wanted && $live->count() === 1
            && (int) $live->first()->account_id === $accountId
            && bccomp((string) $live->first()->amount, $amount, Money::SCALE) === 0) {
            return;
        }

        if (! $wanted && $live->isEmpty()) {
            return;
        }

        foreach ($live as $movement) {
            ($this->reverse)($movement, $reason, $actorId);
        }

        if (! $wanted) {
            return;
        }

        ($this->post)(new MovementData(
            accountId: $accountId,
            direction: MovementDirection::Out,
            kind: $kind,
            amount: $amount,
            occurredAt: $posted->isEmpty() ? $firstPostedAt : now(),
            sourceType: $sourceType,
            sourceId: $sourceId,
            notes: $notes,
            recordedBy: $actorId,
            revision: $posted->isEmpty() ? 0 : (int) $posted->max('revision') + 1,
        ));
    }
}
