<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Support\Money;

/**
 * Records what a pool earned from one source, into the period that is open now.
 *
 * **The pool counterpart of {@see PostDealShare}, and deliberately much simpler.** That action had
 * to split a figure across frozen percentages the moment it landed. A pool does not know its
 * percentages until its period closes, so this writes the figure whole and leaves the dividing to
 * {@see CloseInvestmentPeriod}.
 *
 * ## Idempotent by comparison, like its sibling
 *
 * Posting the same source twice computes the same total, finds it already standing, and writes
 * nothing. That is what lets a status walked twice, or a listener fired twice, be harmless.
 *
 * ## A correction is a delta, never an edit
 *
 * ```
 * Sept   order X realizes 4,000   → +4,000 into September
 * Sept   closes; the 4,000 is divided and paid into wallets
 * Oct    X is restated to 3,000   → −1,000 into OCTOBER
 * ```
 *
 * September is not touched, because its money has already been withdrawn. The difference is what
 * the ledger can honestly carry, and it lands where corrections always land: the period that is
 * open when somebody notices.
 *
 * **This is the one real behavioural difference from the deal model**, where a restatement reversed
 * the original rows outright. It could, because a deal's profit was not released until the deal
 * ended; a pool's is released every month.
 *
 * ## Zero is a figure like any other
 *
 * A source whose total falls to nothing — a cancelled order, a restated line that no longer draws on
 * this pool — produces a delta that cancels everything standing. Returning early on a zero *target*
 * would leave the original earning in place for a sale that never happened.
 */
final class PostPoolEarning
{
    /**
     * @param  string  $amount  the pool's whole slice, signed — this is not anybody's share yet
     * @param  string  $sourceType  an `AuditSubject` value
     * @return InvestmentRealizedEarning|null the row written, or null when nothing had changed
     */
    public function __invoke(
        InvestorDeal $pool,
        string $amount,
        string $sourceType,
        int $sourceId,
        ?string $note = null,
        ?int $actorId = null,
    ): ?InvestmentRealizedEarning {
        $period = $this->openPeriodFor($pool);

        if ($period === null) {
            return null;
        }

        // Everything this source has ever contributed to this pool, across every period — the only
        // honest baseline for a delta, because an earlier attempt may sit in a period that closed
        // months ago.
        $standing = Money::round((string) (InvestmentRealizedEarning::query()
            ->whereHas('period', fn ($q) => $q->where('investor_deal_id', $pool->getKey()))
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->sum('amount') ?: '0'));

        $delta = bcsub(Money::round($amount), $standing, 2);

        if (bccomp($delta, '0', 2) === 0) {
            return null;
        }

        $sequence = 1 + (int) InvestmentRealizedEarning::query()
            ->where('investment_period_id', $period->getKey())
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->max('source_sequence');

        $row = new InvestmentRealizedEarning;
        $row->investment_period_id = $period->getKey();
        $row->source_type = $sourceType;
        $row->source_id = $sourceId;
        $row->source_sequence = $sequence;
        $row->amount = $delta;
        $row->occurred_at = now();
        $row->notes = $sequence > 1 ? ($note ?? 'تصحيح') : $note;
        $row->recorded_by = $actorId;
        $row->save();

        return $row;
    }

    /**
     * The pool's open period.
     *
     * Null should be unreachable — {@see CloseInvestmentPeriod} opens the next period in the same
     * transaction it closes one, so a pool always has exactly one. Returning null rather than
     * throwing is deliberate all the same: this runs inside an order's status change, and a pool
     * whose periods somebody has managed to leave closed must not make an order undeliverable. The
     * earning is lost rather than the order, and that is the lesser failure of the two.
     */
    private function openPeriodFor(InvestorDeal $pool): ?InvestmentPeriod
    {
        return InvestmentPeriod::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('status', PeriodStatus::Open->value)
            ->lockForUpdate()
            ->first();
    }
}
