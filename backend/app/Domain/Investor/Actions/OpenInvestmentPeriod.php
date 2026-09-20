<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Exceptions\PoolAlreadyHasAnOpenPeriod;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Starts a pool's next accounting period — and lets in the capital that was waiting for it.
 *
 * **The dates come from the calendar, not from a person.** A period begins the day after the last
 * one ended, and runs for `profit_period_months` from the settings. The first period of a pool
 * begins today. That is what makes «كل شهر» a setting rather than a diary: nobody has to remember
 * to open anything on the first.
 *
 * The length is read **here and now, and never again for this period**. Changing the setting
 * tomorrow decides where the *next* boundary falls and cannot move one that has already been
 * opened — still less one that has closed and paid out. (The admin may move an open period's
 * `ends_on` deliberately; that is an edit to this row, not a re-reading of the setting.)
 *
 * **Then the queue is let in**, which is the whole reason capital requests exist: money offered
 * after the last grace window closed has been waiting in its owner's wallet, and this is the
 * boundary it was waiting for. {@see ApplyCapitalRequests} does that, inside the same transaction —
 * a period that opened without admitting its queue would give everyone who waited a period of
 * ownership they did not get.
 *
 * Under the pool's row lock, and guarded by the partial unique index on the table: «الفترة الحالية»
 * must have exactly one answer, or the grace window has two boundaries to measure against.
 */
final class OpenInvestmentPeriod
{
    public function __construct(
        private readonly SettingsService $settings,
        private readonly ApplyCapitalRequests $applyRequests,
    ) {}

    /**
     * **Returns the queue's outcome beside the period, not just the period.** A caller that only
     * received the row would have no way to learn that one investor's wallet could not cover what
     * he had queued — his request stays pending and nothing is wrong, but somebody has to be told.
     *
     * @return array{period: InvestmentPeriod, applied: list<InvestmentCapitalRequest>, short: array<int, array{investor_id: int, wanted: string, available: string}>}
     *
     * @throws PoolAlreadyHasAnOpenPeriod
     */
    public function __invoke(InvestorDeal $pool, ?Carbon $startsOn = null): array
    {
        return DB::transaction(function () use ($pool, $startsOn): array {
            $locked = InvestorDeal::query()->whereKey($pool->getKey())->lockForUpdate()->firstOrFail();

            $open = InvestmentPeriod::query()
                ->where('investor_deal_id', $locked->getKey())
                ->where('status', PeriodStatus::Open->value)
                ->first();

            if ($open !== null) {
                throw PoolAlreadyHasAnOpenPeriod::make(
                    (string) ($locked->name ?? $locked->code),
                    $open->starts_on->toDateString(),
                    $open->ends_on->toDateString(),
                );
            }

            $starts = $startsOn?->copy()->startOfDay() ?? $this->nextStartFor($locked);

            $period = new InvestmentPeriod;
            $period->investor_deal_id = $locked->getKey();
            $period->starts_on = $starts;
            // Inclusive of its last day, so September runs 1→30 rather than 1→1 October: the
            // boundary a person names when they say «آخر الشهر».
            $period->ends_on = $starts->copy()
                ->addMonthsNoOverflow($this->settings->profitPeriodMonths())
                ->subDay();
            $period->status = PeriodStatus::Open;
            $period->save();

            $queue = ($this->applyRequests)($period);

            return [
                'period' => $period->refresh(),
                'applied' => $queue['applied'],
                'short' => $queue['short'],
            ];
        });
    }

    /**
     * The day after the pool's last period ended — or today, for its first.
     *
     * Read from the rows rather than from the settings, so a gap cannot open up: whatever the
     * length is now, the next period starts where the last one stopped.
     */
    private function nextStartFor(InvestorDeal $pool): Carbon
    {
        $last = InvestmentPeriod::query()
            ->where('investor_deal_id', $pool->getKey())
            ->orderByDesc('ends_on')
            ->orderByDesc('id')
            ->first();

        return $last === null
            ? Carbon::today()->startOfDay()
            : $last->ends_on->copy()->addDay()->startOfDay();
    }
}
