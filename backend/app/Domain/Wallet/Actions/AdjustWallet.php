<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Exceptions\WalletBalanceTooLow;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\Queries\WalletBalances;
use App\Domain\Wallet\Support\Money;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * «تعديل الرصيد» — a balance corrected by hand, with a reason, by somebody holding the grant.
 *
 * **No money moves**, so the only treasury effect is on «أرصدة محافظ الزبائن»: a credit is more
 * owed (`out`), a debit less (`in`). The payable keeps equalling minus every wallet. A debit may
 * not take the wallet below zero — a wallet never holds debt.
 */
final class AdjustWallet
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly WalletBalances $balances,
    ) {}

    public function __invoke(int $customerId, string $amount, bool $credit, string $reason, ?int $actorId): CustomerWalletEntry
    {
        if (! Money::isPositive($amount)) {
            throw new InvalidArgumentException('An adjustment moves a positive amount.');
        }

        return DB::transaction(function () use ($customerId, $amount, $credit, $reason, $actorId): CustomerWalletEntry {
            $customer = Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

            if (! $credit) {
                $balance = $this->balances->of((int) $customer->getKey());

                if (bccomp($amount, $balance, Money::SCALE) > 0) {
                    throw WalletBalanceTooLow::make($amount, $balance);
                }
            }

            $entry = new CustomerWalletEntry([
                'amount' => $amount,
                'occurred_at' => now(),
                'notes' => $reason,
            ]);

            $entry->customer_id = $customer->getKey();
            $entry->type = $credit ? WalletEntryType::AdjustmentCredit : WalletEntryType::AdjustmentDebit;
            $entry->recorded_by = $actorId;
            $entry->save();

            $this->treasury->post(new MovementData(
                accountId: (int) $this->treasury->customerWalletsPayable()->getKey(),
                direction: $credit ? MovementDirection::Out : MovementDirection::In,
                kind: MovementKind::WalletAdjustment,
                amount: (string) $entry->amount,
                occurredAt: $entry->occurred_at,
                sourceType: $entry->getMorphClass(),
                sourceId: (int) $entry->getKey(),
                notes: "{$entry->type->label()} — {$customer->name}: {$reason}",
                recordedBy: $actorId,
            ));

            return $entry;
        });
    }
}
