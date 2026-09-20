<?php

namespace Database\Factories;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentRealizedEarning>
 */
class InvestmentRealizedEarningFactory extends Factory
{
    /** @var class-string<InvestmentRealizedEarning> */
    protected $model = InvestmentRealizedEarning::class;

    private static int $source = 0;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investment_period_id' => InvestmentPeriod::factory(),
            'source_type' => AuditSubject::Order->value,
            // Sequenced, because the unique index on (period, source, sequence) is real and two
            // earnings built in one test must not collide on it.
            'source_id' => ++self::$source,
            'source_sequence' => 1,
            'amount' => '1000.00',
            'occurred_at' => now(),
        ];
    }

    public function of(string $amount): self
    {
        return $this->state(fn () => ['amount' => $amount]);
    }
}
