<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\UnitEntryType;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\Investor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentUnit>
 */
class InvestmentUnitFactory extends Factory
{
    /** @var class-string<InvestmentUnit> */
    protected $model = InvestmentUnit::class;

    /**
     * ألفُ وحدةٍ بسعر الافتتاح — أبسطُ إصدارٍ ممكن.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_id' => Investor::factory(),
            'type' => UnitEntryType::Issue,
            'units' => '1000.000000',
            'unit_price' => '1.000000',
            'amount' => '1000.00',
            'source_type' => 'investor_wallet_entry',
            'source_id' => $this->faker->unique()->numberBetween(1, 100000),
            'occurred_at' => now(),
        ];
    }
}
