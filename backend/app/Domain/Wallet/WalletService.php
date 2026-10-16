<?php

declare(strict_types=1);

namespace App\Domain\Wallet;

use App\Domain\Customer\Models\Customer;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Actions\AdjustWallet;
use App\Domain\Wallet\Actions\ReverseWalletEntry;
use App\Domain\Wallet\Actions\TopUpWallet;
use App\Domain\Wallet\DTOs\TopUpData;
use App\Domain\Wallet\Enums\TopUpMethod;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Exceptions\WalletBalanceTooLow;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\Queries\WalletBalances;
use App\Domain\Wallet\Support\BusinessDay;
use App\Domain\Wallet\Support\Money;
use DateTimeInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * The door to «محفظة الزبون» — Docs/payments/CUSTOMER-WALLET.md.
 *
 * **Two kinds of caller.** The wallet screens (staff and the customer's app), through the
 * controllers; and the order context, which asks {@see guardCanPay()} before it takes a payment
 * from the wallet and tells this service about the payment, a refund into the wallet, or the
 * reversal of a payment, all inside its own transaction with the order locked first. The wallet
 * never imports the order context back: it knows an order as two ids.
 *
 * **Lock order: the order, then the customer.** Every path here that is called from an order
 * runs after the order context took its lock, so the two can never wait on each other in reverse.
 */
final class WalletService
{
    public function __construct(
        private readonly WalletBalances $balances,
        private readonly TopUpWallet $topUp,
        private readonly AdjustWallet $adjust,
        private readonly ReverseWalletEntry $reverse,
        private readonly TreasuryService $treasury,
    ) {}

    public function balanceOf(int $customerId): string
    {
        return $this->balances->of($customerId);
    }

    /**
     * @param  list<int>  $customerIds
     * @return array<int, string>
     */
    public function balancesOf(array $customerIds): array
    {
        return $this->balances->forCustomers($customerIds);
    }

    // ── the counter ─────────────────────────────────────────────────────────────────────

    public function topUp(int $customerId, TopUpData $data, ?int $actorId): CustomerWalletEntry
    {
        return ($this->topUp)($customerId, $data, $actorId);
    }

    public function adjust(int $customerId, string $amount, bool $credit, string $reason, ?int $actorId): CustomerWalletEntry
    {
        return ($this->adjust)($customerId, $amount, $credit, $reason, $actorId);
    }

    public function reverse(CustomerWalletEntry $entry, string $reason, ?int $actorId): CustomerWalletEntry
    {
        return ($this->reverse)($entry, $reason, $actorId);
    }

    // ── for the order context ───────────────────────────────────────────────────────────

    /**
     * Locks the customer and refuses an amount the wallet does not hold. Returns the balance.
     * Call inside the transaction that will write the payment, after the order is locked.
     */
    public function guardCanPay(int $customerId, string $amount, string $field = 'amount'): string
    {
        $balance = $this->lockedBalanceOf($customerId);

        if (! Money::isPositive($amount) || bccomp($amount, $balance, Money::SCALE) > 0) {
            throw WalletBalanceTooLow::make($amount, $balance, $field);
        }

        return $balance;
    }

    /**
     * Locks the customer and reads the balance — for a caller that decides the amount from it.
     * Call inside the transaction, after the order is locked.
     */
    public function lockedBalanceOf(int $customerId): string
    {
        Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

        return $this->balances->of($customerId);
    }

    /**
     * The wallet's row for a payment taken out of it. Call after {@see guardCanPay()}.
     *
     * @param  ?string  $clientToken  the app's key for this request — a retry carrying it is
     *                                answered by {@see sentPayment()} instead of paying twice
     */
    public function recordOrderPayment(
        int $customerId,
        int $orderId,
        int $orderPaymentId,
        string $amount,
        DateTimeInterface $occurredAt,
        ?int $actorId,
        ?string $notes = null,
        ?string $clientToken = null,
    ): CustomerWalletEntry {
        return $this->writeOrderEntry(
            WalletEntryType::OrderPayment,
            $customerId,
            $orderId,
            $orderPaymentId,
            $amount,
            $occurredAt,
            $actorId,
            $notes,
            $clientToken,
        );
    }

    /**
     * The payment from this wallet a request already made, found by the app's key — `[order id,
     * order payment id]` — or null when the key is new. Ask it before paying and again under the
     * lock: two copies of one request racing each other meet here, and the unique index under it
     * is the last guard, not the usual path.
     *
     * @return ?array{0: int, 1: int}
     */
    public function sentPayment(int $customerId, ?string $clientToken): ?array
    {
        if ($clientToken === null) {
            return null;
        }

        $entry = CustomerWalletEntry::query()
            ->where('customer_id', $customerId)
            ->where('client_token', $clientToken)
            ->where('type', WalletEntryType::OrderPayment->value)
            ->first();

        return $entry === null ? null : [(int) $entry->order_id, (int) $entry->order_payment_id];
    }

    /** The wallet's row for money handed back into it on an order. */
    public function recordOrderRefund(
        int $customerId,
        int $orderId,
        int $orderPaymentId,
        string $amount,
        DateTimeInterface $occurredAt,
        ?int $actorId,
        ?string $notes = null,
    ): CustomerWalletEntry {
        Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

        return $this->writeOrderEntry(WalletEntryType::OrderRefund, $customerId, $orderId, $orderPaymentId, $amount, $occurredAt, $actorId, $notes);
    }

    /**
     * A top-up the payment provider confirmed. CUSTOMER-WALLET §٥.
     *
     * The wallet receives `net`, exactly what the customer was quoted. The provider's account
     * receives `gross` — what it charged — and what it kept leaves it at once as an expense, so its
     * balance is what it will pay out. «أرصدة محافظ الزبائن» owes `net` more. Locks the customer;
     * call inside the transaction that marks the attempt settled.
     */
    public function creditOnlineTopUp(
        int $customerId,
        string $net,
        string $gross,
        string $fee,
        int $providerAccountId,
        string $reference,
        DateTimeInterface $occurredAt,
    ): CustomerWalletEntry {
        $customer = Customer::query()->whereKey($customerId)->lockForUpdate()->firstOrFail();

        $entry = new CustomerWalletEntry([
            'amount' => $net,
            'reference' => $reference,
            'occurred_at' => $occurredAt,
            'notes' => null,
        ]);

        $entry->customer_id = $customerId;
        $entry->type = WalletEntryType::Topup;
        $entry->method = TopUpMethod::Online;
        $entry->treasury_account_id = $providerAccountId;
        $entry->save();

        $payable = $this->treasury->customerWalletsPayable();
        $notes = "شحن إلكتروني — {$customer->name}";

        $this->treasury->post(new MovementData(
            accountId: $providerAccountId,
            direction: MovementDirection::In,
            kind: MovementKind::WalletTopup,
            amount: $gross,
            occurredAt: $occurredAt,
            sourceType: $entry->getMorphClass(),
            sourceId: (int) $entry->getKey(),
            notes: $notes,
            counterpartAccountId: (int) $payable->getKey(),
        ));

        $this->treasury->post(new MovementData(
            accountId: (int) $payable->getKey(),
            direction: MovementDirection::Out,
            kind: MovementKind::WalletTopup,
            amount: $net,
            occurredAt: $occurredAt,
            sourceType: $entry->getMorphClass(),
            sourceId: (int) $entry->getKey(),
            notes: $notes,
            counterpartAccountId: $providerAccountId,
        ));

        if (Money::isPositive($fee)) {
            $this->treasury->recordGatewayFee($providerAccountId, $fee, $occurredAt, "عمولة شحن إلكتروني {$reference}");
        }

        return $entry;
    }

    /** The money of a reversed payment from the wallet comes back. Null: it never touched one. */
    public function undoOrderPayment(int $orderPaymentId, string $reason, ?int $actorId): ?CustomerWalletEntry
    {
        return $this->reverse->forOrderPayment($orderPaymentId, $reason, $actorId);
    }

    // ── reading ─────────────────────────────────────────────────────────────────────────

    /**
     * One wallet's rows, newest first.
     *
     * @param  array{type?: ?string, from?: ?string, to?: ?string}  $filters
     * @return LengthAwarePaginator<int, CustomerWalletEntry>
     */
    public function entriesOf(int $customerId, array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->where('customer_id', $customerId)
            ->with(['recorder', 'treasuryAccount', 'reversal', 'reversedEntry'])
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * «المعاملات المالية» — every wallet's rows on one page, newest first.
     *
     * @param  array{type?: ?string, from?: ?string, to?: ?string, customer_id?: ?int, q?: ?string}  $filters
     * @return LengthAwarePaginator<int, CustomerWalletEntry>
     */
    public function allEntries(array $filters, int $perPage): LengthAwarePaginator
    {
        return $this->filtered($filters)
            ->when($filters['customer_id'] ?? null, fn ($q, $id) => $q->where('customer_id', $id))
            ->when(trim((string) ($filters['q'] ?? '')), fn ($q, $term) => $q->whereHas('customer', fn ($c) => $c
                ->where(fn ($match) => $match
                    ->where('name', 'ilike', "%{$term}%")
                    ->orWhere('phone', 'ilike', "%{$term}%")
                    ->orWhere('code', 'ilike', "%{$term}%"))))
            ->with(['customer', 'recorder', 'treasuryAccount', 'reversal', 'reversedEntry'])
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * @param  array{type?: ?string, from?: ?string, to?: ?string}  $filters
     * @return Builder<CustomerWalletEntry>
     */
    private function filtered(array $filters): Builder
    {
        return CustomerWalletEntry::query()
            ->when($filters['type'] ?? null, fn ($q, $type) => $q->where('type', $type))
            // أيامُ المحلّ بتوقيت طرابلس، لا أيامُ UTC.
            ->when($filters['from'] ?? null, fn ($q, $from) => $q->where('occurred_at', '>=', BusinessDay::start($from)))
            ->when($filters['to'] ?? null, fn ($q, $to) => $q->where('occurred_at', '<=', BusinessDay::end($to)));
    }

    private function writeOrderEntry(
        WalletEntryType $type,
        int $customerId,
        int $orderId,
        int $orderPaymentId,
        string $amount,
        DateTimeInterface $occurredAt,
        ?int $actorId,
        ?string $notes,
        ?string $clientToken = null,
    ): CustomerWalletEntry {
        $entry = new CustomerWalletEntry([
            'amount' => $amount,
            'occurred_at' => $occurredAt,
            'notes' => $notes,
        ]);

        $entry->customer_id = $customerId;
        $entry->type = $type;
        $entry->order_id = $orderId;
        $entry->order_payment_id = $orderPaymentId;
        $entry->recorded_by = $actorId;
        // Stamped, never fillable: the key is the request's, decided at the boundary.
        $entry->client_token = $clientToken;
        $entry->save();

        return $entry;
    }
}
