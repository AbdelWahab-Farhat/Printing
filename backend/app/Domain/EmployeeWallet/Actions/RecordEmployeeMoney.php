<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Actions;

use App\Domain\EmployeeWallet\DTOs\EmployeeMoneyData;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletBalanceTooLow;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletNeedsReceipt;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Queries\EmployeeWalletBalances;
use App\Domain\EmployeeWallet\Queries\SentEntry;
use App\Domain\EmployeeWallet\Support\Money;
use App\Domain\Identity\AccessService;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Support\Media\StoreReceipt;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * مالٌ عبر الطاولة: «إيداع» سلّمه الموظف، أو «سحب» قبضه. EMPLOYEE-WALLET-DESIGN §٣.
 *
 * **حركتان ومصدرٌ واحد.** المال يدخل الحساب الذي وصله أو يخرج من الذي دفعه، والدَّين يتحرك عكسه على
 * «أرصدة محافظ الموظفين». كلتاهما تشير إلى هذا السطر، فعكسُه يعكس الاثنتين.
 *
 * **السقفُ يُقرأ تحت قفل الموظف** لا من رقمٍ جُلب قبله، وإلا قرأ سحبان متزامنان الرصيد نفسه ومرّا.
 * **والأقفال بترتيبٍ واحد**: الموظف ثم الحساب.
 *
 * **مالُ يدٍ، فقواعدُ اليد عليه**: لا تاريخ في فترةٍ مقفلة ولا قبل آخر جرد للحساب. والإيداع لا يُرفض
 * لرصيد — مالٌ وصل فعلاً — والسحب يُرفض إن لم يكن في الحساب ما يكفي، ما دام «منع الرصيد السالب» مفعّلاً.
 */
final class RecordEmployeeMoney
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly AccessService $access,
        private readonly EmployeeWalletBalances $balances,
        private readonly SentEntry $sent,
        private readonly StoreReceipt $storeReceipt,
    ) {}

    public function __invoke(
        int $userId,
        EmployeeWalletEntryType $type,
        EmployeeMoneyData $data,
        ?int $actorId,
    ): EmployeeWalletEntry {
        if ($type !== EmployeeWalletEntryType::Deposit && $type !== EmployeeWalletEntryType::Withdrawal) {
            throw new InvalidArgumentException('Only a deposit or a withdrawal moves money through an account.');
        }

        if (! Money::isPositive($data->amount)) {
            throw new InvalidArgumentException('A wallet row moves a positive amount.');
        }

        return DB::transaction(function () use ($userId, $type, $data, $actorId): EmployeeWalletEntry {
            $employee = $this->access->lockEmployee($userId);

            // قبل حارس الواصل والرصيد: الإعادةُ هي الطلب الأول نفسه، ولو تغيّر الرصيد بعده.
            if (($sent = ($this->sent)($userId, $data->clientToken, $type)) !== null) {
                return $sent;
            }

            if ($data->method->requiresReceipt() && $data->receipt === null) {
                throw EmployeeWalletNeedsReceipt::make($data->method);
            }

            $incoming = $type === EmployeeWalletEntryType::Deposit;

            if (! $incoming) {
                $this->guardBalance($userId, $data->amount);
            }

            $occurredAt = $data->occurredAt ?? now();

            $account = $this->treasury->accountFor($data->method->value, $actorId, $data->treasuryAccountId, incoming: $incoming);
            $this->treasury->guardManualEntry($account, $occurredAt, 'occurred_at');

            if (! $incoming) {
                $this->treasury->guardCanSpend($account, $data->amount, 'amount', $actorId);
            }

            $entry = new EmployeeWalletEntry([
                'amount' => $data->amount,
                'reference' => $data->reference,
                'occurred_at' => $occurredAt,
                'notes' => $data->notes,
            ]);

            $entry->user_id = $employee->getKey();
            $entry->type = $type;
            $entry->method = $data->method;
            $entry->treasury_account_id = $account->getKey();
            $entry->recorded_by = $actorId;
            // مختومٌ لا مملوء: الرمزُ رمزُ الطلب، يُقرَّر عند الباب.
            $entry->client_token = $data->clientToken;

            if ($data->receipt !== null) {
                $entry->forceFill(($this->storeReceipt)("employee-wallet-receipts/{$employee->getKey()}", $data->receipt));
            }

            $entry->save();

            $this->post($entry, $employee, $account, $incoming, $actorId);

            return $entry;
        });
    }

    private function guardBalance(int $userId, string $amount): void
    {
        $balance = $this->balances->of($userId);

        if (bccomp($amount, $balance, Money::SCALE) > 0) {
            throw EmployeeWalletBalanceTooLow::make($amount, $balance);
        }
    }

    private function post(
        EmployeeWalletEntry $entry,
        User $employee,
        TreasuryAccount $account,
        bool $incoming,
        ?int $actorId,
    ): void {
        $payable = $this->treasury->employeeWalletsPayable();
        $kind = $incoming ? MovementKind::EmployeeWalletDeposit : MovementKind::EmployeeWalletWithdrawal;
        $notes = "{$entry->type->label()} — {$employee->name}";

        $movement = fn (TreasuryAccount $on, MovementDirection $direction, TreasuryAccount $other) => new MovementData(
            accountId: (int) $on->getKey(),
            direction: $direction,
            kind: $kind,
            amount: (string) $entry->amount,
            occurredAt: $entry->occurred_at,
            sourceType: $entry->getMorphClass(),
            sourceId: (int) $entry->getKey(),
            notes: $notes,
            recordedBy: $actorId,
            counterpartAccountId: (int) $other->getKey(),
        );

        $this->treasury->post($movement($account, $incoming ? MovementDirection::In : MovementDirection::Out, $payable));
        $this->treasury->post($movement($payable, $incoming ? MovementDirection::Out : MovementDirection::In, $account));
    }
}
