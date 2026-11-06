<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Actions;

use App\Domain\EmployeeWallet\DTOs\EmployeeCreditData;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Queries\SentEntry;
use App\Domain\EmployeeWallet\Support\Money;
use App\Domain\Identity\AccessService;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * «مستحق» — صارت الشركة مدينةً للموظف: راتبٌ أو مكافأة. EMPLOYEE-WALLET-DESIGN §٣.
 *
 * **لا كاش يتحرك.** الخزينة تكتب مصروفاً بتصنيفه على «أرصدة محافظ الموظفين»، فيظهر في «المصاريف»
 * ويكبر الدَّين، والمال يبقى مكانه حتى يسحب الموظف. والسحبُ بعدها ليس مصروفاً ثانياً.
 *
 * **تاريخٌ من يد إنسان**، فلا يقع في فترةٍ مقفلة.
 */
final class CreditEmployeeWallet
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly AccessService $access,
        private readonly SentEntry $sent,
    ) {}

    public function __invoke(int $userId, EmployeeCreditData $data, ?int $actorId): EmployeeWalletEntry
    {
        if (! Money::isPositive($data->amount)) {
            throw new InvalidArgumentException('A wallet row moves a positive amount.');
        }

        return DB::transaction(function () use ($userId, $data, $actorId): EmployeeWalletEntry {
            $employee = $this->access->lockEmployee($userId);

            if (($sent = ($this->sent)($userId, $data->clientToken, EmployeeWalletEntryType::Credit)) !== null) {
                return $sent;
            }

            $occurredAt = $data->occurredAt ?? now();

            $this->treasury->guardManualEntry($this->treasury->employeeWalletsPayable(), $occurredAt, 'occurred_at');

            $operation = $this->treasury->recordWalletExpense(
                $data->categoryId,
                (int) $employee->getKey(),
                $data->amount,
                $occurredAt,
                $data->notes ?? "مستحق — {$employee->name}",
                $actorId,
            );

            $entry = new EmployeeWalletEntry([
                'amount' => $data->amount,
                'occurred_at' => $occurredAt,
                'notes' => $data->notes,
            ]);

            $entry->user_id = $employee->getKey();
            $entry->type = EmployeeWalletEntryType::Credit;
            $entry->expense_category_id = $data->categoryId;
            $entry->treasury_operation_id = $operation->getKey();
            $entry->recorded_by = $actorId;
            $entry->client_token = $data->clientToken;
            $entry->save();

            return $entry;
        });
    }
}
