<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Enums\OrderStatus;

final readonly class OrderFilters
{
    /**
     * @param  list<OrderStatus>|null  $statuses  more than one, because the work queues staff
     *                                            actually want are groups: "everything still in
     *                                            production", "everything that came back".
     */
    public function __construct(
        /** Matches the order number, the customer's name or their phone. */
        public ?string $search = null,
        public ?array $statuses = null,
        public ?int $customerId = null,
        public ?int $cityId = null,
        public ?string $from = null,
        public ?string $to = null,
    ) {}

    /**
     * @param  array<string, mixed>  $query
     */
    public static function fromArray(array $query): self
    {
        $search = trim((string) ($query['search'] ?? ''));

        return new self(
            search: $search !== '' ? $search : null,
            statuses: self::statuses($query),
            customerId: self::intOrNull($query['customer_id'] ?? null),
            cityId: self::intOrNull($query['city_id'] ?? null),
            from: self::textOrNull($query['from'] ?? null),
            to: self::textOrNull($query['to'] ?? null),
        );
    }

    /**
     * Accepts `status=ready` and `status[]=ready&status[]=printing` alike, and quietly drops a
     * value that names no status — a filter nobody can satisfy would return an empty page and
     * look like "no orders" rather than "you asked for something that does not exist".
     *
     * @param  array<string, mixed>  $query
     * @return list<OrderStatus>|null
     */
    private static function statuses(array $query): ?array
    {
        $raw = $query['status'] ?? null;

        if ($raw === null || $raw === '' || $raw === []) {
            return null;
        }

        $statuses = array_filter(array_map(
            fn (mixed $value) => OrderStatus::tryFrom((string) $value),
            is_array($raw) ? $raw : [$raw],
        ));

        return $statuses === [] ? null : array_values($statuses);
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
