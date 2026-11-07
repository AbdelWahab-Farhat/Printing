<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryOperation;
use DateTimeInterface;

/**
 * مستحقٌّ لموظف، مصروفاً على «أرصدة محافظ الموظفين» — EMPLOYEE-WALLET-DESIGN §٣.
 *
 * **عمليةٌ لا حركةٌ مجرّدة**، ليظهر في «المصاريف» بتصنيفه واسم الموظف كأيّ مصروف، على نسق
 * {@see RecordGatewayFee}. ويكتبها النظام: لا تُعكس باليد، والمحفظةُ تعكسها مع سطرها.
 *
 * **ولا كاش يتحرك**: الشركة صارت مدينة، فالدَّين يكبر والمال باقٍ في مكانه حتى يسحب الموظف.
 *
 * يُستدعى داخل المعاملة التي تكتب سطر المحفظة.
 */
final class RecordWalletExpense
{
    public function __construct(private readonly PostMovement $post) {}

    public function __invoke(
        int $accountId,
        int $categoryId,
        int $employeeId,
        string $amount,
        DateTimeInterface $occurredAt,
        string $notes,
        ?int $actorId,
    ): TreasuryOperation {
        $category = ExpenseCategory::query()->findOrFail($categoryId);

        if (! $category->is_active) {
            throw OperationRefused::categoryInactive((string) $category->name);
        }

        if ($category->isSystem() && ! in_array($category->code, ExpenseCategory::FOR_EMPLOYEE_WALLETS, true)) {
            throw OperationRefused::categoryNotForWallet((string) $category->name);
        }

        $operation = new TreasuryOperation;

        $operation->forceFill([
            'type' => OperationType::WalletExpense,
            'amount' => $amount,
            'from_account_id' => $accountId,
            'category_id' => $category->getKey(),
            'employee_id' => $employeeId,
            'occurred_at' => $occurredAt,
            'notes' => $notes,
            'recorded_by' => $actorId,
        ])->save();

        ($this->post)(new MovementData(
            accountId: $accountId,
            direction: MovementDirection::Out,
            kind: OperationType::WalletExpense->movementKind(),
            amount: $amount,
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
