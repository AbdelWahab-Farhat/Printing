<?php

declare(strict_types=1);

namespace App\Domain\Treasury\DTOs;

use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use DateTimeInterface;

/**
 * One movement, as the context that caused it describes it.
 *
 * **What crosses the boundary.** Order, Shortage, Investor and Vendor build one of these and hand
 * it to `TreasuryService::post()`; Treasury never reads their models. `sourceType` is the
 * morph-map alias of the row that caused it (`order_payment`), `sourceId` its id.
 */
final readonly class MovementData
{
    public function __construct(
        public int $accountId,
        public MovementDirection $direction,
        public MovementKind $kind,
        public string $amount,
        public DateTimeInterface $occurredAt,
        public string $sourceType,
        public int $sourceId,
        public ?int $orderId = null,
        public ?string $notes = null,
        public ?int $recordedBy = null,
        public ?int $operationId = null,
        public ?int $counterpartAccountId = null,
        public ?int $reversesMovementId = null,
        // 0 for everything but a debt reposted after its source changed — a purchase order whose
        // total was edited. The reversed original still holds revision 0 in the posted-once index.
        public int $revision = 0,
    ) {}
}
