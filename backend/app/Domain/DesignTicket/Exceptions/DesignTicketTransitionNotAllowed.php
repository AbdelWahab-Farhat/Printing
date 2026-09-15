<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Support\Exceptions\DomainException;

/**
 * An action asked for a move the ticket's current state does not allow.
 *
 * The backstop rather than the everyday refusal: each action checks the thing a user would
 * actually get wrong — uploading before acceptance, reviewing twice — and says so in its own
 * words. This catches a move nobody wrote a message for, so a future action that forgets its own
 * guard fails loudly against {@see DesignTicketStatus::allowedNext()} instead of writing a state
 * nothing can leave.
 */
final class DesignTicketTransitionNotAllowed extends DomainException
{
    public static function make(DesignTicketStatus $from, DesignTicketStatus $to): self
    {
        return new self("لا يمكن نقل التذكرة من «{$from->label()}» إلى «{$to->label()}»");
    }
}
