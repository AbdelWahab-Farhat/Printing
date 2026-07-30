<?php

declare(strict_types=1);

namespace App\Domain\Customer\Queries;

final readonly class CustomerFilters
{
    public function __construct(
        /** Matches against name, code, or phone. */
        public ?string $search = null,
        /** null = both active and inactive. */
        public ?bool $isActive = null,
    ) {}

    /**
     * @param  array<string, mixed>  $query  Validated query-string values.
     */
    public static function fromArray(array $query): self
    {
        $search = isset($query['search']) ? trim((string) $query['search']) : '';

        return new self(
            search: $search !== '' ? $search : null,
            isActive: array_key_exists('is_active', $query) && $query['is_active'] !== null
                ? filter_var($query['is_active'], FILTER_VALIDATE_BOOLEAN)
                : null,
        );
    }
}
