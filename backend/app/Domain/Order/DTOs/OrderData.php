<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Enums\DesignSource;

/**
 * Everything a request may say about an order.
 *
 * Money that a client could invent is absent: `items_total` and `grand_total` are derived from
 * the lines, and `delivery_price` is copied from the destination city. What remains — the design
 * fee and the discount — are decisions a person makes, and each is guarded: the fee only counts
 * when we did the design, and the discount needs its own permission.
 *
 * `customerId` is read on create and ignored on update: an order belongs to whoever placed it,
 * and moving one between customers would rewrite two histories to fix one typo. Cancel and
 * re-take it instead.
 */
final readonly class OrderData
{
    /**
     * @param  list<OrderItemData>|null  $items  null means "not supplied" — on update the
     *                                           existing lines are left untouched.
     */
    public function __construct(
        public int $customerId,
        public int $cityId,
        public ?int $customerShopId = null,
        public ?int $regionId = null,
        public DesignSource $designSource = DesignSource::None,
        public ?string $recipientName = null,
        public ?string $recipientPhone = null,
        public ?string $addressDetails = null,
        public ?string $notes = null,
        public string $designFee = '0.00',
        public string $discount = '0.00',
        public ?string $shippingCompany = null,
        public ?string $trackingNumber = null,
        public ?string $courierName = null,
        public ?array $items = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            customerId: (int) ($validated['customer_id'] ?? 0),
            cityId: (int) $validated['city_id'],
            customerShopId: isset($validated['customer_shop_id'])
                ? (int) $validated['customer_shop_id']
                : null,
            regionId: isset($validated['region_id']) ? (int) $validated['region_id'] : null,
            designSource: isset($validated['design_source'])
                ? DesignSource::from((string) $validated['design_source'])
                : DesignSource::None,
            recipientName: self::textOrNull($validated['recipient_name'] ?? null),
            recipientPhone: self::textOrNull($validated['recipient_phone'] ?? null),
            addressDetails: self::textOrNull($validated['address_details'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
            // Through string, never float: these are added to a total that must stay exact.
            designFee: self::money($validated['design_fee'] ?? null),
            discount: self::money($validated['discount'] ?? null),
            shippingCompany: self::textOrNull($validated['shipping_company'] ?? null),
            trackingNumber: self::textOrNull($validated['tracking_number'] ?? null),
            courierName: self::textOrNull($validated['courier_name'] ?? null),
            items: array_key_exists('items', $validated) && is_array($validated['items'])
                ? array_values(array_map(
                    fn (array $item, int $index) => OrderItemData::fromArray($item, $index),
                    $validated['items'],
                    array_keys($validated['items']),
                ))
                : null,
        );
    }

    private static function money(mixed $value): string
    {
        if ($value === null || $value === '') {
            return '0.00';
        }

        return number_format((float) $value, 2, '.', '');
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
