<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

/**
 * One instant sale as the counter typed it: who, where, and what (INSTANT-ORDERS-PLAN.md §3).
 *
 * The customer arrives as typed — phone, name, city, region — not as an id: the counter employee
 * does not pick a customer from a list, the phone finds one or a new one is made.
 */
final readonly class InstantOrderData
{
    /**
     * @param  list<OrderItemData>  $items
     */
    public function __construct(
        public int $branchId,
        public string $customerPhone,
        public string $customerName,
        // Optional: the address only fills the customer's record (owner's decision, 2026-11-27).
        public ?int $customerCityId,
        public ?int $customerRegionId,
        public array $items,
        public string $discount = '0.00',
        public ?string $notes = null,
        public ?string $clientToken = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $customer = (array) $validated['customer'];

        return new self(
            branchId: (int) $validated['branch_id'],
            customerPhone: (string) $customer['phone'],
            customerName: trim((string) $customer['name']),
            customerCityId: isset($customer['city_id']) ? (int) $customer['city_id'] : null,
            // Never without its city.
            customerRegionId: isset($customer['city_id'], $customer['region_id']) ? (int) $customer['region_id'] : null,
            items: self::items($validated['items'] ?? []),
            discount: number_format((float) ($validated['discount'] ?? 0), 2, '.', ''),
            notes: self::textOrNull($validated['notes'] ?? null),
            clientToken: self::textOrNull($validated['client_token'] ?? null),
        );
    }

    /**
     * The lines, priced from the product: a unit price is never read from the request.
     *
     * @return list<OrderItemData>
     */
    public static function items(mixed $items): array
    {
        if (! is_array($items)) {
            return [];
        }

        return array_values(array_map(
            fn (array $item, int $index) => new OrderItemData(
                productId: (int) $item['product_id'],
                productVariantId: (int) $item['product_variant_id'],
                quantity: (string) $item['quantity'],
                notes: self::textOrNull($item['notes'] ?? null),
                sortOrder: $index,
                // Only an edit sends it: the line it keeps. A line without one is new.
                id: isset($item['id']) ? (int) $item['id'] : null,
            ),
            array_values($items),
            array_keys(array_values($items)),
        ));
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
