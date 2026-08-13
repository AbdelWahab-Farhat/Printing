<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerComment;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CustomerComment>
 */
class CustomerCommentFactory extends Factory
{
    protected $model = CustomerComment::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            // A colleague by default, so `->for($user)` in a test is what makes a note *mine*
            // and the difference between the two is never an accident of ordering.
            'user_id' => User::factory(),
            'body' => 'يفضّل التسليم صباحاً',
            'edited_at' => null,
        ];
    }
}
