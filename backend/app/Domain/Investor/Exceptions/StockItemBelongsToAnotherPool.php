<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A shelf may be owned by one pool and no more.
 *
 * **Why this is refused rather than merged.** A cost layer carries exactly one container id, and
 * the lookup that answers «which pool financed this shelf?» answers with the first row it finds.
 * Two pools over one shelf would raise no error at all — the goods of one set of investors would
 * simply be accounted to the other, and every total would still balance while being wrong. The
 * database refuses it with a unique index; this is that refusal said in Arabic, one step earlier,
 * where it can still name the pool that already holds the shelf.
 *
 * There is deliberately no «move it for me». A shelf's layers and its whole history carry its
 * pool, so changing the owner is a new pool and a fold-in, never an `UPDATE`.
 */
final class StockItemBelongsToAnotherPool extends DomainException
{
    public static function make(string $stockItem, string $pool): self
    {
        return new self("المادة «{$stockItem}» تتبع صندوق «{$pool}» — ولا يمكن أن تتبع صندوقين");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['stock_item_ids' => [$this->getMessage()]];
    }
}
