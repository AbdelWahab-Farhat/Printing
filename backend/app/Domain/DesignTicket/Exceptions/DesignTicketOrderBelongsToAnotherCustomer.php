<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A ticket named an order that belongs to somebody else.
 *
 * The same guard `DesignDoesNotBelongToCustomer` puts on an order's artwork, pointed the other
 * way. Without it a ticket could quietly link one customer's request to another's order, and the
 * approved design would land on an account the work was never done for.
 */
final class DesignTicketOrderBelongsToAnotherCustomer extends DomainException
{
    public static function make(int $orderId, int $customerId): self
    {
        return new self("الطلبية رقم {$orderId} لا تخصّ العميل رقم {$customerId}");
    }
}
