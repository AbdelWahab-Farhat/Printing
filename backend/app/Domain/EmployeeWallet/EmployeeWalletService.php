<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet;

use App\Domain\EmployeeWallet\Actions\AdjustEmployeeWallet;
use App\Domain\EmployeeWallet\Actions\CreditEmployeeWallet;
use App\Domain\EmployeeWallet\Actions\RecordEmployeeMoney;
use App\Domain\EmployeeWallet\Actions\ReverseEmployeeWalletEntry;
use App\Domain\EmployeeWallet\DTOs\EmployeeCreditData;
use App\Domain\EmployeeWallet\DTOs\EmployeeMoneyData;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Events\EmployeeWalletMoved;
use App\Domain\EmployeeWallet\Exceptions\OwnWalletRefused;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Queries\EmployeeWalletBalances;
use App\Domain\EmployeeWallet\Support\BusinessDay;
use App\Domain\EmployeeWallet\Support\OwnWalletRule;
use App\Domain\Identity\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * باب «محفظة الموظف» — Docs/employees/EMPLOYEE-WALLET-DESIGN.md.
 *
 * **سياقٌ مستقلّ عن محفظة الزبون**: تلك مربوطةٌ بالطلبيات وفيها مال حقيقي، وهذا العمل لا يمسّها. هذا
 * السياق يعتمد على `Treasury` و`Identity` وحدهما، ولا يستورده أحد — الإشعارات تصغي لحدثه.
 *
 * **كلُّ كتابةٍ تمرّ بهذا الباب**، لأن قاعدة «لا تحرّك محفظتك بنفسك» وإعلانَ الحركة يسكنان هنا مرّةً
 * واحدة بدل أن يتذكّرهما كل فعل.
 */
final class EmployeeWalletService
{
    public function __construct(
        private readonly EmployeeWalletBalances $balances,
        private readonly RecordEmployeeMoney $money,
        private readonly CreditEmployeeWallet $credit,
        private readonly AdjustEmployeeWallet $adjust,
        private readonly ReverseEmployeeWalletEntry $reverse,
    ) {}

    public function balanceOf(int $userId): string
    {
        return $this->balances->of($userId);
    }

    /** أيحرّك هذا الموظفُ هذه المحفظة — {@see OwnWalletRule}. */
    public function mayMove(User $actor, int $userId): bool
    {
        return OwnWalletRule::allows($actor, $userId);
    }

    // ── الكتابة ──────────────────────────────────────────────────────────────────────────

    public function deposit(int $userId, EmployeeMoneyData $data, User $actor): EmployeeWalletEntry
    {
        $this->guardNotOwn($actor, $userId);

        return $this->announced(
            ($this->money)($userId, EmployeeWalletEntryType::Deposit, $data, (int) $actor->getKey()),
            $actor,
        );
    }

    public function withdraw(int $userId, EmployeeMoneyData $data, User $actor): EmployeeWalletEntry
    {
        $this->guardNotOwn($actor, $userId);

        return $this->announced(
            ($this->money)($userId, EmployeeWalletEntryType::Withdrawal, $data, (int) $actor->getKey()),
            $actor,
        );
    }

    public function credit(int $userId, EmployeeCreditData $data, User $actor): EmployeeWalletEntry
    {
        $this->guardNotOwn($actor, $userId);

        return $this->announced(($this->credit)($userId, $data, (int) $actor->getKey()), $actor);
    }

    public function adjust(
        int $userId,
        string $amount,
        bool $credit,
        string $reason,
        ?string $clientToken,
        User $actor,
    ): EmployeeWalletEntry {
        $this->guardNotOwn($actor, $userId);

        return $this->announced(
            ($this->adjust)($userId, $amount, $credit, $reason, $clientToken, (int) $actor->getKey()),
            $actor,
        );
    }

    public function reverse(EmployeeWalletEntry $entry, string $reason, User $actor): EmployeeWalletEntry
    {
        $this->guardNotOwn($actor, (int) $entry->user_id);

        return $this->announced(($this->reverse)($entry, $reason, (int) $actor->getKey()), $actor);
    }

    // ── القراءة ──────────────────────────────────────────────────────────────────────────

    /**
     * سطور محفظةٍ واحدة، الأحدث أولاً.
     *
     * @param  array{type?: ?string, from?: ?string, to?: ?string}  $filters
     * @return LengthAwarePaginator<int, EmployeeWalletEntry>
     */
    public function entriesOf(int $userId, array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->where('user_id', $userId)
            ->with(['recorder', 'treasuryAccount', 'category', 'reversal', 'reversedEntry'])
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * «حركات محافظ الموظفين» — كل المحافظ في صفحة، الأحدث أولاً.
     *
     * @param  array{type?: ?string, from?: ?string, to?: ?string, user_id?: ?int, q?: ?string}  $filters
     * @return LengthAwarePaginator<int, EmployeeWalletEntry>
     */
    public function allEntries(array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->when($filters['user_id'] ?? null, fn ($q, $id) => $q->where('user_id', $id))
            ->when(trim((string) ($filters['q'] ?? '')), fn ($q, $term) => $q->whereHas('employee', fn ($e) => $e
                ->where(fn ($match) => $match
                    ->where('name', 'ilike', "%{$term}%")
                    ->orWhere('phone', 'ilike', "%{$term}%")
                    ->orWhere('employee_code', 'ilike', "%{$term}%"))))
            ->with(['employee', 'recorder', 'treasuryAccount', 'category', 'reversal', 'reversedEntry'])
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * @param  array{type?: ?string, from?: ?string, to?: ?string}  $filters
     * @return Builder<EmployeeWalletEntry>
     */
    private function filtered(array $filters): Builder
    {
        return EmployeeWalletEntry::query()
            ->when($filters['type'] ?? null, fn ($q, $type) => $type === EmployeeWalletEntryType::ADJUSTMENT_FILTER
                ? $q->whereIn('type', [
                    EmployeeWalletEntryType::AdjustmentCredit->value,
                    EmployeeWalletEntryType::AdjustmentDebit->value,
                ])
                : $q->where('type', $type))
            // أيامُ المحلّ بتوقيت طرابلس، لا أيامُ UTC.
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->where('occurred_at', '>=', BusinessDay::start($from)))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->where('occurred_at', '<=', BusinessDay::end($to)));
    }

    private function guardNotOwn(User $actor, int $userId): void
    {
        if (! $this->mayMove($actor, $userId)) {
            throw OwnWalletRefused::make();
        }
    }

    /**
     * يعلن الحركة بعد أن التزمت معاملتها. الإعادةُ بالرمز نفسه لا سطرَ جديداً فيها ولا خبر.
     */
    private function announced(EmployeeWalletEntry $entry, User $actor): EmployeeWalletEntry
    {
        if ($entry->wasRecentlyCreated) {
            EmployeeWalletMoved::dispatch(
                (int) $entry->getKey(),
                (int) $entry->user_id,
                $entry->type->value,
                $entry->isCredit(),
                (int) $actor->getKey(),
            );
        }

        return $entry;
    }
}
