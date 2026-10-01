<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Actions;

use App\Domain\Treasury\Models\TreasuryAccount;

/**
 * Makes this account the default of its kind, taking the title from whichever held it.
 *
 * The previous holder is cleared first and one row at a time — a mass update would skip the
 * audit trail, and «من غيّر الحساب الافتراضي؟» is exactly what it is for. The partial unique
 * index on `(kind) WHERE is_default` is what holds if two people do this at once.
 */
final class MakeSoleDefault
{
    public function __invoke(TreasuryAccount $account): void
    {
        TreasuryAccount::query()
            ->where('kind', $account->kind->value)
            ->where('is_default', true)
            ->whereKeyNot($account->getKey())
            ->lockForUpdate()
            ->get()
            ->each(fn (TreasuryAccount $previous) => $previous->forceFill(['is_default' => false])->save());

        $account->forceFill(['is_default' => true, 'is_active' => true])->save();
    }
}
