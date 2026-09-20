<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Support\Carbon;

/**
 * «هل ما زال بالإمكان الدخول في هذه الفترة؟» — asked in exactly one place.
 *
 * **Why this is a class and not two lines in an action.** The same question is asked three times
 * from three directions: the action deciding whether to allocate now or queue, the endpoint telling
 * the investor what will happen *before* he submits, and the screen drawing the deadline. Three
 * callers doing their own date arithmetic is how a man is promised one thing at 23:58 and given
 * another at 23:59 — and the boundary day is precisely where it would happen.
 *
 * ## The rule
 *
 * ```
 * window = [ period.starts_on , period.starts_on + entry_grace_days ]   inclusive at both ends
 * ```
 *
 * Inside it, capital joins **this** period and participates for the whole of it. Outside it, the
 * request waits for the next period to open. `entry_grace_days = 0` makes the window the first day
 * only — the strict boundary the ownership arithmetic in INVESTMENT-FUND-DESIGN.md §6.3 assumes.
 *
 * **Inclusive of the last day**, because «three days of grace» means three days a person can use,
 * not two and a bit. The comparison is on whole dates and never on times: an investor handing money
 * over at four in the afternoon of the third day is inside it, and nobody should have to know what
 * hour the period technically began.
 *
 * ## What it deliberately does not do
 *
 * It does not read the settings and it does not ask what today is. Both are passed in — which is
 * what lets a test walk a year of boundaries without touching the clock or the database, and what
 * keeps this class a statement about the rule rather than about the environment.
 */
final class GraceWindow
{
    /**
     * Whether capital offered on `$on` still joins `$period`.
     *
     * A closed period is never open to capital, whatever the dates say: its profit has been divided
     * and paid, so money joining it now would be buying a share of something already spent.
     */
    public static function admits(InvestmentPeriod $period, int $graceDays, Carbon $on): bool
    {
        if (! $period->isOpen()) {
            return false;
        }

        return $on->startOfDay()->lessThanOrEqualTo(
            $period->graceWindowEndsOn($graceDays)->endOfDay()
        ) && $on->startOfDay()->greaterThanOrEqualTo($period->starts_on->startOfDay());
    }

    /**
     * The last day money may still join this period — what the screen prints and the warning names.
     */
    public static function closesOn(InvestmentPeriod $period, int $graceDays): Carbon
    {
        return $period->graceWindowEndsOn($graceDays);
    }

    /**
     * The day capital offered on `$on` will actually take effect.
     *
     * Inside the window, today — the money goes to work at once. Outside it, the day after this
     * period ends, which is when the next one begins. **This is the sentence the investor is shown
     * before he submits**, and the reason it is computed here rather than in the controller: the
     * promise and the behaviour come from one function, so they cannot disagree.
     */
    public static function takesEffectOn(InvestmentPeriod $period, int $graceDays, Carbon $on): Carbon
    {
        return self::admits($period, $graceDays, $on)
            ? $on->copy()->startOfDay()
            : $period->ends_on->copy()->addDay()->startOfDay();
    }
}
