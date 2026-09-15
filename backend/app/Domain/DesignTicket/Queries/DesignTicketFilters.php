<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Queries;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;

/**
 * What the design tickets list is being asked for.
 *
 * **`visibleToUserId` is not a filter the user sets.** It is the reader's own narrowing, carried
 * down from the controller: null means "this reader holds `design_tickets.view_all`, show
 * everything", and an id means "show only what this person is part of". It lives here rather than
 * in the query for the reason `ShortageFilters` gives about the archive grant — two queries seed
 * the builder separately, the list and the status counts, and a rule living in only one of them
 * makes the chip row count rows the list below it will not show. A number that leaks the
 * existence of work a reader may not open is a leak even though no row is rendered.
 */
final readonly class DesignTicketFilters
{
    /**
     * @param  list<DesignTicketStatus>|null  $statuses  more than one, because the queues people
     *                                                   ask for are groups: «كل ما لم يُغلق» is
     *                                                   four statuses at once, and a screen that
     *                                                   had to call four times to draw one number
     *                                                   would draw the wrong one.
     */
    public function __construct(
        public ?array $statuses = null,
        public ?int $designerId = null,
        /** «الطابور المشترك» — addressed to nobody and not yet taken. A real question. */
        public bool $unassignedOnly = false,
        public ?int $requestedByUserId = null,
        public ?int $customerId = null,
        public ?int $orderId = null,
        /** Matches the ticket's title, its code, or the snapshotted customer name. */
        public ?string $search = null,
        /** The reader, unless they hold `design_tickets.view_all` — see the class docblock. */
        public ?int $visibleToUserId = null,
    ) {}

    /**
     * @param  array<string, mixed>  $query  validated query-string values
     */
    public static function fromArray(array $query, ?int $visibleToUserId = null): self
    {
        $designer = $query['designer'] ?? null;

        return new self(
            statuses: self::statuses($query),
            // `designer=me` is resolved to an id by the controller, the only layer that knows who
            // is asking. What arrives here is always an id or «none».
            designerId: $designer !== null && $designer !== '' && $designer !== 'none'
                ? (int) $designer
                : null,
            unassignedOnly: $designer === 'none',
            requestedByUserId: self::intOrNull($query['requested_by'] ?? null),
            customerId: self::intOrNull($query['customer_id'] ?? null),
            orderId: self::intOrNull($query['order_id'] ?? null),
            search: self::search($query),
            visibleToUserId: $visibleToUserId,
        );
    }

    /**
     * The same filters with the status dropped — what the counts are built from.
     *
     * **Rebuilt field by field, and that is the trap.** `ShortageFilters::withoutStatuses()`
     * carries the same warning, and ORDER-DELETE-AND-ARCHIVE §٦ names it as the silent failure of
     * that feature: a field added to the constructor and forgotten here makes the chip row count
     * a different set of rows from the list beside it. Every field below is deliberate; adding one
     * to this class means adding it here too.
     */
    public function withoutStatuses(): self
    {
        return new self(
            statuses: null,
            designerId: $this->designerId,
            unassignedOnly: $this->unassignedOnly,
            requestedByUserId: $this->requestedByUserId,
            customerId: $this->customerId,
            orderId: $this->orderId,
            search: $this->search,
            visibleToUserId: $this->visibleToUserId,
        );
    }

    /**
     * Blank is not a filter — clearing the search box sends `search=`, and reading that as a term
     * would answer «show me everything» with an empty page.
     *
     * @param  array<string, mixed>  $query
     */
    private static function search(array $query): ?string
    {
        $search = isset($query['search']) ? trim((string) $query['search']) : '';

        return $search !== '' ? $search : null;
    }

    /**
     * Accepts `status=new` and `status[]=new&status[]=in_progress` alike, and quietly drops a
     * value that names no status — the shape every other filter in this codebase settled on.
     *
     * @param  array<string, mixed>  $query
     * @return list<DesignTicketStatus>|null
     */
    private static function statuses(array $query): ?array
    {
        $raw = $query['status'] ?? null;

        if ($raw === null || $raw === '' || $raw === []) {
            return null;
        }

        $statuses = array_filter(array_map(
            fn (mixed $value) => DesignTicketStatus::tryFrom((string) $value),
            is_array($raw) ? $raw : [$raw],
        ));

        return $statuses === [] ? null : array_values($statuses);
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }
}
