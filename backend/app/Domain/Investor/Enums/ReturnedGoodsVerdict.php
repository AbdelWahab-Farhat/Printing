<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * What happened to the material a cancelled order gave back.
 *
 * The one fact the system cannot work out for itself: the movement ledger records quantities, not
 * whether there is ink on them. So it is asked, and the period will not close until it is answered.
 */
enum ReturnedGoodsVerdict: string
{
    /** Nobody has looked yet. Blocks the close. */
    case Open = 'open';

    /** Usable — it goes back on the shelf and nothing is written off. */
    case Good = 'good';

    /** Ruined. Its cost is charged to the pool as damage. */
    case Damaged = 'damaged';

    public function label(): string
    {
        return match ($this) {
            self::Open => 'بانتظار الفحص',
            self::Good => 'صالحة',
            self::Damaged => 'تالفة',
        };
    }

    public function isAnswered(): bool
    {
        return $this !== self::Open;
    }
}
