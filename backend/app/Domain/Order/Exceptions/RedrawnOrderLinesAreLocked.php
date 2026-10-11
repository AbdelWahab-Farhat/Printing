<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * The lines of an order whose stock has been put back and taken again cannot be edited.
 *
 * **A restored or reinstated order carries a draw the ledger has already settled once.** The
 * investor's payment for the first draw is keyed on the line and stands — the delete handed the
 * goods to the company, not back to the deal — and re-posting the line after an edit would read
 * that settled payment as a figure to correct. That is the open BACKLOG item «الاستعادة ثم إعادة
 * بيان الخصم»; until it is fixed the edit is refused rather than allowed to take an investor's
 * money. Rare by construction: it needs an order deleted or cancelled after its stock left.
 */
final class RedrawnOrderLinesAreLocked extends DomainException
{
    public static function make(): self
    {
        return new self(
            'خرجت بضاعة هذه الطلبية من المخزن ثم أُعيدت إليه من قبل (حذف ثم استعادة، أو إلغاء ثم تراجع)،'
            .' فلا تُعدَّل بنودها بعد ذلك — ألغِ الطلبية وأعد أخذها'
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
