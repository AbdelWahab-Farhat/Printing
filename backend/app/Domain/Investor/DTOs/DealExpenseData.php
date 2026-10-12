<?php

declare(strict_types=1);

namespace App\Domain\Investor\DTOs;

use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Support\Money;

/** A cost booked against a deal. `is_landed` is absent on purpose — the server decides it. */
final readonly class DealExpenseData
{
    public function __construct(
        public DealExpenseKind $kind,
        public string $name,
        public string $amount,
        public string $incurredOn,
        public ?string $notes = null,
        // The drawer it was paid from; null lets the treasury take it from the cash box.
        public ?int $treasuryAccountId = null,
        // The document that charged it — a purchase order's arrival cost on a funded line. Never
        // from a request: a person's expense names nothing, and is reversed by hand.
        public ?string $sourceType = null,
        public ?int $sourceId = null,
        // **The purchase order whose goods carry it** — the fund's alone
        // (Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md). Set, the expense is spread over every
        // unit that order brought in instead of being charged to the period of its date.
        public ?int $purchaseOrderId = null,
    ) {}

    /** The same expense with no purchase order — what an old deal takes, since it has no periods. */
    public function withoutPurchaseOrder(): self
    {
        return new self(
            kind: $this->kind,
            name: $this->name,
            amount: $this->amount,
            incurredOn: $this->incurredOn,
            notes: $this->notes,
            treasuryAccountId: $this->treasuryAccountId,
            sourceType: $this->sourceType,
            sourceId: $this->sourceId,
        );
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            kind: DealExpenseKind::from((string) $validated['kind']),
            name: trim((string) $validated['name']),
            amount: Money::normalize($validated['amount']),
            incurredOn: (string) $validated['incurred_on'],
            notes: isset($validated['notes']) && trim((string) $validated['notes']) !== ''
                ? trim((string) $validated['notes'])
                : null,
            treasuryAccountId: isset($validated['treasury_account_id']) && $validated['treasury_account_id'] !== ''
                ? (int) $validated['treasury_account_id']
                : null,
        );
    }
}
