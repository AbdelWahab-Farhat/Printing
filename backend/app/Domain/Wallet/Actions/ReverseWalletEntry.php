<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Actions;

use App\Domain\Customer\Models\Customer;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Enums\TopUpMethod;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Exceptions\WalletEntryCannotBeReversed;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\Queries\WalletBalances;
use App\Domain\Wallet\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * Undoing a top-up or an adjustment that should never have been written.
 *
 * The wrong row stays; a `reversal` beside it carries the same amount and points back, and the
 * treasury mirrors every movement the original posted. **Refused when the money is already
 * spent**: undoing a 100 top-up from a wallet holding 30 would leave it at −70, and a wallet never
 * holds debt — the order it paid is reversed first, which returns the money.
 *
 * A payment from the wallet and a refund into it are the order's rows, and are undone on the
 * order's ledger — see {@see self::forOrderPayment()}.
 */
final class ReverseWalletEntry
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly WalletBalances $balances,
    ) {}

    public function __invoke(CustomerWalletEntry $entry, string $reason, ?int $actorId): CustomerWalletEntry
    {
        if (! $entry->type->isReversibleByHand()) {
            throw WalletEntryCannotBeReversed::notByHand($entry->type->label());
        }

        // Money EzonePay confirmed it took: undoing it by hand would leave «Ezone» short of what
        // EzonePay will pay out. A refund to the customer goes through EzonePay, not this.
        if ($entry->method === TopUpMethod::Online) {
            throw WalletEntryCannotBeReversed::online();
        }

        return DB::transaction(function () use ($entry, $reason, $actorId): CustomerWalletEntry {
            $reversal = $this->reverse($entry, $reason, $actorId);

            $this->treasury->reverseSource($entry->getMorphClass(), (int) $entry->getKey(), $reason, $actorId);

            return $reversal;
        });
    }

    /**
     * The wallet's half of reversing a payment from it: the money comes back. Called by the order
     * context inside its own transaction, with the order already locked. Null when the payment
     * never touched a wallet. The treasury half is the order payment's own movement, mirrored there.
     */
    public function forOrderPayment(int $orderPaymentId, string $reason, ?int $actorId): ?CustomerWalletEntry
    {
        $entry = CustomerWalletEntry::query()
            ->where('order_payment_id', $orderPaymentId)
            ->where('type', WalletEntryType::OrderPayment->value)
            ->first();

        return $entry === null ? null : $this->reverse($entry, $reason, $actorId);
    }

    /** Locks the customer, refuses what may not be undone, and writes the reversal row. */
    private function reverse(CustomerWalletEntry $entry, string $reason, ?int $actorId): CustomerWalletEntry
    {
        $customer = Customer::query()->whereKey($entry->customer_id)->lockForUpdate()->firstOrFail();

        // Under the lock, and backed by a partial unique index underneath it.
        if ($entry->isReversed()) {
            throw WalletEntryCannotBeReversed::alreadyReversed();
        }

        if ($entry->type->isCredit()) {
            $balance = $this->balances->of((int) $customer->getKey());

            if (bccomp((string) $entry->amount, $balance, Money::SCALE) > 0) {
                throw WalletEntryCannotBeReversed::alreadySpent((string) $entry->amount, $balance);
            }
        }

        $reversal = new CustomerWalletEntry([
            'amount' => (string) $entry->amount,
            'reference' => $entry->reference,
            // When the mistake was caught — the original's own moment is on the row it points at.
            'occurred_at' => now(),
            'notes' => $reason,
        ]);

        $reversal->customer_id = $entry->customer_id;
        $reversal->type = WalletEntryType::Reversal;
        $reversal->order_id = $entry->order_id;
        $reversal->reverses_entry_id = $entry->getKey();
        $reversal->recorded_by = $actorId;
        $reversal->save();

        return $reversal;
    }
}
