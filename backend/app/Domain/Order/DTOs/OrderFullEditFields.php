<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use Illuminate\Support\Carbon;

/**
 * The fields only `orders.edit_fully` writes: the ones nothing else edits once they are set.
 *
 * **Each one moves only when the request mentioned it.** The app sends them only to a reader
 * holding the grant, so a key that never arrived has to leave the column standing. That is why
 * this holds the keys that were sent rather than a value for every field.
 *
 * `delivery_cost` is written to `delivery_cost_override`, never to `delivery_cost` itself; a
 * null there hands the figure back to RecalculateDeliveryCost. See that migration.
 */
final readonly class OrderFullEditFields
{
    /** @var list<string> */
    public const KEYS = [
        'delivery_price',
        'delivery_cost',
        'shipping_company_id',
        'courier_name',
        'courier_phone',
        'deposit_expected_amount',
        'placed_at',
    ];

    /**
     * @param  array<string, mixed>  $values  only the keys the request sent
     */
    private function __construct(private array $values) {}

    /**
     * Null when the request sent none of them, which is every request from a reader without
     * the grant.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): ?self
    {
        $values = array_intersect_key($validated, array_flip(self::KEYS));

        return $values === [] ? null : new self($values);
    }

    public function has(string $key): bool
    {
        return array_key_exists($key, $this->values);
    }

    public function deliveryPrice(): string
    {
        return self::money($this->values['delivery_price']) ?? '0.00';
    }

    /** Null clears the override, so the cost is derived again. */
    public function deliveryCost(): ?string
    {
        return self::money($this->values['delivery_cost']);
    }

    public function shippingCompanyId(): ?int
    {
        $id = $this->values['shipping_company_id'];

        return $id === null ? null : (int) $id;
    }

    public function courierName(): ?string
    {
        return self::text($this->values['courier_name']);
    }

    public function courierPhone(): ?string
    {
        return self::text($this->values['courier_phone']);
    }

    public function depositExpectedAmount(): ?string
    {
        return self::money($this->values['deposit_expected_amount']);
    }

    public function placedAt(): Carbon
    {
        return Carbon::parse((string) $this->values['placed_at']);
    }

    private static function money(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return number_format((float) $value, 2, '.', '');
    }

    private static function text(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text === '' ? null : $text;
    }
}
