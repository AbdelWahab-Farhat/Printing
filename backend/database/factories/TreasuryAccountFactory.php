<?php

namespace Database\Factories;

use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TreasuryAccount>
 */
class TreasuryAccountFactory extends Factory
{
    protected $model = TreasuryAccount::class;

    public function definition(): array
    {
        return [
            'name' => 'حساب '.fake()->unique()->numerify('###'),
            'kind' => AccountKind::Cash,
            'is_default' => false,
            'is_active' => true,
            'currency' => 'LYD',
        ];
    }

    public function kind(AccountKind $kind): static
    {
        return $this->state(fn () => ['kind' => $kind]);
    }

    public function heldBy(User $user): static
    {
        return $this->state(fn () => ['holder_user_id' => $user->getKey()]);
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }
}
