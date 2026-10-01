<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * عمليةٌ على الحسابات تُكتب مرّة ولا تُمسّ بعدها — التصحيحُ عمليةٌ ثانية تعكسها.
 */
final class OperationIsImmutable extends DomainException
{
    public static function make(): self
    {
        return new self('العمليات على الحسابات لا تُعدَّل — التصحيح يكون بعكس العملية');
    }

    public static function cannotBeDeleted(): self
    {
        return new self('العمليات على الحسابات لا تُحذف — التصحيح يكون بعكس العملية');
    }
}
