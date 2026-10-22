<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Queries;

use App\Domain\InternalTicket\Enums\InternalTicketStatus;

/**
 * ما تُسأل عنه قائمة «الموظفين» — كقائمة بريمولا الداخلية.
 *
 * **`allTickets` ليس فلتراً يضعه أيّ أحد.** هو تبويب «الكل» عند المدير؛ والمتحكّم يُنزله `false`
 * لكل من سواه مهما أرسل، فلا يرى موظفٌ إلا ما هو طرفٌ فيه.
 */
final readonly class InternalTicketFilters
{
    public const SORT_LATEST = 'latest';

    public const SORT_OLDEST_ACTIVITY = 'oldest_activity';

    public function __construct(
        public bool $allTickets = false,
        public ?InternalTicketStatus $status = null,
        /** كودُ التذكرة، أو عنوانها، أو اسمُ أحد طرفيها. */
        public ?string $search = null,
        public ?int $categoryId = null,
        /** تذاكرُ موظفٍ بعينه، أيَّ طرفٍ كان. */
        public ?int $userId = null,
        public bool $unreadOnly = false,
        public ?int $orderId = null,
        public ?int $customerId = null,
        public string $sort = self::SORT_LATEST,
    ) {}

    /**
     * @param  array<string, mixed>  $query  validated query-string values
     */
    public static function fromArray(array $query, bool $mayReadAll): self
    {
        $search = isset($query['search']) ? trim((string) $query['search']) : '';

        return new self(
            allTickets: $mayReadAll && ($query['scope'] ?? 'mine') === 'all',
            status: InternalTicketStatus::tryFrom((string) ($query['status'] ?? '')),
            search: $search !== '' ? $search : null,
            categoryId: self::intOrNull($query['category_id'] ?? null),
            userId: self::intOrNull($query['user_id'] ?? null),
            unreadOnly: filter_var($query['unread'] ?? false, FILTER_VALIDATE_BOOLEAN),
            orderId: self::intOrNull($query['order_id'] ?? null),
            customerId: self::intOrNull($query['customer_id'] ?? null),
            sort: ($query['sort'] ?? null) === self::SORT_OLDEST_ACTIVITY ? self::SORT_OLDEST_ACTIVITY : self::SORT_LATEST,
        );
    }

    private static function intOrNull(mixed $value): ?int
    {
        return $value !== null && $value !== '' ? (int) $value : null;
    }
}
