<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Support\Exceptions\DomainException;

/**
 * Something was asked of a ticket that has finished.
 *
 * Covers both endings, and names which one, because they mean different things to the person
 * reading the message: «مكتمل» says the work was done and the artwork is on the customer's
 * account, «ملغى» says it never will be. A single «التذكرة مغلقة» would leave a designer
 * wondering whether their last upload landed.
 */
final class DesignTicketIsClosed extends DomainException
{
    public static function make(DesignTicketStatus $status): self
    {
        return new self("لا يمكن تنفيذ هذا الإجراء: التذكرة {$status->label()}");
    }
}
