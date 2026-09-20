<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

use App\Domain\Investor\Enums\WalletEntryType;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * «الحد الأدنى للبقاء» — when an investor's capital becomes free to leave a pool.
 *
 * **One place, because two callers answer the same question.** The action that refuses an early
 * exit and the screen that tells a man when he may ask both need this, and the day they disagree
 * is the day somebody is told «في ٢٠٢٧-٠٣-٠١» and refused on that date. The same standing
 * {@see GraceWindow} has for the other boundary.
 *
 * ## Measured from his first capital into this pool
 *
 * Not the latest top-up: restarting the clock on every deposit would make paying more into a pool
 * a reason to be locked in longer, which is the opposite of what anybody means by a minimum term.
 * Not per tranche either — that turns one stake into a row of separately-maturing parcels, and
 * «كم أستطيع أن أسحب اليوم؟» stops having one answer.
 *
 * ## A man who left and came back starts again
 *
 * The first allocation is read from the rows that are **standing now**, so somebody who took
 * everything out and later put money back is measured from the return, not from the original
 * January he has no capital left from. That falls out of reading the ledger rather than a stored
 * `joined_at`, and it is the honest answer: it is new money.
 */
final class MinimumTerm
{
    /**
     * The day this investor's capital in this pool may be asked back, or null when it already may.
     *
     * Null covers the three cases a screen should treat identically — no minimum is set, he has
     * no capital here, and the term has already run — because in all three there is nothing to
     * tell him.
     */
    public static function freeOn(int $investorId, int $poolId, int $termMonths): ?Carbon
    {
        if ($termMonths <= 0) {
            return null;
        }

        $since = self::capitalHeldSince($investorId, $poolId);

        if ($since === null) {
            return null;
        }

        // `addMonthsNoOverflow` so a stake made on the 31st matures on the 28th of a short month
        // rather than slipping into the next one. The same helper the period calendar uses.
        $free = $since->copy()->addMonthsNoOverflow($termMonths);

        return $free->isFuture() ? $free : null;
    }

    public static function admits(int $investorId, int $poolId, int $termMonths): bool
    {
        return self::freeOn($investorId, $poolId, $termMonths) === null;
    }

    /**
     * When his **current** holding in this pool began.
     *
     * The earliest allocation that has not since been undone by taking everything out: walked
     * forward through his movements, resetting whenever the balance reaches zero. A reversal is
     * netted by reading `deltas()`, exactly as {@see InvestorBalances} does — a reversed
     * allocation never started a term.
     */
    private static function capitalHeldSince(int $investorId, int $poolId): ?Carbon
    {
        $entries = DB::table('investor_wallet_entries as e')
            ->leftJoin('investor_wallet_entries as r', 'r.id', '=', 'e.reverses_entry_id')
            ->where('e.investor_id', $investorId)
            ->where('e.investor_deal_id', $poolId)
            ->whereNull('e.deleted_at')
            ->orderBy('e.occurred_at')
            ->orderBy('e.id')
            ->get([
                'e.type',
                'e.amount',
                'e.occurred_at',
                'r.type as reversed_type',
            ]);

        $balance = '0';
        $since = null;

        foreach ($entries as $row) {
            $type = WalletEntryType::tryFrom((string) $row->type);

            if ($type === null) {
                continue;
            }

            $effective = $type === WalletEntryType::Reversal
                ? WalletEntryType::tryFrom((string) ($row->reversed_type ?? ''))
                : $type;

            if ($effective === null) {
                continue;
            }

            $delta = $effective->deltas()['capital_deal'];

            if ($delta === 0) {
                continue;
            }

            $signed = bcmul(
                (string) $row->amount,
                (string) ($type === WalletEntryType::Reversal ? -$delta : $delta),
                2,
            );

            $wasEmpty = bccomp($balance, '0', 2) <= 0;
            $balance = bcadd($balance, $signed, 2);

            if ($wasEmpty && bccomp($balance, '0', 2) > 0) {
                $since = Carbon::parse((string) $row->occurred_at);
            }

            if (bccomp($balance, '0', 2) <= 0) {
                $since = null;
            }
        }

        return $since;
    }
}
