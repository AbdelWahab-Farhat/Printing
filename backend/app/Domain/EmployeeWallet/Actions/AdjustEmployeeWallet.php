<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Actions;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletBalanceTooLow;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Queries\EmployeeWalletBalances;
use App\Domain\EmployeeWallet\Queries\SentEntry;
use App\Domain\EmployeeWallet\Support\Money;
use App\Domain\Identity\AccessService;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * «تعديل الرصيد» — رصيدٌ صُحّح باليد بسبب، ممن يملك الصلاحية. وهو باب الرصيد الافتتاحي يوم الإطلاق.
 *
 * **لا مال يتحرك**، فأثره الوحيد على «أرصدة محافظ الموظفين»: الزيادة دَينٌ أكبر (`out`)، والنقص أصغر
 * (`in`). والحساب يبقى سالبَ مجموع المحافظ. ولا ينزل النقصُ بالمحفظة تحت الصفر.
 */
final class AdjustEmployeeWallet
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly AccessService $access,
        private readonly EmployeeWalletBalances $balances,
        private readonly SentEntry $sent,
    ) {}

    public function __invoke(
        int $userId,
        string $amount,
        bool $credit,
        string $reason,
        ?string $clientToken,
        ?int $actorId,
    ): EmployeeWalletEntry {
        if (! Money::isPositive($amount)) {
            throw new InvalidArgumentException('An adjustment moves a positive amount.');
        }

        $type = $credit ? EmployeeWalletEntryType::AdjustmentCredit : EmployeeWalletEntryType::AdjustmentDebit;

        return DB::transaction(function () use ($userId, $amount, $credit, $reason, $clientToken, $actorId, $type): EmployeeWalletEntry {
            $employee = $this->access->lockEmployee($userId);

            if (($sent = ($this->sent)($userId, $clientToken, $type)) !== null) {
                return $sent;
            }

            if (! $credit) {
                $balance = $this->balances->of($userId);

                if (bccomp($amount, $balance, Money::SCALE) > 0) {
                    throw EmployeeWalletBalanceTooLow::make($amount, $balance);
                }
            }

            $entry = new EmployeeWalletEntry([
                'amount' => $amount,
                'occurred_at' => now(),
                'notes' => $reason,
            ]);

            $entry->user_id = $employee->getKey();
            $entry->type = $type;
            $entry->recorded_by = $actorId;
            $entry->client_token = $clientToken;
            $entry->save();

            $this->treasury->post(new MovementData(
                accountId: (int) $this->treasury->employeeWalletsPayable()->getKey(),
                direction: $credit ? MovementDirection::Out : MovementDirection::In,
                kind: MovementKind::EmployeeWalletAdjustment,
                amount: (string) $entry->amount,
                occurredAt: $entry->occurred_at,
                sourceType: $entry->getMorphClass(),
                sourceId: (int) $entry->getKey(),
                notes: "{$entry->type->label()} — {$employee->name}: {$reason}",
                recordedBy: $actorId,
            ));

            return $entry;
        });
    }
}
