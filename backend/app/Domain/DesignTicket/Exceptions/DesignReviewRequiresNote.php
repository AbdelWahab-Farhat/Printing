<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * «تعديل مطلوب» was sent with nothing said.
 *
 * The whole value of keeping versions is knowing *why* one was replaced; a change request with no
 * words turns the history into a count and leaves the designer guessing.
 * `DesignRejectionRequiresReason` makes the same argument for an order's artwork, and it applies
 * harder here: that one is a refusal, this one is an instruction, and an instruction with no
 * content is not one.
 */
final class DesignReviewRequiresNote extends DomainException
{
    public static function make(): self
    {
        return new self('اكتب ما المطلوب تعديله');
    }
}
