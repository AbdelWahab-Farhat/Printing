<?php

declare(strict_types=1);

namespace App\Domain\Delivery\DTOs;

final readonly class CityData
{
    public function __construct(
        public string $name,
        public bool $isRegionRequired = false,
        /** null means "no rate agreed yet" — never "free". Free is the string '0.00'. */
        public ?string $deliveryPrice = null,
        public ?string $darbBranch = null,
        public ?float $latitude = null,
        public ?float $longitude = null,
    ) {}

    /**
     * Built from already-validated request data — the one place an array is allowed to cross
     * into the domain.
     *
     * `store` and `update` both send the city's whole representation, so a field left out is an
     * instruction to clear it rather than to keep whatever is there.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $price = $validated['delivery_price'] ?? null;

        return new self(
            name: trim((string) $validated['name']),
            isRegionRequired: (bool) ($validated['is_region_required'] ?? false),
            // Cast through string, never float: the column is decimal and money that is summed
            // must not pick up binary drift on the way in.
            deliveryPrice: $price !== null && $price !== '' ? number_format((float) $price, 2, '.', '') : null,
            darbBranch: self::textOrNull($validated['darb_branch'] ?? null),
            latitude: isset($validated['latitude']) ? (float) $validated['latitude'] : null,
            longitude: isset($validated['longitude']) ? (float) $validated['longitude'] : null,
        );
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
