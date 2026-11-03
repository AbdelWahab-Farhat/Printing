<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Enums\OrderTicketKind;
use App\Domain\Order\Queries\OrderTicketsQuery;
use Carbon\CarbonInterface;

/**
 * صفٌّ في «التذاكر المرتبطة» — تذكرةٌ من أيّ الأنواع الثلاثة، بما يكفي لرسمها وفتحها.
 *
 * **ما يُرسم فقط، لا التذكرة نفسها**: المحادثةُ تُقرأ من شاشتها هي، وهذا السطرُ يقول ما هي وأين
 * وصلت. انظر {@see OrderTicketsQuery}.
 */
final readonly class OrderTicket
{
    public function __construct(
        public OrderTicketKind $kind,
        public int $id,
        /** «T24» و«D6». `null` لتذكرة العميل: صفُّها بلا كود، ويُعرف بعميله. */
        public ?string $code,
        public string $title,
        public string $status,
        public string $statusLabel,
        public bool $isOpen,
        /** آخرُ ما جرى فيها — ما تُرتَّب به القائمة بعد المفتوحة أولاً. */
        public ?CarbonInterface $activityAt,
    ) {}
}
