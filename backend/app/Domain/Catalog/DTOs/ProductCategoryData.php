<?php

declare(strict_types=1);

namespace App\Domain\Catalog\DTOs;

final readonly class ProductCategoryData
{
    public function __construct(
        public string $name,
        /**
         * The heading this one sits under, or null when it is one in its own right.
         *
         * Only a root may be named here — the one-level rule lives in the request, where it can
         * be explained rather than merely enforced.
         */
        public ?int $parentId = null,
        /** The line the catalogue prints under the heading. Null until somebody writes one. */
        public ?string $description = null,
        /** A category is offered the moment it is created; hiding one is a later, deliberate act. */
        public bool $isActive = true,
        /** Where it sits in the catalogue. Equal values fall back to the name. */
        public int $sortOrder = 0,
        /**
         * Whether goods under this heading skip the designer and the press — see
         * `ProductCategory::skipsProduction()`.
         *
         * Defaults to false, and that is the safe direction: a heading nobody has thought about
         * yet sends its orders down the road every order took before this existed.
         */
        public bool $skipsProduction = false,
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
            // `?? null` rather than `array_key_exists`: both store and update send the whole
            // representation, so an absent parent is «اجعله رئيسياً», not «اترك ما كان».
            parentId: isset($validated['parent_id']) ? (int) $validated['parent_id'] : null,
            description: $description !== '' ? $description : null,
            isActive: (bool) ($validated['is_active'] ?? true),
            sortOrder: (int) ($validated['sort_order'] ?? 0),
            skipsProduction: (bool) ($validated['skips_production'] ?? false),
        );
    }
}
