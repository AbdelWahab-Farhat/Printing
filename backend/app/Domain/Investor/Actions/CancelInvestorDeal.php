<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Exceptions\DealIsNotEditable;
use App\Domain\Investor\Models\InvestorDeal;

/**
 * Abandons a deal before anything arrived.
 *
 * **From `draft` alone.** An open deal owns cost layers, and FIFO goes on drawing from them
 * whatever the status says — so a cancelled-but-funded deal would be a row no screen lists while
 * its stock is quietly sold. A deal with goods is closed, which has real conditions attached.
 */
final class CancelInvestorDeal
{
    public function __invoke(InvestorDeal $deal, string $reason): InvestorDeal
    {
        if ($deal->status !== DealStatus::Draft) {
            throw DealIsNotEditable::make((string) $deal->code);
        }

        $deal->status = DealStatus::Cancelled;
        $deal->cancellation_reason = $reason;
        $deal->save();

        return $deal;
    }
}
