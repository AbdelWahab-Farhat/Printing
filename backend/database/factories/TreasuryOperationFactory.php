<?php

namespace Database\Factories;

use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * A bare deposit row. It writes no movement — tests that need a balance record operations through
 * `TreasuryService`, which is the only way a real one comes to exist.
 *
 * @extends Factory<TreasuryOperation>
 */
class TreasuryOperationFactory extends Factory
{
    protected $model = TreasuryOperation::class;

    public function definition(): array
    {
        return [
            'type' => OperationType::Deposit,
            'amount' => '100.00',
            'to_account_id' => TreasuryAccount::factory(),
            'occurred_at' => now(),
        ];
    }
}
