<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A design ticket for an order that no longer takes artwork — at the press or past it.
 *
 * Its approval puts the design on the order (PRINT-COLORS.md §11), which such an order refuses;
 * the ticket would be work nobody could use.
 */
final class DesignTicketOrderTakesNoArtwork extends DomainException
{
    public static function make(string $orderCode, string $statusLabel): self
    {
        return new self("الطلبية {$orderCode} في «{$statusLabel}» ولم تعد تقبل تصميماً — لا تُفتح لها تذكرة تصميم");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['order_id' => [$this->getMessage()]];
    }
}
