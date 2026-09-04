<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;

/**
 * The four balances, walked from the ledger — the only place any of them is computed.
 *
 * There is no balance column anywhere in this feature, which is the standing rule of the schema
 * («الرصيد لا يُخزَّن») and the reason `orders.paid_amount` may only ever be written by one
 * action. A cached figure here could only ever disagree with the rows it summarises, and this is
 * precisely the table somebody will add up by hand.
 *
 * Every row is asked what it did through {@see InvestorWalletEntry::deltas()}, so a reversal is
 * a negation of the row it undoes and nothing here has to know that.
 */
final class InvestorBalances
{
    /** @var array{capital_wallet: string, capital_deal: string, profit_deal: string, profit_wallet: string} */
    private const ZERO = [
        'capital_wallet' => '0.00',
        'capital_deal' => '0.00',
        'profit_deal' => '0.00',
        'profit_wallet' => '0.00',
    ];

    /**
     * Every balance of one investor: the two wallet pots, and the two per-deal pots keyed by
     * deal id.
     *
     * One query and one walk rather than four aggregates: the rows are few per investor, and
     * summing them in PHP is what lets `deltas()` stay the single definition instead of being
     * restated as four SQL CASE expressions that can drift from it.
     *
     * @return array{
     *     wallet: array{capital: string, profit: string},
     *     deals: array<int, array{capital: string, profit: string}>
     * }
     */
    public function forInvestor(int $investorId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investor_id', $investorId)
            ->get();

        $wallet = ['capital' => '0', 'profit' => '0'];
        $deals = [];

        foreach ($entries as $entry) {
            $deltas = $entry->deltas();

            $wallet['capital'] = bcadd($wallet['capital'], $deltas['capital_wallet'], 8);
            $wallet['profit'] = bcadd($wallet['profit'], $deltas['profit_wallet'], 8);

            $dealId = $entry->investor_deal_id;

            if ($dealId === null) {
                continue;
            }

            $deals[$dealId] ??= ['capital' => '0', 'profit' => '0'];
            $deals[$dealId]['capital'] = bcadd($deals[$dealId]['capital'], $deltas['capital_deal'], 8);
            $deals[$dealId]['profit'] = bcadd($deals[$dealId]['profit'], $deltas['profit_deal'], 8);
        }

        return [
            'wallet' => [
                'capital' => Money::round($wallet['capital']),
                'profit' => Money::round($wallet['profit']),
            ],
            // A loop rather than `array_map`, and it matters: `array_map` preserves *string*
            // keys and renumbers integer ones, so mapping over a map keyed by deal id silently
            // relabels deal 7 as deal 0. Every figure stays correct and lands against the wrong
            // deal — which is exactly the class of bug this table exists to make impossible.
            'deals' => $this->rounded($deals),
        ];
    }

    /**
     * One investor's standing in one deal.
     *
     * @return array{capital: string, profit: string}
     */
    public function forShare(int $investorId, int $dealId): array
    {
        return $this->forInvestor($investorId)['deals'][$dealId]
            ?? ['capital' => '0.00', 'profit' => '0.00'];
    }

    /**
     * What a whole deal holds and has earned, across everybody in it.
     *
     * @return array{capital: string, profit: string, per_investor: array<int, array{capital: string, profit: string}>}
     */
    public function forDeal(int $dealId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investor_deal_id', $dealId)
            ->get();

        $capital = '0';
        $profit = '0';
        $perInvestor = [];

        foreach ($entries as $entry) {
            $deltas = $entry->deltas();

            $capital = bcadd($capital, $deltas['capital_deal'], 8);
            $profit = bcadd($profit, $deltas['profit_deal'], 8);

            $id = (int) $entry->investor_id;
            $perInvestor[$id] ??= ['capital' => '0', 'profit' => '0'];
            $perInvestor[$id]['capital'] = bcadd($perInvestor[$id]['capital'], $deltas['capital_deal'], 8);
            $perInvestor[$id]['profit'] = bcadd($perInvestor[$id]['profit'], $deltas['profit_deal'], 8);
        }

        return [
            'capital' => Money::round($capital),
            'profit' => Money::round($profit),
            'per_investor' => $this->rounded($perInvestor),
        ];
    }

    /**
     * Rounds a map of pots, keeping whatever it is keyed by — see the note in `forInvestor()`.
     *
     * @param  array<int, array{capital: string, profit: string}>  $pots
     * @return array<int, array{capital: string, profit: string}>
     */
    private function rounded(array $pots): array
    {
        $out = [];

        foreach ($pots as $key => $value) {
            $out[$key] = [
                'capital' => Money::round($value['capital']),
                'profit' => Money::round($value['profit']),
            ];
        }

        return $out;
    }

    /**
     * @return array{capital_wallet: string, capital_deal: string, profit_deal: string, profit_wallet: string}
     */
    public static function zero(): array
    {
        return self::ZERO;
    }
}
