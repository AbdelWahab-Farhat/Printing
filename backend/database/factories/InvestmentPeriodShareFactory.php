<?php

namespace Database\Factories;

use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentPeriodShare;
use App\Domain\Investor\Models\Investor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentPeriodShare>
 */
class InvestmentPeriodShareFactory extends Factory
{
    /** @var class-string<InvestmentPeriodShare> */
    protected $model = InvestmentPeriodShare::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investment_period_id' => InvestmentPeriod::factory(),
            'investor_id' => Investor::factory(),
            'capital' => '10000.00',
            'share_percent' => '100.0000',
            'net_share' => '500.00',
            'is_company' => false,
        ];
    }
}
