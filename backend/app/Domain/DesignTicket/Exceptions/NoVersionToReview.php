<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A verdict named a ticket with nothing waiting on it.
 *
 * Reachable whenever a reviewer's screen is stale — the version was already judged, or the ticket
 * was cancelled from another device. Its own failure rather than a generic one because the answer
 * the reader needs is "refresh, this has moved on", not "something went wrong".
 */
final class NoVersionToReview extends DomainException
{
    public static function make(): self
    {
        return new self('لا يوجد تصميم بانتظار المراجعة في هذه التذكرة');
    }
}
