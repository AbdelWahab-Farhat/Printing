<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * Where an accounting period is in its life — and there are only two places.
 *
 * **No draft and no cancelled**, unlike {@see DealStatus}. A period is not a thing somebody writes
 * and then decides about: it begins because the last one ended, and it ends because its dates ran
 * out. Nothing is agreed, so there is nothing to review; nothing is reserved, so there is nothing
 * to abandon.
 *
 * `Closed` is final in the strongest sense in this system: money was divided on that period's
 * figures and paid into wallets it can be withdrawn from. Reopening it would be asking for the
 * money back.
 */
enum PeriodStatus: string
{
    /** Trading. Margin accrues to it, and its figures are all still derived. */
    case Open = 'open';

    /** Settled and frozen. Its snapshot is history and its distribution has been paid. */
    case Closed = 'closed';

    public function label(): string
    {
        return match ($this) {
            self::Open => 'مفتوحة',
            self::Closed => 'مغلقة',
        };
    }

    /** Whether new capital, expenses and margin may still land in it. */
    public function acceptsActivity(): bool
    {
        return $this === self::Open;
    }
}
