<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\DTOs\TopUpData;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Exceptions\TopUpNeedsReceipt;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\Support\Money;
use App\Support\Media\StoreReceipt;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * «شحن المحفظة» at the counter — the customer hands over money and it waits in their wallet.
 *
 * **Two movements, one source.** The money goes `in` to the account it physically reached — the
 * resolver's answer, as for an order payment — and the debt that came with it goes `out` on
 * «أرصدة محافظ الزبائن». Both point at this row, so reversing it takes both back. CUSTOMER-WALLET §٤.
 *
 * **Hand money, hand rules**: no date inside the locked period nor before the account's last
 * count, the investor deposit's discipline. A deposit is never refused for balance — money arrived.
 */
final class TopUpWallet
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly StoreReceipt $storeReceipt,
    ) {}

    public function __invoke(int $customerId, TopUpData $data, ?int $actorId): CustomerWalletEntry
    {
        if (! Money::isPositive($data->amount)) {
            throw new InvalidArgumentException('A top-up moves a positive amount.');
        }

        if ($data->method->requiresReceipt() && $data->receipt === null) {
            throw TopUpNeedsReceipt::make($data->method);
        }

        return DB::transaction(function () use ($customerId, $data, $actorId): CustomerWalletEntry {
            $customer = Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

            $occurredAt = $data->occurredAt ?? now();

            $account = $this->treasury->accountFor($data->method->value, $actorId, $data->treasuryAccountId);
            $this->treasury->guardManualEntry($account, $occurredAt, 'occurred_at');

            $payable = $this->treasury->customerWalletsPayable();

            $entry = new CustomerWalletEntry([
                'amount' => $data->amount,
                'reference' => $data->reference,
                'occurred_at' => $occurredAt,
                'notes' => $data->notes,
            ]);

            $entry->customer_id = $customer->getKey();
            $entry->type = WalletEntryType::Topup;
            $entry->method = $data->method;
            $entry->treasury_account_id = $account->getKey();
            $entry->recorded_by = $actorId;

            if ($data->receipt !== null) {
                $entry->forceFill(($this->storeReceipt)("wallet-receipts/{$customer->getKey()}", $data->receipt));
            }

            $entry->save();

            $notes = "شحن محفظة — {$customer->name}";

            $this->treasury->post(new MovementData(
                accountId: (int) $account->getKey(),
                direction: MovementDirection::In,
                kind: MovementKind::WalletTopup,
                amount: (string) $entry->amount,
                occurredAt: $entry->occurred_at,
                sourceType: $entry->getMorphClass(),
                sourceId: (int) $entry->getKey(),
                notes: $notes,
                recordedBy: $actorId,
                counterpartAccountId: (int) $payable->getKey(),
            ));

            $this->treasury->post(new MovementData(
                accountId: (int) $payable->getKey(),
                direction: MovementDirection::Out,
                kind: MovementKind::WalletTopup,
                amount: (string) $entry->amount,
                occurredAt: $entry->occurred_at,
                sourceType: $entry->getMorphClass(),
                sourceId: (int) $entry->getKey(),
                notes: $notes,
                recordedBy: $actorId,
                counterpartAccountId: (int) $account->getKey(),
            ));

            return $entry;
        });
    }
}
