<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Carbon;

/**
 * @extends Factory<InvestmentPeriod>
 */
class InvestmentPeriodFactory extends Factory
{
    /** @var class-string<InvestmentPeriod> */
    protected $model = InvestmentPeriod::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_deal_id' => InvestorDeal::factory()->pool(),
            'starts_on' => now()->startOfMonth()->toDateString(),
            'ends_on' => now()->endOfMonth()->toDateString(),
            'status' => PeriodStatus::Open,
        ];
    }

    /**
     * A period that has been closed, carrying the whole snapshot the table demands.
     *
     * **All thirteen columns or none** — `investment_periods_closed_is_complete` refuses a period
     * that looks settled and is not, so a test cannot take the shortcut of flipping `status` and
     * walking away. That is the constraint doing its job; this state is how a test says «assume
     * this month was closed» without pretending the close was free.
     *
     * The figures are a flat, obviously-synthetic zero-profit month: nothing here should ever be
     * mistaken for a worked example.
     */
    public function closed(): self
    {
        return $this->state(fn () => [
            'status' => PeriodStatus::Closed,
            'closed_at' => now(),
            'opening_cash' => '0.00',
            'closing_cash' => '0.00',
            'opening_stock_cost' => '0.00',
            'closing_stock_cost' => '0.00',
            'realized_margin' => '0.00',
            'deductible_expenses' => '0.00',
            'damage_cost' => '0.00',
            'shortage_cost' => '0.00',
            'net_profit' => '0.00',
            'investor_share_percent_applied' => '50.00',
            'investor_capital_weight_applied' => '100.0000',
            'total_pool_capital' => '0.00',
            'total_investor_capital' => '0.00',
        ]);
    }

    /** A period that began on a given day and runs a month from it. */
    public function startingOn(string $date): self
    {
        return $this->state(fn () => [
            'starts_on' => $date,
            'ends_on' => Carbon::parse($date)->addMonthNoOverflow()->subDay()->toDateString(),
        ]);
    }
}
