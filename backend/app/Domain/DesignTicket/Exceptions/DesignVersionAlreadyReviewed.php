<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Support\Exceptions\DomainException;

/**
 * A verdict was passed on a version that already has one.
 *
 * **A version is judged once.** Changing a verdict afterwards would erase the reason the next
 * version exists, and that trail is the entire value of keeping versions at all — the argument
 * `DesignAlreadyReviewed` already makes for an order's artwork.
 *
 * A reviewer who changed their mind asks for the next version rather than rewriting the last
 * verdict, which is what the conversation actually was.
 */
final class DesignVersionAlreadyReviewed extends DomainException
{
    public static function make(int $version, DesignSubmissionStatus $status): self
    {
        return new self("النسخة رقم {$version} تمت مراجعتها مسبقاً: {$status->label()}");
    }
}
