<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A pool has one current period, or it has none.
 *
 * Two open at once would make «الفترة الحالية» a question with two answers — and the grace window,
 * which decides whether a man's money joins now or waits a month, would have two boundaries to
 * measure him against. The database refuses it with a partial unique index; this is that refusal
 * said in Arabic, naming the period already standing so the reader knows what to close.
 */
final class PoolAlreadyHasAnOpenPeriod extends DomainException
{
    public static function make(string $pool, string $startsOn, string $endsOn): self
    {
        return new self("الصندوق «{$pool}» له فترة مفتوحة بالفعل ({$startsOn} → {$endsOn}) — أغلقها أولاً");
    }
}
