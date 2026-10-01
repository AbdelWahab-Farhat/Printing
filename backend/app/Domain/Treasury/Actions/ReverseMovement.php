<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Models\TreasuryMovement;

/**
 * The mirror of a movement: same account, same kind, same amount, the other direction.
 *
 * **On the account the original hit, whatever has happened since.** If the money was moved on,
 * the account can go below zero — shown red, and meant to be seen. Never refused for balance:
 * undoing a mistake is not spending (TREASURY-DESIGN §١٢).
 *
 * Returns null when the movement is already undone, so a caller reversing "everything a source
 * posted" can run twice without failing — the partial unique index is the guarantee underneath.
 */
final class ReverseMovement
{
    public function __construct(private readonly PostMovement $post) {}

    public function __invoke(
        TreasuryMovement $original,
        ?string $notes = null,
        ?int $recordedBy = null,
        ?int $operationId = null,
    ): ?TreasuryMovement {
        if ($original->isReversal() || $original->reversedBy()->exists()) {
            return null;
        }

        return ($this->post)(new MovementData(
            accountId: (int) $original->account_id,
            direction: $original->direction->opposite(),
            kind: $original->kind,
            amount: (string) $original->amount,
            // The correction's own moment. When the mistake was caught is what this row records;
            // when the money supposedly moved is on the row it points at.
            occurredAt: now(),
            sourceType: (string) $original->source_type,
            sourceId: (int) $original->source_id,
            orderId: $original->order_id === null ? null : (int) $original->order_id,
            notes: $notes,
            recordedBy: $recordedBy,
            operationId: $operationId ?? ($original->operation_id === null ? null : (int) $original->operation_id),
            counterpartAccountId: $original->counterpart_account_id === null
                ? null
                : (int) $original->counterpart_account_id,
            reversesMovementId: (int) $original->getKey(),
        ));
    }
}
