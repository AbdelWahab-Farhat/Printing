<?php

namespace Database\Factories;

use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentCashEntry>
 */
class InvestmentCashEntryFactory extends Factory
{
    /** @var class-string<InvestmentCashEntry> */
    protected $model = InvestmentCashEntry::class;

    /**
     * تحصيلُ ثمن بيع — أبسط صفٍّ يدخل به المال، ومصدرُه دفعةُ طلبية.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'type' => CashEntryType::SaleProceeds,
            'amount' => '4500.00',
            'source_type' => 'order_payment',
            'source_id' => $this->faker->unique()->numberBetween(1, 100000),
            'source_sequence' => 1,
            'occurred_at' => now(),
        ];
    }
}
