<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

final readonly class PurchaseOrderAdditionalCostData
{
    public function __construct(
        public string $name,
        /** Always non-negative, normalised to two decimal places — money, never a float. */
        public string $amount,
        /** Present when updating an existing cost; null when creating a new one. */
        public ?int $id = null,
        /**
         * Who was paid: null is the vendor's bill; a drawer it was paid from, or a manual
         * payable it is owed to — see `PurchaseOrderAdditionalCost`.
         */
        public ?int $treasuryAccountId = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated  One entry from the request's `additional_costs` array.
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            name: trim((string) $validated['name']),
            amount: number_format((float) $validated['amount'], 2, '.', ''),
            id: isset($validated['id']) ? (int) $validated['id'] : null,
            treasuryAccountId: isset($validated['treasury_account_id']) && $validated['treasury_account_id'] !== ''
                ? (int) $validated['treasury_account_id']
                : null,
        );
    }
}
