<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Actions;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletEntryCannotBeReversed;
use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Queries\EmployeeWalletBalances;
use App\Domain\EmployeeWallet\Support\Money;
use App\Domain\Identity\AccessService;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * إلغاءُ سطرٍ ما كان ينبغي أن يُكتب.
 *
 * السطرُ الخاطئ يبقى، وبجانبه `reversal` بالمبلغ نفسه يشير إليه، والخزينةُ تعكس ما كتبه: حركتَي
 * الإيداع والسحب من مصدرهما، وعمليةَ المستحق من بابها. **ويُرفض حين خرج المال**: عكسُ إيداع ١٠٠ من
 * محفظةٍ فيها ٣٠ يتركها عند −٧٠، والمحفظة لا تحمل دَيناً — يُعكس السحبُ أولاً فيعود المال.
 */
final class ReverseEmployeeWalletEntry
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly AccessService $access,
        private readonly EmployeeWalletBalances $balances,
    ) {}

    public function __invoke(EmployeeWalletEntry $entry, string $reason, ?int $actorId): EmployeeWalletEntry
    {
        if (! $entry->type->isReversibleByHand()) {
            throw EmployeeWalletEntryCannotBeReversed::isAReversal();
        }

        return DB::transaction(function () use ($entry, $reason, $actorId): EmployeeWalletEntry {
            $employee = $this->access->lockEmployee((int) $entry->user_id);

            // تحت القفل، وفوقه فهرسٌ فريدٌ جزئي.
            if ($entry->isReversed()) {
                throw EmployeeWalletEntryCannotBeReversed::alreadyReversed();
            }

            if ($entry->type->isCredit()) {
                $balance = $this->balances->of((int) $employee->getKey());

                if (bccomp((string) $entry->amount, $balance, Money::SCALE) > 0) {
                    throw EmployeeWalletEntryCannotBeReversed::alreadySpent((string) $entry->amount, $balance);
                }
            }

            $reversal = new EmployeeWalletEntry([
                'amount' => (string) $entry->amount,
                'reference' => $entry->reference,
                // متى كُشف الخطأ — لحظةُ الأصل على السطر الذي يشير إليه.
                'occurred_at' => now(),
                'notes' => $reason,
            ]);

            $reversal->user_id = $entry->user_id;
            $reversal->type = EmployeeWalletEntryType::Reversal;
            $reversal->reverses_entry_id = $entry->getKey();
            $reversal->recorded_by = $actorId;
            $reversal->save();

            if ($entry->treasury_operation_id !== null) {
                $this->treasury->reverseWalletExpense((int) $entry->treasury_operation_id, $reason, $actorId);
            } else {
                $this->treasury->reverseSource($entry->getMorphClass(), (int) $entry->getKey(), $reason, $actorId);
            }

            return $reversal;
        });
    }
}
