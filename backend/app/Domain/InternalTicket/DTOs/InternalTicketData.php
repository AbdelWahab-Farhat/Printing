<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\DTOs;

use App\Domain\InternalTicket\Enums\InternalTicketPriority;

/**
 * «تذكرة جديدة» كما ملأها الموظف، في طريقها إلى الداخل.
 *
 * «التفاصيل» ليست عموداً على التذكرة: تصير أول رسالةٍ في المحادثة، كما في بريمولا — فيُقرأ ما
 * كُتب ساعةَ الفتح في مكانه من الحديث، ويُعدَّل ويُقتبس كأيّ رسالة.
 */
final readonly class InternalTicketData
{
    public function __construct(
        public int $assigneeId,
        public string $title,
        public string $description,
        public InternalTicketPriority $priority = InternalTicketPriority::Medium,
        public ?int $categoryId = null,
        public ?int $customerId = null,
        public ?int $orderId = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data  already-validated request data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            assigneeId: (int) $data['assignee_id'],
            title: trim((string) $data['title']),
            description: trim((string) $data['description']),
            priority: InternalTicketPriority::tryFrom((string) ($data['priority'] ?? ''))
                ?? InternalTicketPriority::Medium,
            categoryId: self::idOrNull($data['category_id'] ?? null),
            customerId: self::idOrNull($data['customer_id'] ?? null),
            orderId: self::idOrNull($data['order_id'] ?? null),
        );
    }

    private static function idOrNull(mixed $value): ?int
    {
        return $value === null || $value === '' ? null : (int) $value;
    }
}
