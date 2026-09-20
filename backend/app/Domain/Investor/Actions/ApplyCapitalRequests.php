<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\Money;

/**
 * Lets the queue into a period that is opening.
 *
 * Every `in` request pending on this pool becomes an `allocation` dated to the new period, and the
 * request is stamped with the row it became. This is the boundary those people have been waiting
 * for, and admitting them is not optional: a period that opened without its queue would give
 * everybody who waited a month of ownership they did not get.
 *
 * **Only `in`.** An exit leaves at the **close**, after the period's profit has been distributed,
 * so that a man who asked to leave in September is still paid his September share. That half
 * belongs to the close, in a later slice; this action reads the direction rather than assuming it,
 * so the day it arrives nothing here needs revisiting.
 *
 * ## The one that cannot be paid
 *
 * A man may queue 30,000 in October and spend it in November. **His empty wallet must not stop the
 * pool starting its month**, so the request is checked before it is attempted: what he can cover is
 * applied, what he cannot stays `pending` and is handed back to the caller to report. The period
 * opens either way, and his request is still queued for the next boundary.
 *
 * That is a deliberate departure from the all-or-nothing discipline the rest of this context keeps,
 * and the reason is what these rows are: independent acts by different people, not the steps of one
 * transaction. A half-funded *deal* is incoherent; a period where one of five investors could not
 * pay is an ordinary Tuesday.
 *
 * **Checked rather than attempted-and-caught**, because there is no `try`/`catch` anywhere in
 * `app/` and a test enforces it — see ErrorHandlingTest. The ceiling read here is the same figure
 * {@see RecordWalletEntry} guards against, taken from the same query; that action remains the one
 * that refuses, and this is only a decision about whether to ask it. Both run inside the period's
 * transaction and under its lock, so the balance cannot move between the two.
 */
final class ApplyCapitalRequests
{
    public function __construct(
        private readonly RecordWalletEntry $recordEntry,
        private readonly InvestorBalances $balances,
    ) {}

    /**
     * @return array{applied: list<InvestmentCapitalRequest>, short: array<int, array{investor_id: int, wanted: string, available: string}>}
     */
    public function __invoke(InvestmentPeriod $period): array
    {
        $pending = InvestmentCapitalRequest::query()
            ->where('investor_deal_id', $period->investor_deal_id)
            ->where('status', CapitalRequestStatus::Pending->value)
            ->where('direction', CapitalRequestDirection::In->value)
            // Oldest first: when two of a man's requests draw on one wallet balance, the one he
            // has waited longest for is served first.
            ->orderBy('requested_at')
            ->orderBy('id')
            ->lockForUpdate()
            ->get();

        $applied = [];
        $short = [];

        foreach ($pending as $request) {
            $investorId = (int) $request->investor_id;
            $wanted = (string) $request->amount;
            $available = $this->balances->forInvestor($investorId)['wallet']['capital'];

            if (bccomp($wanted, $available, Money::SCALE) > 0) {
                $short[(int) $request->getKey()] = [
                    'investor_id' => $investorId,
                    'wanted' => $wanted,
                    'available' => $available,
                ];

                continue;
            }

            $entry = ($this->recordEntry)(
                new WalletEntryData(
                    investorId: $investorId,
                    type: $request->direction->walletType(),
                    amount: $wanted,
                    investorDealId: (int) $request->investor_deal_id,
                    notes: $request->notes,
                ),
                $request->requested_by,
            );

            $request->status = CapitalRequestStatus::Applied;
            $request->effective_period_id = $period->getKey();
            $request->applied_entry_id = $entry->getKey();
            $request->save();

            $applied[] = $request;
        }

        return ['applied' => $applied, 'short' => $short];
    }
}
