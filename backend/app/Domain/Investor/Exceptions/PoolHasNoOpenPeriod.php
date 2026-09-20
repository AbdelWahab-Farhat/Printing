<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Capital cannot be offered to a pool that is not in a period.
 *
 * **Not a bookkeeping nicety.** Whether money joins now or waits is decided by measuring today
 * against the current period's start; with no period there is no boundary, so there is no honest
 * answer to give the investor before he submits — and this feature's whole promise is that he is
 * told before, not after.
 *
 * In practice a pool gets its first period when it is opened, so this is reachable mainly between
 * a close and the next open.
 */
final class PoolHasNoOpenPeriod extends DomainException
{
    public static function make(string $pool): self
    {
        return new self("الصندوق «{$pool}» ليس له فترة مفتوحة — افتح فترة جديدة قبل إدخال رأس المال");
    }
}
