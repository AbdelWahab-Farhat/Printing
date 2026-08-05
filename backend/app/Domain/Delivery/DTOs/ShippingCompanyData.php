<?php

declare(strict_types=1);

namespace App\Domain\Delivery\DTOs;

final readonly class ShippingCompanyData
{
    public function __construct(
        public string $name,
        public ?string $phone = null,
        public ?string $notes = null,
        /** Nobody adds a carrier they are not about to use, so a new one starts in use. */
        public bool $isActive = true,
    ) {}

    /**
     * Built from already-validated request data — the one place an array is allowed to cross
     * into the domain.
     *
     * `store` and `update` both send the whole record, so a field left out clears it.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            name: trim((string) $validated['name']),
            phone: self::textOrNull($validated['phone'] ?? null),
            notes: self::textOrNull($validated['notes'] ?? null),
            // Absent means true, which is only right because the flag has one honest default:
            // a company nobody switched off is one we deal with.
            isActive: (bool) ($validated['is_active'] ?? true),
        );
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
