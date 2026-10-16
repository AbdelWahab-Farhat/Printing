<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\OnlinePayment\Support\Money;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * «تحويل Ezone إلى المصرف» — EzonePay paid out what it collected. CUSTOMER-WALLET §٥ (step 6).
 *
 * **Two hand operations, in one transaction**: a transfer of what arrived from «Ezone» to the bank,
 * and — when EzonePay kept something at payout — an expense out of «Ezone» under «عمولة الدفع
 * الإلكتروني». Both go through `RecordOperation`, so every hand rule holds: the lock date, the
 * last count, no overdraft, a reason a reversal needs, and the request key (`client_token`) on the
 * transfer, so a retry records nothing twice. Undone the way any operation is.
 */
final class RecordEzonePayout
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  ?int  $bankAccountId  where it arrived — null: the bank's default, like «تلقائي» on a payment
     */
    public function __invoke(
        string $received,
        ?string $kept,
        ?int $bankAccountId,
        Carbon $occurredAt,
        ?string $reference,
        ?User $actor,
        ?string $clientToken = null,
    ): TreasuryOperation {
        $ezone = $this->treasury->systemAccount(TreasuryAccount::EZONE);
        $bankAccountId ??= (int) $this->treasury->defaultAccountOf(AccountKind::Bank)->getKey();
        $notes = trim('تحويل Ezone إلى المصرف '.($reference ?? ''));

        return DB::transaction(function () use ($received, $kept, $bankAccountId, $occurredAt, $notes, $actor, $ezone, $clientToken): TreasuryOperation {
            $transfer = $this->treasury->recordOperation(new OperationData(
                type: OperationType::Transfer,
                amount: $received,
                fromAccountId: (int) $ezone->getKey(),
                toAccountId: $bankAccountId,
                categoryId: null,
                employeeId: null,
                countedBalance: null,
                occurredAt: $occurredAt,
                notes: $notes,
                clientToken: $clientToken,
                ezonePayout: true,
            ), $actor);

            // A retried request is the first transfer; its fee was recorded with it.
            if (! $transfer->wasRecentlyCreated || $kept === null || ! Money::isPositive($kept)) {
                return $transfer;
            }

            $this->treasury->recordOperation(new OperationData(
                type: OperationType::Expense,
                amount: $kept,
                fromAccountId: (int) $ezone->getKey(),
                toAccountId: null,
                categoryId: (int) ExpenseCategory::query()->where('code', ExpenseCategory::ONLINE_PAYMENT_FEE)->value('id'),
                employeeId: null,
                countedBalance: null,
                occurredAt: $occurredAt,
                notes: "رسوم تحويل Ezone {$notes}",
                ezonePayout: true,
            ), $actor);

            return $transfer;
        });
    }
}
