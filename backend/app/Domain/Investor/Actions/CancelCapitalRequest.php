<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Exceptions\CapitalRequestCannotBeCancelled;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use Illuminate\Support\Facades\DB;

/**
 * Calls off a queued request before its boundary.
 *
 * **Nothing to unwind.** A pending request never moved money — the deposit has been in the
 * investor's wallet the whole time — so cancelling writes no ledger row and leaves no trace in the
 * balances. That is the property that makes queueing acceptable to the person waiting: his money
 * was never trapped anywhere.
 *
 * An **applied** request is a different matter and is refused. There is a wallet row behind it, and
 * undoing a wallet row is a reversal — a deliberate act by somebody, with its own reason — not the
 * withdrawal of an intention. The two are kept apart everywhere money is concerned here.
 *
 * Under a row lock, because the period-open action is reading exactly this set of rows and the race
 * is real: the boundary can fall between the read and the write.
 */
final class CancelCapitalRequest
{
    /**
     * @throws CapitalRequestCannotBeCancelled
     */
    public function __invoke(InvestmentCapitalRequest $request): InvestmentCapitalRequest
    {
        return DB::transaction(function () use ($request): InvestmentCapitalRequest {
            $locked = InvestmentCapitalRequest::query()
                ->whereKey($request->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if (! $locked->isCancellable()) {
                throw CapitalRequestCannotBeCancelled::make($locked->status->label());
            }

            $locked->status = CapitalRequestStatus::Cancelled;
            $locked->save();

            return $locked;
        });
    }
}
