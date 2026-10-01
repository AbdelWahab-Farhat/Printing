<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Exceptions\AccountChangeRefused;
use App\Domain\Treasury\Models\TreasuryAccount;

/**
 * Where a custody account's money may be set to go at settlement — shared by create and edit.
 *
 * Custody only, and only into an active account money can sit in: settling Nawris into another
 * custody would only move the waiting from one holder to the next.
 */
final class SettlesIntoRule
{
    public static function check(AccountKind $kind, ?int $targetId): void
    {
        if ($targetId === null) {
            return;
        }

        if ($kind !== AccountKind::Custody) {
            throw AccountChangeRefused::onlyCustodySettles();
        }

        $target = TreasuryAccount::query()->findOrFail($targetId);

        if (! $target->is_active || ! $target->kind->spendable()) {
            throw AccountChangeRefused::cannotSettleInto((string) $target->name);
        }
    }
}
