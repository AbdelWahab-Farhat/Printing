<?php

declare(strict_types=1);

namespace App\Domain\Catalog\DTOs;

final readonly class ProductCategoryData
{
    public function __construct(
        public string $name,
        /** The line the catalogue prints under the heading. Null until somebody writes one. */
        public ?string $description = null,
        /** A category is offered the moment it is created; hiding one is a later, deliberate act. */
        public bool $isActive = true,
        /** Where it sits in the catalogue. Equal values fall back to the name. */
        public int $sortOrder = 0,
    ) {}

    /**
     * Built from already-validated request data — the one place an array crosses into the domain.
     *
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        // Trimmed here rather than at the boundary: a name with a trailing space is a second
        // «أكياس» as far as the unique index is concerned, and nobody would see why.
        $description = trim((string) ($validated['description'] ?? ''));

        return new self(
            name: trim((string) $validated['name']),
            description: $description !== '' ? $description : null,
            isActive: (bool) ($validated['is_active'] ?? true),
            sortOrder: (int) ($validated['sort_order'] ?? 0),
        );
    }
}
