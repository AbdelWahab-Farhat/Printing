<?php

declare(strict_types=1);

namespace App\Domain\Customer\DTOs;

final readonly class CustomerShopData
{
    public function __construct(
        public string $name,
        /** Degrees, -90 to 90. */
        public float $latitude,
        /** Degrees, -180 to 180. */
        public float $longitude,
        public ?string $pageUrl = null,
        /** Present when updating an existing shop; null when creating a new one. */
        public ?int $id = null,
    ) {}

    /**
     * @param  array<string, mixed>  $shop  One validated entry from the request's `shops` array.
     */
    public static function fromArray(array $shop): self
    {
        return new self(
            name: (string) $shop['name'],
            latitude: (float) $shop['latitude'],
            longitude: (float) $shop['longitude'],
            pageUrl: isset($shop['page_url']) && $shop['page_url'] !== '' ? (string) $shop['page_url'] : null,
            id: isset($shop['id']) ? (int) $shop['id'] : null,
        );
    }
}
