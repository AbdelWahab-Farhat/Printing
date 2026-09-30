<?php

namespace Database\Factories;

use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TreasuryMovement>
 */
class TreasuryMovementFactory extends Factory
{
    protected $model = TreasuryMovement::class;

    public function definition(): array
    {
        return [
            'account_id' => TreasuryAccount::factory(),
            'direction' => MovementDirection::In,
            'kind' => MovementKind::Deposit,
            'amount' => '100.00',
            'occurred_at' => now(),
            'source_type' => 'treasury_operation',
            'source_id' => fake()->unique()->numberBetween(1, 1_000_000),
        ];
    }
}
