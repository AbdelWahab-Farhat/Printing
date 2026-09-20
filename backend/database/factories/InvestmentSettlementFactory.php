<?php

namespace Database\Factories;

use App\Domain\Investor\Models\InvestmentSettlement;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentSettlement>
 */
class InvestmentSettlementFactory extends Factory
{
    /** @var class-string<InvestmentSettlement> */
    protected $model = InvestmentSettlement::class;

    /**
     * A settled position with nothing in it — the shape, not a scenario.
     *
     * Tests about the arithmetic build a real pool and call the action, because a settlement whose
     * figures were typed in proves nothing about the two derivations agreeing.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_deal_id' => InvestorDeal::factory()->pool(),
            'settled_on' => now()->toDateString(),
        ];
    }

    /** A settlement whose two sides disagreed — for tests about how a finding is reported. */
    public function drifting(string $drift): static
    {
        return $this->state(fn () => ['drift' => $drift]);
    }
}
