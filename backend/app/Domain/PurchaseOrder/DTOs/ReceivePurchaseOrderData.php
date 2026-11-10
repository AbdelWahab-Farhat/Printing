<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\DTOs;

use App\Domain\PurchaseOrder\Actions\ReceivePurchaseOrder;
use App\Domain\Treasury\Support\ExchangeRate;

final readonly class ReceivePurchaseOrderData
{
    /**
     * @param  list<ReceivePurchaseOrderItemData>  $items
     */
    public function __construct(
        /** Stamped from the authenticated user, never read from the payload. */
        public int $receivedBy,
        public array $items,
        public ?string $invoiceNumber = null,
        public ?string $notes = null,
        /**
         * What was paid on the lorry's arrival — delivery, porters, customs. Spread over what
         * this receipt brought ({@see ReceivePurchaseOrder}).
         *
         * @var list<PurchaseOrderAdditionalCostData>
         */
        public array $additionalCosts = [],
        /**
         * Dinars per dollar on a dollar order — what its stock is priced at (USD-ACCOUNTS.md §٥).
         * Required there, ignored on a dinar order.
         */
        public ?string $arrivalRate = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated, int $receivedBy): self
    {
        return new self(
            receivedBy: $receivedBy,
            items: array_map(ReceivePurchaseOrderItemData::fromArray(...), $validated['items']),
            invoiceNumber: self::textOrNull($validated['invoice_number'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
            additionalCosts: array_map(
                PurchaseOrderAdditionalCostData::fromArray(...),
                array_values($validated['additional_costs'] ?? []),
            ),
            arrivalRate: isset($validated['arrival_rate']) && $validated['arrival_rate'] !== ''
                ? ExchangeRate::normalize((string) $validated['arrival_rate'])
                : null,
        );
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
