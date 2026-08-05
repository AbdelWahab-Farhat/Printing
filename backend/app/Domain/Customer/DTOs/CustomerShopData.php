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
        /**
         * مجال العمل — which trade this shop is in, or null for one recorded without it.
         *
         * Null is a real answer, not a missing one: every shop recorded before this field
         * existed has none, and «لم يُحدَّد» is also the honest state for a shop entered in a
         * hurry. Both `store` and `update` send the whole shop, so omitting it clears it.
         */
        public ?int $businessFieldId = null,
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
            businessFieldId: isset($shop['business_field_id']) && $shop['business_field_id'] !== ''
                ? (int) $shop['business_field_id']
                : null,
            id: isset($shop['id']) ? (int) $shop['id'] : null,
        );
    }
}
