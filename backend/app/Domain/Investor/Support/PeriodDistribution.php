<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;

/**
 * How one period's net profit is divided — pure arithmetic, no database, no clock.
 *
 * **Extracted so the sums can be checked by hand.** This is the part of the close a person will
 * argue with, and it should be readable and testable without arranging a pool, a ledger and a month
 * of trading first. {@see CloseInvestmentPeriod} gathers the facts;
 * this turns them into figures.
 *
 * ## The three factors
 *
 * ```
 * investor weight = investor capital ÷ total pool capital
 * investors' pool = net profit × investor weight × investor_profit_share_percent ÷ 100
 * company         = net profit − investors' pool
 * each investor   = investors' pool × (his capital ÷ total investor capital)
 * ```
 *
 * The first two are {@see InvestorDeal::investorsCutOf()} with its shape
 * intact — the company is a partner for the goods its own money bought, **and** takes the operator's
 * share of what the rest earned. What changed is only where the middle factor comes from: computed
 * from this period's capital rather than frozen from one lorry's cost.
 *
 * ## Why the company appears twice
 *
 * It is a participant like anybody else *and* the operator. Its capital earns a weight in the first
 * line; its operator's half is the residual in the third. Modelling it as two claims on one profit
 * is what lets a single formula serve a pool the company is in and one it is not: with no company
 * capital the weight is 100%, and the residual is the plain 50%.
 *
 * ## Rounding
 *
 * Largest-remainder throughout, so the parts sum to the whole exactly and no dinar is created or
 * lost in a division. A loss divides by the same rule with the sign carried through.
 */
final class PeriodDistribution
{
    /**
     * @param  string  $netProfit  signed — negative is a losing period
     * @param  array<int, string>  $capitalByInvestor  every participant's capital, company included, keyed by investor id
     * @param  int|null  $companyInvestorId  which of them is the company, or null when it is in no pool
     * @param  string  $investorSharePercent  the operator's split, «50.00»
     * @return array{
     *     investors_side: string,
     *     company_total: string,
     *     investor_weight_percent: string,
     *     total_capital: string,
     *     total_investor_capital: string,
     *     per_investor: array<int, array{capital: string, share_percent: string, net_share: string}>
     * }
     */
    public static function divide(
        string $netProfit,
        array $capitalByInvestor,
        ?int $companyInvestorId,
        string $investorSharePercent,
    ): array {
        $totalCapital = '0.00';
        $investorCapital = '0.00';

        foreach ($capitalByInvestor as $investorId => $capital) {
            $totalCapital = bcadd($totalCapital, $capital, 2);

            if ($investorId !== $companyInvestorId) {
                $investorCapital = bcadd($investorCapital, $capital, 2);
            }
        }

        // **A pool with no capital divides nothing.** It can still have earned — a period that sold
        // the last of its goods and returned every dinar — and the honest answer is that the
        // company keeps it, because there is nobody whose money was at work to claim a share.
        if (bccomp($totalCapital, '0', 2) === 0) {
            return self::nothingToDivide($netProfit, $capitalByInvestor, $companyInvestorId);
        }

        $weight = bcdiv(bcmul($investorCapital, '100', 8), $totalCapital, 8);

        $investorsSide = Money::round(bcdiv(
            bcmul(bcmul($netProfit, $weight, 8), $investorSharePercent, 8),
            '10000',
            8,
        ));

        // The residual, never a second multiplication: the two must add to the net profit exactly,
        // and two roundings of the same figure do not.
        $companyTotal = bcsub($netProfit, $investorsSide, 2);

        return [
            'investors_side' => $investorsSide,
            'company_total' => $companyTotal,
            'investor_weight_percent' => self::percent($weight),
            'total_capital' => $totalCapital,
            'total_investor_capital' => $investorCapital,
            'per_investor' => self::split(
                $investorsSide,
                $capitalByInvestor,
                $companyInvestorId,
                $investorCapital,
            ),
        ];
    }

    /**
     * The investors' side, across the investors, by capital.
     *
     * @param  array<int, string>  $capitalByInvestor
     * @return array<int, array{capital: string, share_percent: string, net_share: string}>
     */
    private static function split(
        string $investorsSide,
        array $capitalByInvestor,
        ?int $companyInvestorId,
        string $investorCapital,
    ): array {
        $investors = [];

        foreach ($capitalByInvestor as $investorId => $capital) {
            if ($investorId !== $companyInvestorId) {
                $investors[$investorId] = $capital;
            }
        }

        if ($investors === [] || bccomp($investorCapital, '0', 2) === 0) {
            return [];
        }

        $percents = [];

        foreach ($investors as $investorId => $capital) {
            $percents[$investorId] = bcdiv(bcmul($capital, '100', 8), $investorCapital, 8);
        }

        // Largest-remainder over the percentages, so the shares sum to the investors' side exactly.
        $amounts = Money::allocate($investorsSide, array_values($percents));
        $ids = array_keys($percents);

        $out = [];

        foreach ($ids as $index => $investorId) {
            $out[$investorId] = [
                'capital' => $investors[$investorId],
                'share_percent' => self::percent($percents[$investorId]),
                'net_share' => $amounts[$index] ?? '0.00',
            ];
        }

        return $out;
    }

    /**
     * A percentage at the resolution its column keeps, rounded half-up.
     *
     * `Money::round()` is fixed at two places because it rounds money; `share_percent` is
     * `decimal(9,4)`, and truncating with `bcadd(..., 4)` would quietly bias every split downward.
     * The same half-up shape as `Money::round()`, at the scale this column actually has.
     */
    private static function percent(string $value): string
    {
        $half = bccomp($value, '0', 8) < 0 ? '-0.00005' : '0.00005';

        return bcadd(bcadd($value, $half, 8), '0', 4);
    }

    /**
     * @param  array<int, string>  $capitalByInvestor
     * @return array{investors_side: string, company_total: string, investor_weight_percent: string, total_capital: string, total_investor_capital: string, per_investor: array<int, array{capital: string, share_percent: string, net_share: string}>}
     */
    private static function nothingToDivide(
        string $netProfit,
        array $capitalByInvestor,
        ?int $companyInvestorId,
    ): array {
        return [
            'investors_side' => '0.00',
            'company_total' => Money::round($netProfit),
            'investor_weight_percent' => '0.0000',
            'total_capital' => '0.00',
            'total_investor_capital' => '0.00',
            'per_investor' => [],
        ];
    }
}
