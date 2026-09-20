<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealShare;

/**
 * Puts a man on a pool's roster the first time his money goes in.
 *
 * ## Why this has to exist separately
 *
 * On a صفقة the roster **was** ownership: `share_percent` said what fraction of the investors' half
 * was his, agreed before the lorry was funded, and {@see SyncDealShares} wrote it as part of
 * striking the deal. There was never a moment where money existed without a row beside it.
 *
 * A صندوق has no such moment to hang it on. Capital arrives whenever somebody offers it, ownership
 * is recomputed from the ledger at every close, and the roster stops being ownership at all — it
 * becomes what its name says: **a list of who is in this pool, and since when**.
 *
 * So the row is created where the money moves, and nowhere else.
 *
 * ## `share_percent` is null, and that is the whole point
 *
 * Not zero, and not an even split. Both would be numbers somebody could read as a term that was
 * agreed, and neither is: a pool's split is worked out per period from capital and written to
 * `investment_period_shares`. Null is the only honest value, and the migration that made the column
 * nullable exists for this row alone.
 *
 * ## Idempotent, and it never moves `joined_at`
 *
 * Topping up is not joining. A man who put money in last March and adds more today has been in the
 * pool since March, and the date that says so is the one the screen shows beside his name.
 */
final class EnsurePoolMembership
{
    public function __invoke(InvestorDeal $pool, int $investorId): ?InvestorDealShare
    {
        // Only a pool. A legacy صفقة's roster is its frozen terms, written when it was struck, and
        // a row appearing here would be a partner nobody agreed to.
        if (! $pool->isPool()) {
            return null;
        }

        $existing = InvestorDealShare::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('investor_id', $investorId)
            ->first();

        if ($existing !== null) {
            return $existing;
        }

        $share = new InvestorDealShare;
        $share->investor_deal_id = $pool->getKey();
        $share->investor_id = $investorId;
        $share->share_percent = null;
        $share->joined_at = now();
        $share->save();

        return $share;
    }
}
