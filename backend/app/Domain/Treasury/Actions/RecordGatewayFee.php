<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryOperation;
use DateTimeInterface;

/**
 * What a payment provider kept, out of its account, as an expense under «عمولة الدفع الإلكتروني».
 *
 * **An operation, not a bare movement**, so it shows in «المصاريف» with its category — the same
 * shape a hand expense has — and the owner can see what online payments cost. Written by the
 * system: no lock date or checkpoint guard, because the provider took it whatever we had counted.
 * Call inside the transaction that recorded what it was taken from. CUSTOMER-WALLET §٥.
 */
final class RecordGatewayFee
{
    public function __construct(private readonly PostMovement $post) {}

    public function __invoke(
        int $accountId,
        string $fee,
        DateTimeInterface $occurredAt,
        string $notes,
        ?int $actorId = null,
    ): TreasuryOperation {
        $operation = new TreasuryOperation;

        $operation->forceFill([
            'type' => OperationType::Expense,
            'amount' => $fee,
            'from_account_id' => $accountId,
            'category_id' => ExpenseCategory::query()->where('code', ExpenseCategory::ONLINE_PAYMENT_FEE)->value('id'),
            'occurred_at' => $occurredAt,
            'notes' => $notes,
            'recorded_by' => $actorId,
        ])->save();

        ($this->post)(new MovementData(
            accountId: $accountId,
            direction: MovementDirection::Out,
            kind: MovementKind::Expense,
            amount: $fee,
            occurredAt: $occurredAt,
            sourceType: AuditSubject::TreasuryOperation->value,
            sourceId: (int) $operation->getKey(),
            notes: $notes,
            recordedBy: $actorId,
            operationId: (int) $operation->getKey(),
        ));

        return $operation;
    }
}
