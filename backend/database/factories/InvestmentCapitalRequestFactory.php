<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentCapitalRequest>
 */
class InvestmentCapitalRequestFactory extends Factory
{
    /** @var class-string<InvestmentCapitalRequest> */
    protected $model = InvestmentCapitalRequest::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_id' => Investor::factory(),
            'investor_deal_id' => InvestorDeal::factory()->pool(),
            'direction' => CapitalRequestDirection::In,
            'amount' => '10000.00',
            'requested_at' => now(),
            'status' => CapitalRequestStatus::Pending,
        ];
    }

    public function out(): self
    {
        return $this->state(fn () => ['direction' => CapitalRequestDirection::Out]);
    }
}
