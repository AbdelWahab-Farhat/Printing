<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Delivery\Enums\FulfilmentType;

/**
 * A resolved, validated destination together with the facts an order copies from it.
 *
 * The names and the price travel with the ids because an order snapshots them: renaming a city
 * or renegotiating its rate must not rewrite what an order said on the day it was taken.
 */
final readonly class OrderDestination
{
    public function __construct(
        public int $cityId,
        public ?int $regionId,
        public string $cityName,
        public ?string $regionName,
        public FulfilmentType $fulfilmentType,
        public string $deliveryPrice,
    ) {}

    /**
     * The `orders` columns this destination writes, for `forceFill()` — `delivery_price` is not
     * fillable. One list, so the edit form and the move into «إعادة إرسال» cannot write
     * different halves of an address.
     *
     * @return array<string, mixed>
     */
    public function columns(): array
    {
        return [
            'city_id' => $this->cityId,
            'region_id' => $this->regionId,
            'city_name' => $this->cityName,
            'region_name' => $this->regionName,
            'fulfilment_type' => $this->fulfilmentType,
            'delivery_price' => $this->deliveryPrice,
        ];
    }
}
