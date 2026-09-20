<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Models\InvestmentPeriod;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentPeriod>
 */
class InvestmentPeriodFactory extends Factory
{
    /** @var class-string<InvestmentPeriod> */
    protected $model = InvestmentPeriod::class;

    /**
     * فترةٌ مفتوحة على شهرٍ كامل، بالمدد الافتراضية.
     *
     * **بلا رصيدٍ افتتاحي** — أوّلُ فترةٍ في صندوقٍ لم يشترِ بعد، وهي أبسط حالةٍ يُبنى عليها.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $starts = now()->startOfMonth();

        return [
            'status' => PeriodStatus::Open,
            'starts_on' => $starts->toDateString(),
            'ends_on' => $starts->copy()->endOfMonth()->toDateString(),
            'subscription_closes_on' => $starts->copy()->addDays(6)->toDateString(),
            'period_months' => 1,
            'subscription_window_days' => 7,
            'investor_profit_share_percent' => '50.00',
            'opening_stock_cost' => '0.00',
            'opening_cash' => '0.00',
        ];
    }
}
