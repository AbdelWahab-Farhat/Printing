<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

use App\Domain\Investor\Models\InvestorDeal;

/**
 * Which of the two containers a row of `investor_deals` is.
 *
 * **`Deal` is history and `Pool` is the present**, and the distinction is permanent rather than a
 * migration state: the صفقات that were struck under the old arrangement keep their rows, their
 * ledger, their expenses and their audit trail, and their screens go on rendering. Nothing about
 * a legacy deal is rewritten, because rewriting it would falsify what was agreed at the time.
 *
 * A row never changes kind. A deal that is still open at the migration is *folded into* a pool —
 * money released from it and allocated to the pool through the ordinary ledger — and the deal
 * itself is left closed and readable. See INVESTMENT-FUND-DESIGN.md §11.
 *
 * `label()` is not decoration: `AuditValueLabels` auto-translates any enum-cast column whose enum
 * can name itself, so the history of a container prints Arabic without a second dictionary.
 *
 * @see InvestorDeal::isPool()
 */
enum PoolKind: string
{
    /**
     * One financed purchase of stock, opened against one purchase order and closed when its goods
     * were gone. Read-only from the day pools arrive.
     */
    case Deal = 'deal';

    /**
     * A continuous pool for one material. It never closes; its **periods** do.
     */
    case Pool = 'pool';

    public function label(): string
    {
        return match ($this) {
            self::Deal => 'صفقة',
            self::Pool => 'صندوق',
        };
    }

    /** Whether rows of this kind may still be created and traded. */
    public function isLive(): bool
    {
        return $this === self::Pool;
    }
}
